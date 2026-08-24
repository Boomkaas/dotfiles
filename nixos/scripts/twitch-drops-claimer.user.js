// ==UserScript==
// @name         Twitch Drops Auto-Claimer (DST & DBD Priority)
// @namespace    https://github.com/Boomkaas/dotfiles
// @version      1.2.0
// @description  Automates Twitch Drops for Don't Starve Together and Dead by Daylight, filters out Russian streams, stays on stream to farm watch time, auto-claims, with ultra-eco mode (160p, muted, low RAM/CPU/GPU/WiFi), and closes only when all drops are finished.
// @author       Peng
// @match        https://www.twitch.tv/*
// @grant        GM_closeTab
// @grant        window.close
// @run-at       document-idle
// ==/UserScript==

(function () {
  'use strict';

  const isTopWindow = window.self === window.top;
  if (!isTopWindow) return; // Only run in top window

  // ============================================================
  // ULTRA-ECO PRE-SEED (Forces 160p, Muted, Low-Latency off)
  // ============================================================
  try {
    localStorage.setItem('video-quality', JSON.stringify({ default: '160p30' }));
    localStorage.setItem('video-muted', JSON.stringify({ default: true }));
    localStorage.setItem('volume', '0');
    localStorage.setItem('lowLatency', 'false');
  } catch (e) {}

  const STORAGE_KEY = 'twitch_drops_claimer_state';
  const CHECK_INTERVAL = 3000;

  const TARGET_GAMES = [
    {
      name: "Don't Starve Together",
      slug: "dont-starve-together",
      aliases: ["don't starve together", "dont starve together", "dst"]
    },
    {
      name: "Dead by Daylight",
      slug: "dead-by-daylight",
      aliases: ["dead by daylight", "dbd"]
    }
  ];

  const RU_REGEX = /(russian|русский|рус|\[ru\]|\(ru\)|ru\/|\/ru|\bru\b|\brussians\b)/i;

  const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

  function getState() {
    try {
      return JSON.parse(sessionStorage.getItem(STORAGE_KEY)) || {
        active: false,
        gameIndex: 0,
        currentGame: null,
        currentStreamer: null,
        watchStartTime: Date.now()
      };
    } catch {
      return { active: false, gameIndex: 0, currentGame: null, currentStreamer: null, watchStartTime: Date.now() };
    }
  }

  function setState(state) {
    try {
      sessionStorage.setItem(STORAGE_KEY, JSON.stringify(state));
    } catch (e) {}
  }

  function clearState() {
    try {
      sessionStorage.removeItem(STORAGE_KEY);
    } catch (e) {}
  }

  function closeTab(delayMs = 4000) {
    setTimeout(() => {
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

  // ============================================================
  // ULTRA-ECO CSS INJECTION (Drastically cuts CPU / GPU / RAM)
  // ============================================================
  function injectEcoStyles() {
    if (document.getElementById('twitch-eco-styles')) return;
    const style = document.createElement('style');
    style.id = 'twitch-eco-styles';
    style.textContent = `
      /* Disable expensive background animations & rendering */
      .chat-room__viewer-status,
      .chat-line__status,
      [data-test-selector="community-points-summary"],
      .stream-chat-header,
      .reward-center,
      .animated-emote__img {
        display: none !important;
      }
      /* Prevent GPU scaling overhead on video element */
      .video-player video {
        image-rendering: pixelated !important;
        will-change: auto !important;
      }
    `;
    document.head.appendChild(style);
  }

  // Floating HUD UI
  function createHUD() {
    if (document.getElementById('twitch-drops-hud')) return;
    injectEcoStyles();

    const hud = document.createElement('div');
    hud.id = 'twitch-drops-hud';
    hud.innerHTML = `
      <div style="
        position: fixed;
        bottom: 24px;
        right: 24px;
        z-index: 9999999;
        background: rgba(15, 14, 23, 0.95);
        backdrop-filter: blur(14px);
        -webkit-backdrop-filter: blur(14px);
        border: 1px solid rgba(145, 70, 255, 0.5);
        border-radius: 14px;
        box-shadow: 0 12px 35px rgba(0, 0, 0, 0.8), 0 0 15px rgba(145, 70, 255, 0.3);
        padding: 16px 20px;
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
        color: #f0f0f0;
        min-width: 320px;
        max-width: 390px;
        transition: all 0.3s ease;
      ">
        <div style="display: flex; align-items: center; justify-content: space-between; margin-bottom: 8px;">
          <div style="display: flex; align-items: center; gap: 8px;">
            <span style="font-size: 20px;">🟣</span>
            <span style="font-weight: 700; font-size: 14px; letter-spacing: 0.5px; color: #a970ff;">TWITCH DROPS CLAIMER</span>
          </div>
          <span id="tdrops-spinner" style="font-size: 14px; animation: tdrops-spin 2s linear infinite;">⏳</span>
        </div>
        <div style="display: inline-block; padding: 2px 8px; border-radius: 6px; background: rgba(0, 200, 83, 0.15); border: 1px solid rgba(0, 200, 83, 0.3); color: #00e676; font-size: 11px; font-weight: 600; margin-bottom: 10px;">
          🌿 Ultra-Eco: 160p • Muted • Auto-Farming
        </div>
        <div id="tdrops-status" style="font-size: 13px; color: #dedede; line-height: 1.4; margin-bottom: 12px;">
          Initializing auto-claimer...
        </div>
        <div style="display: flex; gap: 8px;">
          <button id="tdrops-btn-start" style="
            flex: 1;
            padding: 8px 12px;
            background: linear-gradient(135deg, #9146ff, #772ce8);
            border: none;
            border-radius: 8px;
            color: #fff;
            font-size: 12px;
            font-weight: 600;
            cursor: pointer;
          ">▶ Check Drops</button>
          <button id="tdrops-btn-stop" style="
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
        @keyframes tdrops-spin { 100% { transform: rotate(360deg); } }
      </style>
    `;
    document.body.appendChild(hud);

    document.getElementById('tdrops-btn-start').addEventListener('click', () => {
      clearState();
      window.location.href = 'https://www.twitch.tv/drops/campaigns';
    });

    document.getElementById('tdrops-btn-stop').addEventListener('click', () => {
      clearState();
      updateHUDStatus('⏹ Auto-claimer stopped.', false);
    });
  }

  function updateHUDStatus(text, showSpinner = true) {
    const statusEl = document.getElementById('tdrops-status');
    const spinnerEl = document.getElementById('tdrops-spinner');
    if (statusEl) statusEl.innerHTML = text;
    if (spinnerEl) spinnerEl.style.display = showSpinner ? 'inline-block' : 'none';
  }

  // ============================================================
  // ULTRA-ECO ENFORCER (160p Quality, Mute, Chat Collapse)
  // ============================================================
  async function enforceUltraEcoMode() {
    // 1. Mute HTML5 video elements immediately (0% Audio CPU)
    const videos = document.querySelectorAll('video');
    for (const v of videos) {
      if (!v.muted) v.muted = true;
      if (v.volume !== 0) v.volume = 0;
    }

    // 2. Click player mute button if unmuted
    const muteBtn = document.querySelector('button[data-a-target="player-mute-unmute-button"]');
    const isMuted = muteBtn && muteBtn.getAttribute('aria-label')?.toLowerCase().includes('unmute');
    if (muteBtn && !isMuted) {
      muteBtn.click();
      console.log('[Twitch Drops] Enforced video mute');
    }

    // 3. Set quality to 160p (Saves ~97% WiFi / Bandwidth & GPU)
    const settingsBtn = document.querySelector('button[data-a-target="player-settings-button"]');
    if (settingsBtn) {
      settingsBtn.click();
      await sleep(250);

      const qualityMenuBtn = document.querySelector('button[data-a-target="player-settings-menu-item-quality"]');
      if (qualityMenuBtn) {
        qualityMenuBtn.click();
        await sleep(250);

        const qualityOptions = Array.from(document.querySelectorAll('[data-a-target="player-settings-submenu-quality-option"]'));
        const lowest160p = qualityOptions.find(opt => opt.innerText.includes('160p')) || qualityOptions[qualityOptions.length - 1];
        if (lowest160p && !lowest160p.querySelector('[data-a-target="tw-core-button-label-text"]')?.innerText.includes('160p')) {
          lowest160p.click();
          console.log('[Twitch Drops] Enforced 160p lowest quality');
        }
      }

      // Close settings menu
      if (settingsBtn.getAttribute('aria-expanded') === 'true') {
        settingsBtn.click();
      }
    }

    // 4. Collapse Twitch Chat (Saves massive RAM & CPU from message streaming)
    const collapseChatBtn = document.querySelector('button[data-a-target="right-column__toggle-collapse-btn"]');
    const isChatOpen = collapseChatBtn && collapseChatBtn.getAttribute('aria-label')?.toLowerCase().includes('collapse');
    if (collapseChatBtn && isChatOpen) {
      collapseChatBtn.click();
      console.log('[Twitch Drops] Collapsed live chat to save RAM & CPU');
    }
  }

  // Auto-click point bonus & drop buttons on any active page
  function autoClaimButtons() {
    // 1. Channel Points Bonus Box
    const bonusBtn = document.querySelector('.claimable-bonus__icon, [aria-label*="Claim Bonus"]');
    if (bonusBtn) {
      bonusBtn.click();
      console.log('[Twitch Drops] Claimed channel bonus points!');
    }

    // 2. Drop Claim Now buttons in chat / notifications / inventory
    const claimButtons = Array.from(document.querySelectorAll('button')).filter(btn => {
      const text = (btn.innerText || '').trim().toUpperCase();
      const testId = btn.getAttribute('data-test-selector') || '';
      return (text === 'CLAIM NOW' || text === 'CLAIM' || testId.includes('claim-button')) && !btn.disabled;
    });

    for (const btn of claimButtons) {
      btn.click();
      console.log('[Twitch Drops] Clicked Drop Claim button!');
      updateHUDStatus('🎁 <b>Claimed a Drop reward!</b> Continuing watch time...');
    }

    // 3. Mature Content Warning ("Start Watching" / "I Understand")
    const matureBtn = document.querySelector('[data-a-target="player-overlay-mature-accept"], button[data-a-target="content-classification-gate-overlay-start-watching-button"]');
    if (matureBtn) {
      matureBtn.click();
      console.log('[Twitch Drops] Dismissed mature content gate');
    }
  }

  // 1. CAMPAIGNS PAGE HANDLER
  async function handleCampaignsPage() {
    updateHUDStatus('🔍 Scanning active campaigns for <b>DST</b> & <b>DBD</b>...');
    await sleep(4500);

    const pageText = document.body ? document.body.innerText.toLowerCase() : '';

    // Check Priority 1: Don't Starve Together, Priority 2: Dead by Daylight
    let targetGame = null;
    for (const game of TARGET_GAMES) {
      const isAvailable = game.aliases.some(alias => pageText.includes(alias));
      if (isAvailable) {
        targetGame = game;
        break;
      }
    }

    if (!targetGame) {
      updateHUDStatus('ℹ️ Neither <b>DST</b> nor <b>DBD</b> have active drop campaigns. Checking inventory...');
      await sleep(2500);
      window.location.href = 'https://www.twitch.tv/drops/inventory';
      return;
    }

    updateHUDStatus(`🎯 Found active campaign for <b>${targetGame.name}</b>! Finding non-Russian stream...`);
    const state = {
      active: true,
      currentGame: targetGame,
      watchStartTime: Date.now()
    };
    setState(state);

    await sleep(2000);
    window.location.href = `https://www.twitch.tv/directory/category/${targetGame.slug}?filter=drops`;
  }

  // 2. DIRECTORY STREAM SELECTION (Filter out Russian streams)
  async function handleDirectoryPage(state) {
    const game = state.currentGame || TARGET_GAMES[0];
    updateHUDStatus(`🔎 Searching for <b>${game.name}</b> streams (excluding Russian)...`);
    await sleep(4500);

    const streamCards = Array.from(document.querySelectorAll('[data-target="directory-game__card"], [data-target="directory-container"] [data-a-target^="preview-card-image-link"], div[class*="ScTower"] article, article'));
    let chosenUrl = null;
    let chosenTitle = '';

    for (const card of streamCards) {
      const text = card.innerText || '';
      const link = card.querySelector('a[data-a-target="preview-card-image-link"], a[data-a-target="preview-card-channel-link"], a[href^="/"]');
      if (!link) continue;

      const href = link.getAttribute('href');
      if (!href || href.startsWith('/directory') || href.includes('/videos')) continue;

      // Check if Russian language tag or title
      if (RU_REGEX.test(text) || RU_REGEX.test(href)) {
        console.log('[Twitch Drops] Skipping Russian stream:', href);
        continue;
      }

      // Valid non-Russian stream found!
      chosenUrl = new URL(href, window.location.origin).href;
      chosenTitle = text.split('\n')[0] || href;
      break;
    }

    if (!chosenUrl) {
      // Fallback: take first channel link that is not obviously Russian
      const anyLinks = Array.from(document.querySelectorAll('a[data-a-target="preview-card-channel-link"]'));
      for (const a of anyLinks) {
        const href = a.getAttribute('href');
        if (href && !RU_REGEX.test(href) && !RU_REGEX.test(a.innerText)) {
          chosenUrl = new URL(href, window.location.origin).href;
          break;
        }
      }
    }

    if (!chosenUrl) {
      updateHUDStatus('⚠️ No active non-Russian streams found with drops. Checking inventory...');
      await sleep(3000);
      window.location.href = 'https://www.twitch.tv/drops/inventory';
      return;
    }

    updateHUDStatus(`📺 Found stream: <b>${chosenTitle}</b>. Joining in Ultra-Eco mode...`);
    state.currentStreamer = chosenUrl;
    state.watchStartTime = Date.now();
    setState(state);

    await sleep(1500);
    window.location.href = chosenUrl;
  }

  // 3. STREAM WATCHING & CONTINUOUS MONITORING
  async function handleStreamPage(state) {
    const gameName = state.currentGame ? state.currentGame.name : 'Target Game';
    const channelName = window.location.pathname.replace(/\//g, '');
    updateHUDStatus(`👀 Watching <b>${channelName}</b> for <b>${gameName}</b> drops (🌿 Ultra-Eco)...`);

    // Enforce Eco settings on stream start
    setTimeout(enforceUltraEcoMode, 3000);
    setTimeout(enforceUltraEcoMode, 8000);

    let minutesWatched = 0;

    // Watchdog loop (stays ON stream — does NOT navigate away!)
    setInterval(() => {
      autoClaimButtons();

      // Check if stream is offline
      const isOffline = document.querySelector('.channel-status-info--offline, [data-a-target="player-overlay-offline"]');
      if (isOffline) {
        updateHUDStatus('⚠️ Stream went offline. Finding another non-Russian stream...');
        if (state.currentGame) {
          window.location.href = `https://www.twitch.tv/directory/category/${state.currentGame.slug}?filter=drops`;
        } else {
          window.location.href = 'https://www.twitch.tv/drops/campaigns';
        }
        return;
      }

      // Update minutes counter in HUD
      minutesWatched = Math.floor((Date.now() - (state.watchStartTime || Date.now())) / 60000);
      updateHUDStatus(`👀 Watching <b>${channelName}</b> for <b>${gameName}</b> (${minutesWatched}m farmed • 🌿 Eco)...`);
    }, CHECK_INTERVAL);
  }

  // 4. INVENTORY & CLAIM CONFIRMATION
  async function handleInventoryPage(state) {
    updateHUDStatus('📦 Checking Drops inventory & claiming rewards...');
    await sleep(4500);

    autoClaimButtons();
    await sleep(2500);

    const pageText = document.body ? document.body.innerText.toLowerCase() : '';

    // 1. Check Priority 1: Don't Starve Together
    const dstGame = TARGET_GAMES[0];
    const isDstMentioned = dstGame.aliases.some(a => pageText.includes(a));
    const isDstCompleted = pageText.includes("don't starve together") && (pageText.includes('100%') || pageText.includes('claimed')) && !pageText.includes('remaining');

    if (isDstMentioned && !isDstCompleted) {
      updateHUDStatus(`⏳ Active drop found for <b>${dstGame.name}</b>. Resuming stream...`);
      state.currentGame = dstGame;
      setState(state);
      await sleep(2500);
      window.location.href = `https://www.twitch.tv/directory/category/${dstGame.slug}?filter=drops`;
      return;
    }

    // 2. Check Priority 2: Dead by Daylight
    const dbdGame = TARGET_GAMES[1];
    const isDbdMentioned = dbdGame.aliases.some(a => pageText.includes(a));
    const isDbdCompleted = pageText.includes('dead by daylight') && (pageText.includes('100%') || pageText.includes('claimed')) && !pageText.includes('remaining');

    if (isDbdMentioned && !isDbdCompleted) {
      updateHUDStatus(`⏳ Active drop found for <b>${dbdGame.name}</b>. Resuming stream...`);
      state.currentGame = dbdGame;
      setState(state);
      await sleep(2500);
      window.location.href = `https://www.twitch.tv/directory/category/${dbdGame.slug}?filter=drops`;
      return;
    }

    // 3. If any target game was selected in state, re-verify with the directory before giving up
    if (state.currentGame) {
      updateHUDStatus(`🔎 Checking if more drops exist for <b>${state.currentGame.name}</b>...`);
      const gameToResume = state.currentGame;
      await sleep(2000);
      window.location.href = `https://www.twitch.tv/directory/category/${gameToResume.slug}?filter=drops`;
      return;
    }

    // All target drops are truly completed or no campaigns exist
    updateHUDStatus('🎉 <b>All drops for DST & DBD have been claimed!</b> Closing window in 4s...', false);
    clearState();
    closeTab(4000);
  }

  // Router based on URL
  function route() {
    createHUD();
    setInterval(autoClaimButtons, 2000);

    const path = window.location.pathname;
    const state = getState();

    if (path.includes('/drops/campaigns')) {
      handleCampaignsPage();
    } else if (path.includes('/directory/category/')) {
      handleDirectoryPage(state);
    } else if (path.includes('/drops/inventory')) {
      handleInventoryPage(state);
    } else if (path !== '/' && !path.startsWith('/directory') && !path.startsWith('/downloads')) {
      handleStreamPage(state);
    } else {
      updateHUDStatus('Ready. Click <b>"Check Drops"</b> to start.', false);
    }
  }

  window.addEventListener('load', () => {
    setTimeout(route, 2000);
  });
})();
