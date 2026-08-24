// ==UserScript==
// @name         Epic Games Store - Auto Free Games Claimer
// @namespace    https://github.com/Boomkaas/dotfiles
// @version      1.1.0
// @description  Automatically claims weekly free games in your native logged-in Firefox without rushing.
// @author       Peng
// @match        https://store.epicgames.com/*
// @match        https://www.epicgames.com/store/*
// @match        https://*.epicgames.com/*
// @grant        none
// @run-at       document-idle
// ==/UserScript==

(function () {
  'use strict';

  const isTopWindow = window.self === window.top;
  const STORAGE_KEY = 'epic_auto_claim_state';
  const DELAY_PAGE_LOAD = 3500;        // 3.5s to ensure React hydration & session load
  const DELAY_BETWEEN_ACTIONS = 2500;   // 2.5s calm pace ("don't rush")
  const DELAY_CHECKOUT_POLL = 1000;     // 1.0s polling for checkout elements

  const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

  function getState() {
    try {
      return JSON.parse(sessionStorage.getItem(STORAGE_KEY)) || { active: false, queue: [], currentIndex: 0, status: 'idle' };
    } catch {
      return { active: false, queue: [], currentIndex: 0, status: 'idle' };
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
    // If running inside a purchase/checkout iframe, ONLY assist with checkout.
    // NEVER navigate the parent page or touch the queue.
    async function handleIframeCheckout() {
      let attempts = 0;
      const maxAttempts = 30; // 30 seconds

      while (attempts < maxAttempts) {
        attempts++;

        // 1. Handle agreement checkboxes
        const checkboxes = document.querySelectorAll('input[type="checkbox"]');
        for (const cb of checkboxes) {
          if (!cb.checked) {
            cb.click();
            await sleep(400);
          }
        }

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

        if (orderBtn) {
          console.log('[Epic Claimer Iframe] Found order button:', orderBtn.innerText);
          await sleep(1500); // calm delay
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

        await sleep(DELAY_CHECKOUT_POLL);
      }
    }

    // Start iframe observer
    setTimeout(handleIframeCheckout, 1500);
    return; // Exit script for iframes!
  }

  // ==========================================
  // TOP-LEVEL WINDOW HANDLER (Main Controller)
  // ==========================================

  // Listen for iframe messages
  window.addEventListener('message', (event) => {
    if (!event.data || !event.data.type) return;
    if (event.data.type === 'EPIC_CLAIMER_ORDER_CLICKED') {
      updateHUDStatus('📝 Order placed inside checkout frame! Waiting for confirmation...');
    } else if (event.data.type === 'EPIC_CLAIMER_ORDER_COMPLETED') {
      updateHUDStatus('🎉 Order confirmed in checkout frame!');
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
        min-width: 300px;
        max-width: 380px;
        transition: all 0.3s ease;
      ">
        <div style="display: flex; align-items: center; justify-content: space-between; margin-bottom: 10px;">
          <div style="display: flex; align-items: center; gap: 8px;">
            <span style="font-size: 20px;">🎮</span>
            <span style="font-weight: 700; font-size: 14px; letter-spacing: 0.5px; color: #33ccff;">EPIC AUTO-CLAIMER</span>
          </div>
          <span id="epic-hud-spinner" style="font-size: 14px; animation: epic-spin 2s linear infinite;">⏳</span>
        </div>
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
          ">▶ Start Auto-Claim</button>
          <button id="epic-hud-stop" style="
            padding: 8px 12px;
            background: rgba(255, 255, 255, 0.1);
            border: 1px solid rgba(255, 255, 255, 0.2);
            border-radius: 8px;
            color: #ccc;
            font-size: 12px;
            cursor: pointer;
          ">Stop</button>
        </div>
      </div>
      <style>
        @keyframes epic-spin { 100% { transform: rotate(360deg); } }
      </style>
    `;
    document.body.appendChild(hud);

    document.getElementById('epic-hud-start').addEventListener('click', () => {
      startClaimProcess(true);
    });

    document.getElementById('epic-hud-stop').addEventListener('click', () => {
      clearState();
      updateHUDStatus('⏹ Auto-claim stopped.', false);
    });
  }

  function updateHUDStatus(text, showSpinner = true) {
    const statusEl = document.getElementById('epic-hud-status');
    const spinnerEl = document.getElementById('epic-hud-spinner');
    if (statusEl) statusEl.innerHTML = text;
    if (spinnerEl) spinnerEl.style.display = showSpinner ? 'inline-block' : 'none';
  }

  // Step 1: Scan for free games on the Free Games / Store Hub
  async function scanFreeGamesPage() {
    updateHUDStatus('🔍 Scanning for weekly free games...');
    await sleep(DELAY_PAGE_LOAD);

    const candidates = [];
    const allLinks = Array.from(document.querySelectorAll('a[href*="/p/"], a[href*="/bundles/"]'));

    for (const link of allLinks) {
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

    if (candidates.length === 0) {
      updateHUDStatus('✨ <b>All current free games are already in your library!</b>', false);
      clearState();
      return;
    }

    updateHUDStatus(`🎯 Found <b>${candidates.length}</b> unclaimed free game(s)! Starting claim sequence...`);
    await sleep(DELAY_BETWEEN_ACTIONS);

    const state = {
      active: true,
      queue: candidates,
      currentIndex: 0,
      status: 'navigating'
    };
    setState(state);
    window.location.href = candidates[0];
  }

  // Step 2: Handle individual product page
  async function handleGamePage(state) {
    const gameIndex = state.currentIndex + 1;
    const totalGames = state.queue.length;

    updateHUDStatus(`🎮 <b>Game ${gameIndex}/${totalGames}</b>: Checking page status...`);
    await sleep(DELAY_PAGE_LOAD);

    // 1. Check Age Gate / Content Warning
    const continueBtn = Array.from(document.querySelectorAll('button, a')).find(el => {
      const t = (el.innerText || '').trim().toLowerCase();
      return t === 'continue' || t === 'view product' || t === 'yes';
    });

    if (continueBtn) {
      updateHUDStatus('⚠️ Age confirmation prompt detected. Clicking Continue...');
      continueBtn.click();
      await sleep(DELAY_BETWEEN_ACTIONS);
    }

    // 2. Check if already owned
    const pageText = document.body ? document.body.innerText : '';
    if (pageText.includes('In Library') || pageText.includes('IN LIBRARY')) {
      updateHUDStatus(`✅ <b>Game ${gameIndex}/${totalGames}</b> already in library! Moving to next...`);
      await sleep(DELAY_BETWEEN_ACTIONS);
      advanceQueue(state);
      return;
    }

    // 3. Find the "GET" button on the game page
    const getButton = Array.from(document.querySelectorAll('button')).find(btn => {
      const text = (btn.innerText || '').trim().toUpperCase();
      const testId = btn.getAttribute('data-testid') || '';
      const isGet = (text === 'GET' || text === 'Get' || testId.includes('purchase-cta'));
      return isGet && !btn.disabled && !text.includes('IN LIBRARY');
    });

    if (!getButton) {
      updateHUDStatus(`⚠️ Could not find "GET" button (may already be in library). Advancing...`);
      await sleep(DELAY_BETWEEN_ACTIONS);
      advanceQueue(state);
      return;
    }

    // Click GET calmly
    updateHUDStatus(`🛒 Clicking <b>GET</b> button...`);
    getButton.scrollIntoView({ behavior: 'smooth', block: 'center' });
    await sleep(1000);
    getButton.click();

    updateHUDStatus(`⏳ Waiting for checkout overlay / dialog...`);
    await sleep(3000);

    // 4. Handle the checkout overlay (top window + iframe checking)
    await monitorAndCompleteCheckout(state);
  }

  // Step 3: Monitor Checkout and wait for completion
  async function monitorAndCompleteCheckout(state) {
    let secondsElapsed = 0;
    const timeoutSeconds = 40; // Wait up to 40 seconds for checkout to finish

    while (secondsElapsed < timeoutSeconds) {
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

      if (orderBtn) {
        updateHUDStatus(`📝 Found <b>${orderBtn.innerText || 'Place Order'}</b> button! Finalizing...`);
        // Check agreement checkboxes in top level
        const cbs = document.querySelectorAll('input[type="checkbox"]');
        for (const cb of cbs) {
          if (!cb.checked) cb.click();
        }
        await sleep(1500); // calm pace
        orderBtn.click();
        updateHUDStatus(`🎉 Order placed! Waiting for confirmation...`);
        await sleep(5000);
        advanceQueue(state);
        return;
      }

      // 2. Check if purchase confirmation / thank you screen is visible
      const bodyText = document.body ? document.body.innerText : '';
      if (bodyText.includes('Thank you for buying') || 
          bodyText.includes('Thank you for your order') || 
          bodyText.includes('Order Complete')) {
        updateHUDStatus(`🎉 Purchase confirmed! Moving to next game...`);
        await sleep(DELAY_BETWEEN_ACTIONS);
        advanceQueue(state);
        return;
      }

      // 3. Check if the page reverted to "In Library"
      const inLibraryBtn = topButtons.find(b => (b.innerText || '').trim().toUpperCase().includes('IN LIBRARY'));
      if (inLibraryBtn && secondsElapsed > 8) {
        updateHUDStatus(`✅ Game is now marked In Library! Moving to next...`);
        await sleep(DELAY_BETWEEN_ACTIONS);
        advanceQueue(state);
        return;
      }

      updateHUDStatus(`⏳ Waiting for checkout completion (${Math.round(secondsElapsed)}s / ${timeoutSeconds}s)...`);
      await sleep(1500);
    }

    // If reached here, either completed or manual intervention was done
    updateHUDStatus(`⚠️ Proceeding to next game in queue...`);
    await sleep(DELAY_BETWEEN_ACTIONS);
    advanceQueue(state);
  }

  function advanceQueue(state) {
    state.currentIndex++;
    if (state.currentIndex < state.queue.length) {
      setState(state);
      window.location.href = state.queue[state.currentIndex];
    } else {
      updateHUDStatus('🎉 <b>All weekly free games have been claimed!</b>', false);
      clearState();
      setTimeout(() => {
        window.location.href = 'https://store.epicgames.com/en-US/free-games';
      }, 3500);
    }
  }

  function startClaimProcess(manualTrigger = false) {
    createHUD();
    const state = getState();

    if (manualTrigger) {
      clearState();
      scanFreeGamesPage();
      return;
    }

    if (state.active && state.queue.length > 0) {
      const currentUrl = window.location.href;
      if (currentUrl.includes('/free-games') && state.currentIndex === 0) {
        scanFreeGamesPage();
      } else {
        handleGamePage(state);
      }
    } else {
      updateHUDStatus('Ready. Click <b>"Start Auto-Claim"</b> or visit the Free Games section.', false);
    }
  }

  // Auto-init on top-level window load
  window.addEventListener('load', () => {
    setTimeout(() => {
      createHUD();
      const state = getState();
      if (state.active) {
        startClaimProcess(false);
      } else if (window.location.pathname.includes('/free-games')) {
        updateHUDStatus('✨ On Free Games page. Starting auto-claim in 2s...');
        setTimeout(() => startClaimProcess(true), 2000);
      }
    }, 1500);
  });
})();
