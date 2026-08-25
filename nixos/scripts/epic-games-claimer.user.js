// ==UserScript==
// @name         Epic Games Store - Auto Free Games Claimer
// @namespace    https://github.com/Boomkaas/dotfiles
// @version      1.3.0
// @description  Automatically claims weekly free games in your native logged-in Firefox. Fully stoppable and resumable at any step.
// @author       Peng
// @match        https://store.epicgames.com/*
// @match        https://www.epicgames.com/store/*
// @match        https://*.epicgames.com/*
// @grant        GM_closeTab
// @grant        window.close
// @run-at       document-idle
// ==/UserScript==

(function () {
  'use strict';

  const isTopWindow = window.self === window.top;
  const STORAGE_KEY = 'epic_auto_claim_state';
  const DELAY_PAGE_LOAD = 3500;        // 3.5s to ensure React hydration & session load
  const DELAY_BETWEEN_ACTIONS = 2500;   // 2.5s calm pace ("don't rush")
  const DELAY_CHECKOUT_POLL = 1000;     // 1.0s polling for checkout elements

  let isStopped = false;
  const activeTimeouts = new Set();

  function registerTimeout(fn, ms) {
    const id = setTimeout(() => {
      activeTimeouts.delete(id);
      if (!isStopped) fn();
    }, ms);
    activeTimeouts.add(id);
    return id;
  }

  function clearAllTimers() {
    for (const id of activeTimeouts) {
      clearTimeout(id);
    }
    activeTimeouts.clear();
  }

  // 100ms-chunked cancellable sleep: wakes up immediately if stopped
  async function cancellableSleep(ms) {
    if (isStopped) throw new Error('CANCELLED');
    const step = 100;
    let elapsed = 0;
    while (elapsed < ms) {
      if (isStopped) throw new Error('CANCELLED');
      const wait = Math.min(step, ms - elapsed);
      await new Promise((resolve) => {
        const tid = setTimeout(() => {
          activeTimeouts.delete(tid);
          resolve();
        }, wait);
        activeTimeouts.add(tid);
      });
      elapsed += wait;
      if (isStopped) throw new Error('CANCELLED');
    }
  }

  function getState() {
    try {
      return JSON.parse(sessionStorage.getItem(STORAGE_KEY)) || {
        active: false,
        stopped: false,
        queue: [],
        currentIndex: 0,
        status: 'idle'
      };
    } catch {
      return { active: false, stopped: false, queue: [], currentIndex: 0, status: 'idle' };
    }
  }

  function setState(state) {
    try {
      sessionStorage.setItem(STORAGE_KEY, JSON.stringify(state));
    } catch (e) {
      console.error('[Epic Claimer] Failed to save state:', e);
    }
  }

  function clearState() {
    try {
      sessionStorage.removeItem(STORAGE_KEY);
    } catch (e) {}
  }

  // ==========================================
  // IFRAME HANDLER (Runs inside checkout frame)
  // ==========================================
  if (!isTopWindow) {
    let iframeStopped = false;

    window.addEventListener('message', (event) => {
      if (!event.data) return;
      if (event.data.type === 'EPIC_CLAIMER_STOP') {
        iframeStopped = true;
        console.log('[Epic Claimer Iframe] Received stop signal from parent window.');
      }
    });

    async function handleIframeCheckout() {
      let attempts = 0;
      const maxAttempts = 30; // 30 seconds

      while (attempts < maxAttempts) {
        if (iframeStopped) {
          console.log('[Epic Claimer Iframe] Checkout aborted (stopped).');
          return;
        }

        const state = getState();
        if (state.stopped) {
          iframeStopped = true;
          return;
        }

        attempts++;

        // 1. Handle agreement checkboxes
        const checkboxes = document.querySelectorAll('input[type="checkbox"]');
        for (const cb of checkboxes) {
          if (iframeStopped) return;
          if (!cb.checked) {
            cb.click();
            await cancellableSleep(400).catch(() => {});
          }
        }

        if (iframeStopped) return;

        // 2. Look for "Place Order" or "Add to Library" button
        const buttons = Array.from(document.querySelectorAll('button, a, input[type="button"], input[type="submit"]'));
        const orderBtn = buttons.find(b => {
          const text = (b.innerText || b.value || '').trim().toUpperCase();
          const testId = b.getAttribute('data-testid') || '';
          const isTarget = text.includes('PLACE ORDER') || 
                           text.includes('ADD TO LIBRARY') || 
                           text.includes('CONFIRM') || 
                           testId.includes('purchase') ||
                           b.classList.contains('payment-btn');
          return isTarget && !b.disabled;
        });

        if (orderBtn && !iframeStopped) {
          console.log('[Epic Claimer Iframe] Found order button:', orderBtn.innerText);
          await cancellableSleep(1500).catch(() => {});
          if (iframeStopped) return;
          orderBtn.click();

          // Notify parent window
          try {
            window.top.postMessage({ type: 'EPIC_CLAIMER_ORDER_CLICKED' }, '*');
          } catch (e) {}
          return;
        }

        // 3. Check for thank you / confirmation text
        const bodyText = document.body ? document.body.innerText : '';
        if (bodyText.includes('Thank you') || bodyText.includes('Order Complete')) {
          try {
            window.top.postMessage({ type: 'EPIC_CLAIMER_ORDER_COMPLETED' }, '*');
          } catch (e) {}
          return;
        }

        await cancellableSleep(DELAY_CHECKOUT_POLL).catch(() => {});
      }
    }

    // Start iframe observer
    setTimeout(() => {
      const state = getState();
      if (!state.stopped) {
        handleIframeCheckout();
      }
    }, 1500);

    return; // Exit script for iframes
  }

  // ==========================================
  // TOP-LEVEL WINDOW HANDLER (Main Controller)
  // ==========================================

  // Listen for iframe messages
  window.addEventListener('message', (event) => {
    if (!event.data || !event.data.type || isStopped) return;
    if (event.data.type === 'EPIC_CLAIMER_ORDER_CLICKED') {
      updateHUDStatus('📝 Order placed inside checkout frame! Waiting for confirmation...', true);
    } else if (event.data.type === 'EPIC_CLAIMER_ORDER_COMPLETED') {
      updateHUDStatus('🎉 Order confirmed in checkout frame!', false);
    }
  });

  // Floating HUD UI
  function createHUD() {
    if (document.getElementById('epic-claimer-hud')) return;

    const hud = document.createElement('div');
    hud.id = 'epic-claimer-hud';
    hud.innerHTML = `
      <div style="
        position: fixed;
        bottom: 24px;
        right: 24px;
        z-index: 9999999;
        background: rgba(18, 18, 26, 0.95);
        backdrop-filter: blur(14px);
        -webkit-backdrop-filter: blur(14px);
        border: 1px solid rgba(51, 204, 255, 0.5);
        border-radius: 14px;
        box-shadow: 0 12px 35px rgba(0, 0, 0, 0.8), 0 0 15px rgba(51, 204, 255, 0.2);
        padding: 16px 20px;
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
        color: #f0f0f0;
        min-width: 320px;
        max-width: 400px;
        transition: all 0.3s ease;
      ">
        <div style="display: flex; align-items: center; justify-content: space-between; margin-bottom: 10px;">
          <div style="display: flex; align-items: center; gap: 8px;">
            <span style="font-size: 20px;">🎮</span>
            <span style="font-weight: 700; font-size: 14px; letter-spacing: 0.5px; color: #33ccff;">EPIC AUTO-CLAIMER</span>
          </div>
          <div style="display: flex; align-items: center; gap: 8px;">
            <span id="epic-hud-spinner" style="font-size: 14px; animation: epic-spin 2s linear infinite;">⏳</span>
            <button id="epic-hud-min-toggle" title="Minimize/Expand" style="
              background: rgba(255, 255, 255, 0.1);
              border: 1px solid rgba(255, 255, 255, 0.2);
              border-radius: 6px;
              color: #bbb;
              font-size: 11px;
              cursor: pointer;
              padding: 2px 6px;
            ">_</button>
          </div>
        </div>
        <div id="epic-hud-body">
          <div id="epic-hud-status" style="font-size: 13px; color: #cfd8dc; line-height: 1.4; margin-bottom: 12px;">
            Initializing claimer...
          </div>
          <div style="display: flex; gap: 8px;">
            <button id="epic-hud-start" style="
              flex: 1;
              padding: 8px 12px;
              background: linear-gradient(135deg, #00c853, #009624);
              border: none;
              border-radius: 8px;
              color: #fff;
              font-size: 12px;
              font-weight: 600;
              cursor: pointer;
              transition: all 0.2s ease;
            ">▶ Start Auto-Claim</button>
            <button id="epic-hud-stop" style="
              padding: 8px 12px;
              background: rgba(244, 67, 54, 0.2);
              border: 1px solid rgba(244, 67, 54, 0.5);
              border-radius: 8px;
              color: #ff8a80;
              font-size: 12px;
              font-weight: 600;
              cursor: pointer;
              transition: all 0.2s ease;
            ">⏹ Stop</button>
          </div>
        </div>
      </div>
      <style>
        @keyframes epic-spin { 100% { transform: rotate(360deg); } }
        #epic-hud-start:hover { filter: brightness(1.15); transform: translateY(-1px); }
        #epic-hud-stop:hover { background: rgba(244, 67, 54, 0.35); color: #fff; }
      </style>
    `;
    document.body.appendChild(hud);

    // Minimize toggle
    let isMinimized = false;
    document.getElementById('epic-hud-min-toggle').addEventListener('click', () => {
      isMinimized = !isMinimized;
      const body = document.getElementById('epic-hud-body');
      const btn = document.getElementById('epic-hud-min-toggle');
      if (isMinimized) {
        body.style.display = 'none';
        btn.innerText = '+';
      } else {
        body.style.display = 'block';
        btn.innerText = '_';
      }
    });

    // Start / Resume button
    document.getElementById('epic-hud-start').addEventListener('click', () => {
      const state = getState();
      if (state.queue && state.queue.length > 0 && state.currentIndex < state.queue.length) {
        startClaimProcess(false, true);
      } else {
        startClaimProcess(true, false);
      }
    });

    // Stop button
    document.getElementById('epic-hud-stop').addEventListener('click', () => {
      stopClaimProcess('Manual stop clicked by user');
    });
  }

  function updateHUDStatus(text, showSpinner = true) {
    const statusEl = document.getElementById('epic-hud-status');
    const spinnerEl = document.getElementById('epic-hud-spinner');
    if (statusEl) statusEl.innerHTML = text;
    if (spinnerEl) spinnerEl.style.display = showSpinner ? 'inline-block' : 'none';
  }

  function updateHUDButtons(running = true) {
    const startBtn = document.getElementById('epic-hud-start');
    const stopBtn = document.getElementById('epic-hud-stop');
    if (!startBtn || !stopBtn) return;

    if (running) {
      startBtn.style.opacity = '0.6';
      startBtn.style.cursor = 'default';
      stopBtn.style.opacity = '1.0';
      stopBtn.style.cursor = 'pointer';
      stopBtn.style.background = 'rgba(244, 67, 54, 0.25)';
    } else {
      startBtn.style.opacity = '1.0';
      startBtn.style.cursor = 'pointer';
      stopBtn.style.opacity = '0.5';
      stopBtn.style.cursor = 'default';
      stopBtn.style.background = 'rgba(255, 255, 255, 0.1)';

      const state = getState();
      if (state.queue && state.queue.length > 0 && state.currentIndex < state.queue.length) {
        const gameIdx = state.currentIndex + 1;
        const total = state.queue.length;
        startBtn.innerHTML = `▶ Resume (Game ${gameIdx}/${total})`;
      } else {
        startBtn.innerHTML = `▶ Start Auto-Claim`;
      }
    }
  }

  // ==========================================
  // STOP CONTROLLER (Halts at any step)
  // ==========================================
  function stopClaimProcess(reason = '') {
    isStopped = true;
    clearAllTimers();

    const state = getState();
    state.active = false;
    state.stopped = true;
    state.status = 'stopped';
    setState(state);

    // Broadcast stop signal to iframes
    try {
      window.postMessage({ type: 'EPIC_CLAIMER_STOP' }, '*');
      const iframes = document.querySelectorAll('iframe');
      for (const iframe of iframes) {
        if (iframe.contentWindow) {
          iframe.contentWindow.postMessage({ type: 'EPIC_CLAIMER_STOP' }, '*');
        }
      }
    } catch (e) {}

    console.log('[Epic Claimer] Process stopped immediately.', reason);
    updateHUDStatus(`⏹ <b>Auto-claim stopped.</b> All pending actions and orders cancelled.`, false);
    updateHUDButtons(false);
  }

  function closeClaimerTab(delayMs = 3000) {
    if (isStopped) return;
    registerTimeout(() => {
      if (isStopped) return;
      try {
        if (typeof GM_closeTab === 'function') {
          GM_closeTab();
        } else {
          window.close();
        }
      } catch (e) {
        window.close();
      }
    }, delayMs);
  }

  // ==========================================
  // STEP 1: SCAN FREE GAMES PAGE
  // ==========================================
  async function scanFreeGamesPage() {
    if (isStopped) return;
    updateHUDStatus('🔍 Scanning for weekly free games...');
    updateHUDButtons(true);

    try {
      await cancellableSleep(DELAY_PAGE_LOAD);
    } catch (e) {
      return; // Cancelled
    }

    if (isStopped) return;

    const candidates = [];
    const allLinks = Array.from(document.querySelectorAll('a[href*="/p/"], a[href*="/bundles/"]'));

    for (const link of allLinks) {
      if (isStopped) return;
      const href = link.getAttribute('href');
      if (!href) continue;

      const fullUrl = new URL(href, window.location.origin).href;
      const card = link.closest('[data-component="FreeGamesCard"]') || link.closest('div[class*="Card"]') || link.closest('div') || link;
      const text = card.innerText || '';

      const isFreeNow = text.includes('Free Now') || text.includes('FREE NOW') || text.includes('100%');
      const isComingSoon = text.includes('Coming Soon') || text.includes('COMING SOON') || text.includes('Unlocks');
      const isInLibrary = text.includes('In Library') || text.includes('IN LIBRARY') || text.includes('Owned');

      if (isFreeNow && !isComingSoon && !isInLibrary) {
        if (!candidates.includes(fullUrl)) {
          candidates.push(fullUrl);
        }
      }
    }

    if (isStopped) return;

    if (candidates.length === 0) {
      updateHUDStatus('✨ <b>All current free games are already in your library!</b> Closing tab in 3s...', false);
      updateHUDButtons(false);
      clearState();
      closeClaimerTab(3000);
      return;
    }

    updateHUDStatus(`🎯 Found <b>${candidates.length}</b> unclaimed free game(s)! Starting claim sequence...`);

    try {
      await cancellableSleep(DELAY_BETWEEN_ACTIONS);
    } catch (e) {
      return; // Cancelled
    }

    if (isStopped) return;

    const state = {
      active: true,
      stopped: false,
      queue: candidates,
      currentIndex: 0,
      status: 'navigating'
    };
    setState(state);
    window.location.href = candidates[0];
  }

  // ==========================================
  // STEP 2: HANDLE GAME PRODUCT PAGE
  // ==========================================
  async function handleGamePage(state) {
    if (isStopped) return;

    const gameIndex = state.currentIndex + 1;
    const totalGames = state.queue.length;

    updateHUDStatus(`🎮 <b>Game ${gameIndex}/${totalGames}</b>: Checking page status...`);
    updateHUDButtons(true);

    try {
      await cancellableSleep(DELAY_PAGE_LOAD);
    } catch (e) {
      return; // Cancelled
    }

    if (isStopped) return;

    // 1. Check Age Gate / Content Warning
    const continueBtn = Array.from(document.querySelectorAll('button, a')).find(el => {
      const t = (el.innerText || '').trim().toLowerCase();
      return t === 'continue' || t === 'view product' || t === 'yes';
    });

    if (continueBtn && !isStopped) {
      updateHUDStatus('⚠️ Age confirmation prompt detected. Clicking Continue...');
      continueBtn.click();
      try {
        await cancellableSleep(DELAY_BETWEEN_ACTIONS);
      } catch (e) {
        return; // Cancelled
      }
    }

    if (isStopped) return;

    // 2. Check if already owned
    const pageText = document.body ? document.body.innerText : '';
    if (pageText.includes('In Library') || pageText.includes('IN LIBRARY')) {
      updateHUDStatus(`✅ <b>Game ${gameIndex}/${totalGames}</b> already in library! Moving to next...`);
      try {
        await cancellableSleep(DELAY_BETWEEN_ACTIONS);
      } catch (e) {
        return;
      }
      advanceQueue(state);
      return;
    }

    if (isStopped) return;

    // 3. Find the "GET" button on the game page
    const getButton = Array.from(document.querySelectorAll('button')).find(btn => {
      const text = (btn.innerText || '').trim().toUpperCase();
      const testId = btn.getAttribute('data-testid') || '';
      const isGet = (text === 'GET' || text === 'Get' || testId.includes('purchase-cta'));
      return isGet && !btn.disabled && !text.includes('IN LIBRARY');
    });

    if (!getButton) {
      updateHUDStatus(`⚠️ Could not find "GET" button (may already be in library). Advancing...`);
      try {
        await cancellableSleep(DELAY_BETWEEN_ACTIONS);
      } catch (e) {
        return;
      }
      advanceQueue(state);
      return;
    }

    if (isStopped) return;

    // Click GET calmly
    updateHUDStatus(`🛒 Clicking <b>GET</b> button...`);
    getButton.scrollIntoView({ behavior: 'smooth', block: 'center' });

    try {
      await cancellableSleep(1000);
    } catch (e) {
      return;
    }

    if (isStopped) return;
    getButton.click();

    updateHUDStatus(`⏳ Waiting for checkout overlay / dialog...`);

    try {
      await cancellableSleep(3000);
    } catch (e) {
      return;
    }

    if (isStopped) return;

    // 4. Handle checkout overlay
    await monitorAndCompleteCheckout(state);
  }

  // ==========================================
  // STEP 3: MONITOR & COMPLETE CHECKOUT
  // ==========================================
  async function monitorAndCompleteCheckout(state) {
    if (isStopped) return;

    let secondsElapsed = 0;
    const timeoutSeconds = 40; // Wait up to 40 seconds for checkout to finish

    while (secondsElapsed < timeoutSeconds) {
      if (isStopped) return;

      secondsElapsed += 1.5;

      // 1. Check top-level DOM for Place Order / Add to Library buttons
      const topButtons = Array.from(document.querySelectorAll('button, a, input[type="button"]'));
      const orderBtn = topButtons.find(b => {
        const text = (b.innerText || b.value || '').trim().toUpperCase();
        const testId = b.getAttribute('data-testid') || '';
        return (text.includes('PLACE ORDER') || 
                text.includes('ADD TO LIBRARY') || 
                text.includes('CONFIRM ORDER') || 
                testId.includes('purchase-button') ||
                b.classList.contains('payment-btn')) && !b.disabled;
      });

      if (orderBtn && !isStopped) {
        updateHUDStatus(`📝 Found <b>${orderBtn.innerText || 'Place Order'}</b> button! Finalizing...`);
        // Check agreement checkboxes in top level
        const cbs = document.querySelectorAll('input[type="checkbox"]');
        for (const cb of cbs) {
          if (isStopped) return;
          if (!cb.checked) cb.click();
        }

        try {
          await cancellableSleep(1500);
        } catch (e) {
          return;
        }

        if (isStopped) return;
        orderBtn.click();
        updateHUDStatus(`🎉 Order placed! Waiting for confirmation...`);

        try {
          await cancellableSleep(5000);
        } catch (e) {
          return;
        }

        if (isStopped) return;
        advanceQueue(state);
        return;
      }

      if (isStopped) return;

      // 2. Check if purchase confirmation / thank you screen is visible
      const bodyText = document.body ? document.body.innerText : '';
      if (bodyText.includes('Thank you for buying') || 
          bodyText.includes('Thank you for your order') || 
          bodyText.includes('Order Complete')) {
        updateHUDStatus(`🎉 Purchase confirmed! Moving to next game...`);
        try {
          await cancellableSleep(DELAY_BETWEEN_ACTIONS);
        } catch (e) {
          return;
        }
        advanceQueue(state);
        return;
      }

      if (isStopped) return;

      // 3. Check if the page reverted to "In Library"
      const inLibraryBtn = topButtons.find(b => (b.innerText || '').trim().toUpperCase().includes('IN LIBRARY'));
      if (inLibraryBtn && secondsElapsed > 8) {
        updateHUDStatus(`✅ Game is now marked In Library! Moving to next...`);
        try {
          await cancellableSleep(DELAY_BETWEEN_ACTIONS);
        } catch (e) {
          return;
        }
        advanceQueue(state);
        return;
      }

      updateHUDStatus(`⏳ Waiting for checkout completion (${Math.round(secondsElapsed)}s / ${timeoutSeconds}s)...`);

      try {
        await cancellableSleep(1500);
      } catch (e) {
        return;
      }
    }

    if (isStopped) return;

    // Timeout fallback
    updateHUDStatus(`⚠️ Proceeding to next game in queue...`);
    try {
      await cancellableSleep(DELAY_BETWEEN_ACTIONS);
    } catch (e) {
      return;
    }
    advanceQueue(state);
  }

  // ==========================================
  // STEP 4: ADVANCE QUEUE
  // ==========================================
  function advanceQueue(state) {
    if (isStopped) return;

    state.currentIndex++;
    if (state.currentIndex < state.queue.length) {
      setState(state);
      window.location.href = state.queue[state.currentIndex];
    } else {
      updateHUDStatus('🎉 <b>All weekly free games have been claimed!</b> Closing window in 4s...', false);
      updateHUDButtons(false);
      clearState();
      closeClaimerTab(4000);
    }
  }

  // ==========================================
  // START / RESUME ENTRYPOINT
  // ==========================================
  function startClaimProcess(manualTrigger = false, resume = false) {
    createHUD();
    isStopped = false;
    clearAllTimers();

    let state = getState();

    if (manualTrigger) {
      clearState();
      state = { active: true, stopped: false, queue: [], currentIndex: 0, status: 'scanning' };
      setState(state);
      scanFreeGamesPage();
      return;
    }

    state.stopped = false;
    state.active = true;
    setState(state);

    if (resume && state.queue && state.queue.length > 0) {
      const currentUrl = window.location.href;
      const targetUrl = state.queue[state.currentIndex];

      if (targetUrl && currentUrl !== targetUrl && !currentUrl.includes(targetUrl.replace(window.location.origin, ''))) {
        updateHUDStatus(`▶ Resuming queue. Navigating to Game ${state.currentIndex + 1}/${state.queue.length}...`);
        window.location.href = targetUrl;
        return;
      }
    }

    if (state.active && state.queue.length > 0) {
      const currentUrl = window.location.href;
      if (currentUrl.includes('/free-games') && state.currentIndex === 0) {
        scanFreeGamesPage();
      } else {
        handleGamePage(state);
      }
    } else {
      scanFreeGamesPage();
    }
  }

  // Auto-init on top-level window load
  window.addEventListener('load', () => {
    registerTimeout(() => {
      createHUD();
      const state = getState();

      if (state.stopped) {
        isStopped = true;
        updateHUDStatus('⏹ <b>Auto-claim paused.</b> Click Start or Resume to proceed.', false);
        updateHUDButtons(false);
        return;
      }

      if (state.active && state.queue && state.queue.length > 0) {
        startClaimProcess(false, false);
      } else if (window.location.pathname.includes('/free-games')) {
        updateHUDStatus('✨ On Free Games page. Starting auto-claim in 2s...');
        updateHUDButtons(true);
        registerTimeout(() => {
          if (!isStopped) {
            startClaimProcess(true, false);
          }
        }, 2000);
      } else {
        updateHUDStatus('Ready. Click <b>"Start Auto-Claim"</b> or visit Free Games section.', false);
        updateHUDButtons(false);
      }
    }, 1500);
  });
})();
