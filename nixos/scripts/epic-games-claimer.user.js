// ==UserScript==
// @name         Epic Games Store - Auto Free Games Claimer
// @namespace    https://github.com/Boomkaas/dotfiles
// @version      1.0.0
// @description  Automatically claims weekly free games in your native logged-in Firefox without rushing.
// @author       Peng
// @match        https://store.epicgames.com/*
// @match        https://www.epicgames.com/store/*
// @grant        none
// @run-at       document-idle
// ==/UserScript==

(function () {
  'use strict';

  const STORAGE_KEY = 'epic_auto_claim_state';
  const DELAY_PAGE_LOAD = 3500;  // 3.5s to ensure React hydration & session load
  const DELAY_BETWEEN_ACTIONS = 2500; // 2.5s calm pace ("don't rush")
  const DELAY_CHECKOUT = 3500;   // 3.5s for payment modal to appear

  // Helpers
  const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

  function getState() {
    try {
      return JSON.parse(sessionStorage.getItem(STORAGE_KEY)) || { active: false, queue: [], currentIndex: 0, claimed: [] };
    } catch {
      return { active: false, queue: [], currentIndex: 0, claimed: [] };
    }
  }

  function setState(state) {
    sessionStorage.setItem(STORAGE_KEY, JSON.stringify(state));
  }

  function clearState() {
    sessionStorage.removeItem(STORAGE_KEY);
  }

  // Floating HUD
  function createHUD() {
    if (document.getElementById('epic-claimer-hud')) return;

    const hud = document.createElement('div');
    hud.id = 'epic-claimer-hud';
    hud.innerHTML = `
      <div style="
        position: fixed;
        bottom: 24px;
        right: 24px;
        z-index: 999999;
        background: rgba(18, 18, 26, 0.95);
        backdrop-filter: blur(12px);
        -webkit-backdrop-filter: blur(12px);
        border: 1px solid rgba(51, 204, 255, 0.4);
        border-radius: 14px;
        box-shadow: 0 10px 30px rgba(0, 0, 0, 0.7), 0 0 15px rgba(51, 204, 255, 0.2);
        padding: 16px 20px;
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
        color: #f0f0f0;
        min-width: 290px;
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
            transition: opacity 0.2s;
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

  // Step 1: Scan for free games on Store / Free Games hub
  async function scanFreeGamesPage() {
    updateHUDStatus('🔍 Scanning for weekly free games...');
    await sleep(DELAY_PAGE_LOAD);

    const candidates = [];
    const allLinks = Array.from(document.querySelectorAll('a[href*="/p/"], a[href*="/bundles/"]'));

    for (const link of allLinks) {
      const href = link.getAttribute('href');
      if (!href) continue;

      const fullUrl = new URL(href, window.location.origin).href;
      // Look at card text or surrounding container
      const card = link.closest('[data-component="FreeGamesCard"]') || link.closest('div') || link;
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
      claimed: []
    };
    setState(state);
    window.location.href = candidates[0];
  }

  // Step 2: Handle individual game page
  async function handleGamePage(state) {
    const gameIndex = state.currentIndex + 1;
    const totalGames = state.queue.length;

    updateHUDStatus(`🎮 <b>Game ${gameIndex}/${totalGames}</b>: Checking page status...`);
    await sleep(DELAY_PAGE_LOAD);

    // 1. Check Age Gate / Content Warning
    const continueBtn = Array.from(document.querySelectorAll('button, a')).find(el => {
      const t = el.innerText.trim().toLowerCase();
      return t === 'continue' || t === 'view product' || t === 'yes';
    });

    if (continueBtn) {
      updateHUDStatus('⚠️ Age confirmation prompt detected. Clicking Continue...');
      continueBtn.click();
      await sleep(DELAY_BETWEEN_ACTIONS);
    }

    // 2. Check if already owned
    const bodyText = document.body.innerText;
    const isOwned = bodyText.includes('In Library') || bodyText.includes('IN LIBRARY');

    // 3. Find the "GET" button
    const getButton = Array.from(document.querySelectorAll('button')).find(btn => {
      const text = btn.innerText.trim().toUpperCase();
      const testId = btn.getAttribute('data-testid') || '';
      return (text === 'GET' || text === 'Get' || testId.includes('purchase-cta')) && !btn.disabled && !text.includes('IN LIBRARY');
    });

    if (!getButton) {
      if (isOwned) {
        updateHUDStatus(`✅ <b>Game ${gameIndex}/${totalGames}</b> already in library! Moving to next...`);
      } else {
        updateHUDStatus(`⚠️ Could not find active "GET" button (may be owned or unavailable). Advancing...`);
      }
      await sleep(DELAY_BETWEEN_ACTIONS);
      advanceQueue(state);
      return;
    }

    // Click GET
    updateHUDStatus(`🛒 Clicking <b>GET</b> button (calm pace)...`);
    getButton.scrollIntoView({ behavior: 'smooth', block: 'center' });
    await sleep(1000);
    getButton.click();

    updateHUDStatus(`⏳ Waiting for checkout dialog to load...`);
    await sleep(DELAY_CHECKOUT);

    // 4. Handle Checkout Modal / Iframe / Place Order
    await handleCheckoutFlow(state);
  }

  async function handleCheckoutFlow(state) {
    const maxRetries = 15;
    let retries = 0;

    while (retries < maxRetries) {
      retries++;

      // Check EULA / Email agreement checkboxes if any
      const checkboxes = document.querySelectorAll('input[type="checkbox"]');
      for (const cb of checkboxes) {
        if (!cb.checked && (cb.id?.includes('agree') || cb.name?.includes('agree') || cb.closest('label')?.innerText.includes('agree'))) {
          cb.click();
          await sleep(500);
        }
      }

      // Look for "Place Order" button
      const placeOrderBtn = Array.from(document.querySelectorAll('button')).find(btn => {
        const text = btn.innerText.trim().toUpperCase();
        const testId = btn.getAttribute('data-testid') || '';
        return (text === 'PLACE ORDER' || text === 'Place Order' || testId.includes('purchase-button') || btn.classList.contains('payment-btn')) && !btn.disabled;
      });

      if (placeOrderBtn) {
        updateHUDStatus(`📝 Found <b>Place Order</b> button! Finalizing free claim...`);
        await sleep(1500); // polite pause
        placeOrderBtn.click();
        updateHUDStatus(`🎉 Order placed! Waiting for confirmation...`);
        await sleep(4500);

        state.claimed.push(window.location.pathname);
        advanceQueue(state);
        return;
      }

      // Check if order already went through or redirected back
      if (document.body.innerText.includes('Thank you for buying') || document.body.innerText.includes('Thank you for your order')) {
        updateHUDStatus(`🎉 Purchase confirmed! Moving to next game...`);
        await sleep(DELAY_BETWEEN_ACTIONS);
        state.claimed.push(window.location.pathname);
        advanceQueue(state);
        return;
      }

      await sleep(1000);
    }

    updateHUDStatus(`⚠️ Checkout dialog timed out or manual confirmation needed. Moving to next...`);
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
      }, 3000);
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

  // Auto-init on page load
  window.addEventListener('load', () => {
    setTimeout(() => {
      createHUD();
      const state = getState();
      if (state.active) {
        startClaimProcess(false);
      } else if (window.location.pathname.includes('/free-games')) {
        updateHUDStatus('✨ On Free Games page. Starting scan in 2 seconds...');
        setTimeout(() => startClaimProcess(true), 2000);
      }
    }, 1500);
  });
})();
