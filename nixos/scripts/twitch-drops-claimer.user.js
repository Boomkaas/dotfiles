// ==UserScript==
// @name         Twitch Drops Auto-Claimer (DST & DBD Priority)
// @namespace    https://github.com/Boomkaas/dotfiles
// @version      1.5.0
// @description  Automates Twitch Drops for Don't Starve Together and Dead by Daylight. Stays on the Inventory page with a mini overlay stream player, auto-claims, calculates exact remaining time from highest drop duration (+5m buffer), and reloads on completion.
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
  const CHECK_INTERVAL = 2000;
  const EXTRA_BUFFER_MINUTES = 5; // 5 minutes safety buffer

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
        currentGame: null,
        currentChannel: null,
        targetEndTime: null,
        totalMinutes: 180,
        calculatedWaitMinutes: 135,
        progressPercent: 0
      };
    } catch {
      return { active: false, currentGame: null, currentChannel: null, targetEndTime: null, totalMinutes: 180, calculatedWaitMinutes: 135, progressPercent: 0 };
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
  // TIME & PERCENTAGE PARSER (Picks the HIGHEST drop duration)
  // ============================================================
  function parseWatchTimeAndProgress(containerText) {
    const text = containerText.toLowerCase();

    let percent = 0;
    let maxTotalMinutes = 0;

    // 1. Check for explicit "X% of Y hours/mins"
    const explicitHourMatch = text.match(/(\d+)%\s*of\s*(\d+(?:\.\d+)?)\s*(?:hours?|hrs?|h)\b/i);
    const explicitMinMatch = text.match(/(\d+)%\s*of\s*(\d+)\s*(?:minutes?|mins?|m)\b/i);

    if (explicitHourMatch) {
      percent = parseFloat(explicitHourMatch[1]);
      maxTotalMinutes = parseFloat(explicitHourMatch[2]) * 60;
    } else if (explicitMinMatch) {
      percent = parseFloat(explicitMinMatch[1]);
      maxTotalMinutes = parseFloat(explicitMinMatch[2]);
    } else {
      // 2. Scan for ALL hour and minute mentions and select the HIGHEST duration
      const allHourMatches = Array.from(text.matchAll(/(\d+(?:\.\d+)?)\s*(?:hours?|hrs?|h)\b/gi));
      const allMinMatches = Array.from(text.matchAll(/(\d+)\s*(?:minutes?|mins?|m)\b/gi));

      for (const m of allHourMatches) {
        const val = parseFloat(m[1]) * 60;
        if (val > maxTotalMinutes && val <= 720) { // Reasonable cap (<= 12h)
          maxTotalMinutes = val;
        }
      }

      for (const m of allMinMatches) {
        const val = parseFloat(m[1]);
        if (val > maxTotalMinutes && val <= 720) {
          maxTotalMinutes = val;
        }
      }

      // If no explicit duration found, default to 3 hours (180 mins)
      if (maxTotalMinutes === 0) {
        maxTotalMinutes = 180;
      }

      // Check general percentage
      const generalPercentMatch = text.match(/(\d+)%/);
      if (generalPercentMatch) {
        percent = parseFloat(generalPercentMatch[1]);
      }
    }

    percent = Math.min(100, Math.max(0, percent));

    // 3. Exact Remaining Time Calculation (+ 5 min buffer)
    const remainingMinutes = Math.max(1, Math.ceil(maxTotalMinutes * (1 - (percent / 100))));
    const finalWaitMinutes = remainingMinutes + EXTRA_BUFFER_MINUTES;

    return {
      totalMinutes: maxTotalMinutes,
      percent: percent,
      finalWaitMinutes: finalWaitMinutes
    };
  }

  function formatTimeRemaining(ms) {
    if (ms <= 0) return '0m 0s';
    const totalSecs = Math.floor(ms / 1000);
    const hours = Math.floor(totalSecs / 3600);
    const mins = Math.floor((totalSecs % 3600) / 60);
    const secs = totalSecs % 60;
    if (hours > 0) return `${hours}h ${mins}m ${secs}s`;
    return `${mins}m ${secs}s`;
  }

  function formatClockTime(timestamp) {
    const d = new Date(timestamp);
    return d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit' });
  }

  // Find the specific DOM text for the target game
  function getGameSectionText(game) {
    const allCards = Array.from(document.querySelectorAll('[data-test-selector="DropsCampaignInProgressDescription"], [class*="DropsCampaignCard"], [class*="inventory-campaign-card"], div[class*="ScTower"], article, div'));
    for (const card of allCards) {
      const text = card.innerText || '';
      if (game.aliases.some(a => text.toLowerCase().includes(a))) {
        return text;
      }
    }
    return document.body ? document.body.innerText : '';
  }

  // ============================================================
  // ULTRA-ECO CSS INJECTION
  // ============================================================
  function injectEcoStyles() {
    if (document.getElementById('twitch-eco-styles')) return;
    const style = document.createElement('style');
    style.id = 'twitch-eco-styles';
    style.textContent = `
      .chat-room__viewer-status,
      .chat-line__status,
      [data-test-selector="community-points-summary"],
      .stream-chat-header,
      .reward-center,
      .animated-emote__img {
        display: none !important;
      }
      .video-player video {
        image-rendering: pixelated !important;
        will-change: auto !important;
      }
    `;
    document.head.appendChild(style);
  }

  // ============================================================
  // MINI-STREAM OVERLAY PLAYER (Embedded directly in Inventory)
  // ============================================================
  function createMiniStreamOverlay(channelName) {
    if (!channelName) return;
    let container = document.getElementById('twitch-mini-stream-overlay');

    if (!container) {
      container = document.createElement('div');
      container.id = 'twitch-mini-stream-overlay';
      container.innerHTML = `
        <div style="
          position: fixed;
          bottom: 24px;
          left: 24px;
          z-index: 999998;
          width: 320px;
          height: 195px;
          background: rgba(15, 14, 23, 0.95);
          border: 1px solid rgba(145, 70, 255, 0.5);
          border-radius: 14px;
          box-shadow: 0 12px 35px rgba(0, 0, 0, 0.85), 0 0 15px rgba(145, 70, 255, 0.3);
          overflow: hidden;
          display: flex;
          flex-direction: column;
          font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
          transition: all 0.3s ease;
        ">
          <div style="
            background: rgba(25, 20, 40, 0.95);
            padding: 6px 12px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            border-bottom: 1px solid rgba(145, 70, 255, 0.3);
          ">
            <div style="display: flex; align-items: center; gap: 6px; font-size: 11px; font-weight: 600; color: #a970ff;">
              <span>🔴</span>
              <span id="mini-stream-title">Live: ${channelName}</span>
              <span style="font-size: 10px; color: #00e676; margin-left: 4px;">[160p Muted]</span>
            </div>
            <button id="mini-stream-toggle" style="
              background: none;
              border: none;
              color: #aaa;
              font-size: 12px;
              cursor: pointer;
              padding: 0 4px;
            ">_</button>
          </div>
          <div id="mini-stream-iframe-wrapper" style="flex: 1; width: 100%; height: 100%; background: #000;">
            <iframe
              id="twitch-embed-player"
              src="https://player.twitch.tv/?channel=${channelName}&parent=www.twitch.tv&muted=true"
              style="width: 100%; height: 100%; border: none;"
              allowfullscreen="false">
            </iframe>
          </div>
        </div>
      `;
      document.body.appendChild(container);

      // Minimize / Expand toggle
      let minimized = false;
      document.getElementById('mini-stream-toggle').addEventListener('click', () => {
        minimized = !minimized;
        const wrapper = document.getElementById('mini-stream-iframe-wrapper');
        const box = container.firstElementChild;
        if (minimized) {
          wrapper.style.display = 'none';
          box.style.height = '34px';
        } else {
          wrapper.style.display = 'block';
          box.style.height = '195px';
        }
      });
    } else {
      const iframe = document.getElementById('twitch-embed-player');
      const title = document.getElementById('mini-stream-title');
      if (iframe && !iframe.src.includes(`channel=${channelName}`)) {
        iframe.src = `https://player.twitch.tv/?channel=${channelName}&parent=www.twitch.tv&muted=true`;
      }
      if (title) title.innerText = `Live: ${channelName}`;
    }
  }

  // Floating HUD UI (Bottom-Right)
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
        min-width: 330px;
        max-width: 410px;
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
          🌿 Ultra-Eco: 160p Overlay • Smart Timer
        </div>
        <div id="tdrops-status" style="font-size: 13px; color: #dedede; line-height: 1.4; margin-bottom: 12px;">
          Initializing auto-claimer...
        </div>
        <div style="display: flex; gap: 8px;">
          <button id="tdrops-btn-reloadnow" style="
            flex: 1;
            padding: 8px 12px;
            background: linear-gradient(135deg, #9146ff, #772ce8);
            border: none;
            border-radius: 8px;
            color: #fff;
            font-size: 12px;
            font-weight: 600;
            cursor: pointer;
          ">🔄 Reload & Check Now</button>
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

    document.getElementById('tdrops-btn-reloadnow').addEventListener('click', () => {
      updateHUDStatus('🔄 Reloading page to claim available drops...');
      window.location.reload();
    });

    document.getElementById('tdrops-btn-stop').addEventListener('click', () => {
      clearState();
      const miniOverlay = document.getElementById('twitch-mini-stream-overlay');
      if (miniOverlay) miniOverlay.remove();
      updateHUDStatus('⏹ Auto-claimer stopped.', false);
    });
  }

  function updateHUDStatus(text, showSpinner = true) {
    const statusEl = document.getElementById('tdrops-status');
    const spinnerEl = document.getElementById('tdrops-spinner');
    if (statusEl) statusEl.innerHTML = text;
    if (spinnerEl) spinnerEl.style.display = showSpinner ? 'inline-block' : 'none';
  }

  // Auto-click claim buttons
  function autoClaimButtons() {
    const claimButtons = Array.from(document.querySelectorAll('button')).filter(btn => {
      const text = (btn.innerText || '').trim().toUpperCase();
      const testId = btn.getAttribute('data-test-selector') || '';
      return (text === 'CLAIM NOW' || text === 'CLAIM' || testId.includes('claim-button')) && !btn.disabled;
    });

    for (const btn of claimButtons) {
      btn.click();
      console.log('[Twitch Drops] Clicked Drop Claim button!');
      updateHUDStatus('🎁 <b>Claimed a Drop reward!</b>');
    }
  }

  // 1. CAMPAIGNS HUB: Find active target game
  async function handleCampaignsPage() {
    updateHUDStatus('🔍 Scanning active campaigns for <b>DST</b> & <b>DBD</b>...');
    await sleep(4500);

    const pageText = document.body ? document.body.innerText.toLowerCase() : '';

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

    updateHUDStatus(`🎯 Found <b>${targetGame.name}</b> campaign! Finding non-Russian stream...`);
    const state = {
      active: true,
      currentGame: targetGame,
      currentChannel: null,
      targetEndTime: null
    };
    setState(state);

    await sleep(2000);
    window.location.href = `https://www.twitch.tv/directory/category/${targetGame.slug}?filter=drops`;
  }

  // 2. DIRECTORY: Pick non-Russian channel and redirect straight to Inventory
  async function handleDirectoryPage(state) {
    const game = state.currentGame || TARGET_GAMES[0];
    updateHUDStatus(`🔎 Selecting <b>${game.name}</b> stream (excluding Russian)...`);
    await sleep(4500);

    const streamCards = Array.from(document.querySelectorAll('[data-target="directory-game__card"], [data-target="directory-container"] [data-a-target^="preview-card-image-link"], div[class*="ScTower"] article, article'));
    let chosenChannel = null;

    for (const card of streamCards) {
      const text = card.innerText || '';
      const link = card.querySelector('a[data-a-target="preview-card-image-link"], a[data-a-target="preview-card-channel-link"], a[href^="/"]');
      if (!link) continue;

      const href = link.getAttribute('href');
      if (!href || href.startsWith('/directory') || href.includes('/videos')) continue;

      if (RU_REGEX.test(text) || RU_REGEX.test(href)) {
        continue;
      }

      chosenChannel = href.replace(/\//g, '');
      break;
    }

    if (!chosenChannel) {
      const anyLinks = Array.from(document.querySelectorAll('a[data-a-target="preview-card-channel-link"]'));
      for (const a of anyLinks) {
        const href = a.getAttribute('href');
        if (href && !RU_REGEX.test(href) && !RU_REGEX.test(a.innerText)) {
          chosenChannel = href.replace(/\//g, '');
          break;
        }
      }
    }

    if (!chosenChannel) {
      updateHUDStatus('⚠️ No active non-Russian streams found. Checking inventory...');
      await sleep(3000);
      window.location.href = 'https://www.twitch.tv/drops/inventory';
      return;
    }

    updateHUDStatus(`📺 Selected stream: <b>${chosenChannel}</b>. Attaching overlay to Inventory...`);
    state.currentChannel = chosenChannel;
    setState(state);

    await sleep(1500);
    window.location.href = 'https://www.twitch.tv/drops/inventory';
  }

  // 3. INVENTORY PAGE (Main Hub with Mini-Stream Overlay & Highest-Time Calculator)
  async function handleInventoryPage(state) {
    updateHUDStatus('📦 Loading Drops Inventory & analyzing drop progress...');
    await sleep(4000);

    // Auto-claim any finished drops on arrival
    autoClaimButtons();
    await sleep(2000);

    // If no channel is attached yet, find one first from campaigns
    if (!state.currentChannel) {
      updateHUDStatus('🔍 No stream attached. Finding active stream...');
      await sleep(2000);
      window.location.href = 'https://www.twitch.tv/drops/campaigns';
      return;
    }

    // Attach Mini Stream Player Overlay in bottom-left
    createMiniStreamOverlay(state.currentChannel);

    const game = state.currentGame || TARGET_GAMES[0];
    const gameSectionText = getGameSectionText(game);

    // Parse timing details from the specific game section (picks HIGHEST duration)
    const timing = parseWatchTimeAndProgress(gameSectionText);

    // Calculate fresh target end time based on the exact parsed calculation
    state.totalMinutes = timing.totalMinutes;
    state.progressPercent = timing.percent;
    state.calculatedWaitMinutes = timing.finalWaitMinutes;
    state.targetEndTime = Date.now() + (timing.finalWaitMinutes * 60 * 1000);
    setState(state);

    console.log(`[Twitch Drops] Calculation: ${timing.percent}% of ${timing.totalMinutes}m -> Remaining: ${timing.finalWaitMinutes}m (with +5m buffer)`);

    // Run the watchdog on inventory page
    runInventoryWatchdog(state);
  }

  // Watchdog loop on Inventory Page (Updates countdown & reloads when timer expires)
  function runInventoryWatchdog(state) {
    const gameName = state.currentGame ? state.currentGame.name : 'Target Game';
    const channelName = state.currentChannel || 'Live Stream';
    const totalHoursStr = (state.totalMinutes >= 60) ? `${state.totalMinutes / 60}h` : `${state.totalMinutes}m`;

    setInterval(() => {
      autoClaimButtons();

      const now = Date.now();
      const remainingMs = Math.max(0, state.targetEndTime - now);
      const clockTarget = formatClockTime(state.targetEndTime);

      // When calculated timer completes -> reload inventory to claim & re-evaluate
      if (remainingMs <= 0) {
        updateHUDStatus('⏰ <b>Calculated watch time complete!</b> Reloading inventory to claim reward...');
        setTimeout(() => {
          window.location.reload();
        }, 2000);
        return;
      }

      updateHUDStatus(`
        <div>🎮 <b>${gameName}</b> (📺 ${channelName})</div>
        <div style="font-size: 12px; color: #cfd8dc; margin-top: 2px;">📊 Progress: <b>${state.progressPercent}% of ${totalHoursStr}</b> (${state.totalMinutes} mins)</div>
        <div style="margin-top: 4px; color: #a970ff; font-weight: 600;">⏳ ${formatTimeRemaining(remainingMs)} remaining (+5m buffer)</div>
        <div style="font-size: 11px; color: #aaa; margin-top: 2px;">⏰ Auto-reload & claim at: <b>${clockTarget}</b></div>
      `);
    }, CHECK_INTERVAL);
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
    } else {
      const channel = path.replace(/\//g, '');
      if (channel && !path.startsWith('/directory') && !path.startsWith('/downloads')) {
        state.currentChannel = channel;
        setState(state);
        window.location.href = 'https://www.twitch.tv/drops/inventory';
      } else {
        updateHUDStatus('Ready. Click <b>"Check Drops"</b> to start.', false);
      }
    }
  }

  window.addEventListener('load', () => {
    setTimeout(route, 2000);
  });
})();
