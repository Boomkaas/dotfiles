// ==UserScript==
// @name         Twitch Drops Auto-Claimer (DST)
// @namespace    https://github.com/Boomkaas/dotfiles
// @version      3.1.0
// @description  Automated Twitch Drops claimer: Checks and claims drops exclusively for Don't Starve Together (DST), auto-clicks Live Channels, picks non-Russian streams, sets 160p & mutes, opens drops panel/timer, auto-claims rewards, advances drop tiers, switches offline streamers, and auto-closes when all DST drops are finished.
// @author       Peng
// @match        https://www.twitch.tv/*
// @grant        GM_closeTab
// @grant        window.close
// @run-at       document-idle
// ==/UserScript==

(function () {
  'use strict';

  // Only run in top window
  if (window.self !== window.top) return;

  // ============================================================
  // ULTRA-ECO PRE-SEED (160p, Muted, Low-Latency Off)
  // ============================================================
  try {
    localStorage.setItem('video-quality', JSON.stringify({ default: '160p30' }));
    localStorage.setItem('video-muted', JSON.stringify({ default: true }));
    localStorage.setItem('volume', '0');
    localStorage.setItem('lowLatency', 'false');
  } catch (e) {}

  // ============================================================
  // CONSTANTS & TARGET GAMES CONFIGURATION
  // ============================================================
  const STORAGE_KEY = 'twitch_drops_farmer_state_v3';
  const FAILED_CHANNELS_KEY = 'twitch_failed_channels_v3';
  const GQL_CLIENT_ID = 'kimne78kx3ncx6brgo4mv6wki5h1ko';
  const CHECK_INTERVAL_MS = 1000;
  const HEALTH_CHECK_INTERVAL_MS = 10000;
  const PROGRESS_REFRESH_INTERVAL_MS = 15000;
  const EXTRA_BUFFER_MINUTES = 1;

  const TARGET_GAMES = [
    {
      name: "Don't Starve Together",
      slug: "dont-starve-together",
      aliases: ["don't starve together", "dont starve together", "dst"],
      signatureKeywords: ["bugburst", "portrait", "icon", "klei", "waterballoon", "spiffy", "distinguished", "elegant"]
    }
  ];

  const RU_REGEX = /(russian|русский|рус|\[ru\]|\(ru\)|ru\/|\/ru|\bru\b|\brussians\b)/i;

  // ============================================================
  // GLOBAL CANCELLATION & TIMER REGISTRY
  // ============================================================
  let isStopped = false;
  let isNavigating = false;
  let isSwitchingStreamer = false;
  let lastHealthCheckTime = 0;
  let lastProgressRefreshTime = 0;

  const activeTimeouts = new Set();
  const activeIntervals = new Set();

  function registerTimeout(fn, ms) {
    const id = setTimeout(() => {
      activeTimeouts.delete(id);
      if (!isStopped) fn();
    }, ms);
    activeTimeouts.add(id);
    return id;
  }

  function registerInterval(fn, ms) {
    const id = setInterval(() => {
      if (isStopped) {
        clearInterval(id);
        activeIntervals.delete(id);
        return;
      }
      fn();
    }, ms);
    activeIntervals.add(id);
    return id;
  }

  function clearAllTimers() {
    for (const id of activeTimeouts) clearTimeout(id);
    for (const id of activeIntervals) clearInterval(id);
    activeTimeouts.clear();
    activeIntervals.clear();
  }

  // 100ms-chunked cancellable sleep
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

  // ============================================================
  // PERSISTENT STATE MANAGEMENT
  // ============================================================
  function getState() {
    try {
      return JSON.parse(sessionStorage.getItem(STORAGE_KEY)) || {
        active: true,
        stopped: false,
        gameIndex: 0,
        currentGame: TARGET_GAMES[0],
        currentChannel: null,
        currentDropName: 'Drop Reward',
        progressPercent: 0,
        currentMinutes: 0,
        totalMinutes: 180,
        calculatedWaitMinutes: 180,
        targetEndTime: null,
        status: 'initializing'
      };
    } catch {
      return {
        active: true,
        stopped: false,
        gameIndex: 0,
        currentGame: TARGET_GAMES[0],
        currentChannel: null,
        currentDropName: 'Drop Reward',
        progressPercent: 0,
        currentMinutes: 0,
        totalMinutes: 180,
        calculatedWaitMinutes: 180,
        targetEndTime: null,
        status: 'initializing'
      };
    }
  }

  function setState(state) {
    try {
      sessionStorage.setItem(STORAGE_KEY, JSON.stringify(state));
    } catch (e) {}
  }

  function getFailedChannels() {
    try {
      return JSON.parse(sessionStorage.getItem(FAILED_CHANNELS_KEY)) || [];
    } catch {
      return [];
    }
  }

  function markChannelFailed(channelName) {
    if (!channelName) return;
    try {
      const list = getFailedChannels();
      const lower = channelName.toLowerCase();
      if (!list.includes(lower)) {
        list.push(lower);
        sessionStorage.setItem(FAILED_CHANNELS_KEY, JSON.stringify(list));
      }
    } catch (e) {}
  }

  // ============================================================
  // FLOATING HUD USER INTERFACE
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
      .animated-emote__img,
      [data-test-selector="leaderboard"],
      .channel-leaderboard {
        display: none !important;
      }
      .video-player video {
        image-rendering: pixelated !important;
        will-change: auto !important;
      }
    `;
    document.head.appendChild(style);
  }

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
        min-width: 340px;
        max-width: 440px;
        transition: all 0.3s ease;
      ">
        <div style="display: flex; align-items: center; justify-content: space-between; margin-bottom: 8px;">
          <div style="display: flex; align-items: center; gap: 8px;">
            <span style="font-size: 20px;">🟣</span>
            <span style="font-weight: 700; font-size: 14px; letter-spacing: 0.5px; color: #a970ff;">TWITCH DROPS CLAIMER</span>
          </div>
          <div style="display: flex; align-items: center; gap: 8px;">
            <span id="tdrops-spinner" style="font-size: 14px; animation: tdrops-spin 2s linear infinite;">⏳</span>
            <button id="tdrops-hud-min-toggle" title="Minimize/Expand" style="
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
        <div id="tdrops-hud-body">
          <div style="display: flex; gap: 6px; margin-bottom: 10px;">
            <span id="tdrops-badge-game" style="display: inline-block; padding: 2px 8px; border-radius: 6px; background: rgba(0, 200, 83, 0.15); border: 1px solid rgba(0, 200, 83, 0.3); color: #00e676; font-size: 11px; font-weight: 600;">
              🌿 Target: DST
            </span>
            <span style="display: inline-block; padding: 2px 8px; border-radius: 6px; background: rgba(145, 70, 255, 0.15); border: 1px solid rgba(145, 70, 255, 0.3); color: #c499ff; font-size: 11px; font-weight: 600;">
              ⚡ Auto Switch & Claim
            </span>
          </div>
          <div id="tdrops-status" style="font-size: 13px; color: #dedede; line-height: 1.4; margin-bottom: 12px;">
            Initializing auto-claimer...
          </div>
          <div style="display: flex; gap: 8px; flex-wrap: wrap;">
            <button id="tdrops-btn-start" style="
              flex: 1;
              min-width: 120px;
              padding: 8px 12px;
              background: linear-gradient(135deg, #00c853, #009624);
              border: none;
              border-radius: 8px;
              color: #fff;
              font-size: 12px;
              font-weight: 600;
              cursor: pointer;
              transition: all 0.2s ease;
            ">▶ Start / Resume</button>
            <button id="tdrops-btn-checknow" style="
              padding: 8px 12px;
              background: linear-gradient(135deg, #9146ff, #772ce8);
              border: none;
              border-radius: 8px;
              color: #fff;
              font-size: 12px;
              font-weight: 600;
              cursor: pointer;
              transition: all 0.2s ease;
            ">🔄 Check Now</button>
            <button id="tdrops-btn-stop" style="
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
        @keyframes tdrops-spin { 100% { transform: rotate(360deg); } }
        #tdrops-btn-start:hover { filter: brightness(1.15); transform: translateY(-1px); }
        #tdrops-btn-checknow:hover { filter: brightness(1.15); transform: translateY(-1px); }
        #tdrops-btn-stop:hover { background: rgba(244, 67, 54, 0.35); color: #fff; }
      </style>
    `;
    document.body.appendChild(hud);

    let isMinimized = false;
    document.getElementById('tdrops-hud-min-toggle').addEventListener('click', () => {
      isMinimized = !isMinimized;
      const body = document.getElementById('tdrops-hud-body');
      const btn = document.getElementById('tdrops-hud-min-toggle');
      if (isMinimized) {
        body.style.display = 'none';
        btn.innerText = '+';
      } else {
        body.style.display = 'block';
        btn.innerText = '_';
      }
    });

    document.getElementById('tdrops-btn-start').addEventListener('click', () => {
      startClaimProcess(true);
    });

    document.getElementById('tdrops-btn-checknow').addEventListener('click', () => {
      updateHUDStatus('🔄 Manually re-checking drops & claiming available rewards...');
      autoClaimAllButtons();
      window.location.reload();
    });

    document.getElementById('tdrops-btn-stop').addEventListener('click', () => {
      stopClaimProcess('User clicked Stop');
    });
  }

  function updateHUDStatus(text, showSpinner = true) {
    const statusEl = document.getElementById('tdrops-status');
    const spinnerEl = document.getElementById('tdrops-spinner');
    if (statusEl) statusEl.innerHTML = text;
    if (spinnerEl) spinnerEl.style.display = showSpinner ? 'inline-block' : 'none';
  }

  function updateHUDButtons(running = true) {
    const startBtn = document.getElementById('tdrops-btn-start');
    const stopBtn = document.getElementById('tdrops-btn-stop');
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
      startBtn.innerHTML = '▶ Resume / Start';
      stopBtn.style.opacity = '0.5';
      stopBtn.style.cursor = 'default';
      stopBtn.style.background = 'rgba(255, 255, 255, 0.1)';
    }
  }

  function stopClaimProcess(reason = '') {
    isStopped = true;
    clearAllTimers();

    const state = getState();
    state.active = false;
    state.stopped = true;
    state.status = 'stopped';
    setState(state);

    console.log('[Twitch Drops] Farmer stopped.', reason);
    updateHUDStatus('⏹ <b>Auto-claimer paused.</b> All timers, stream watchers, and claims halted.', false);
    updateHUDButtons(false);
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

  // ============================================================
  // TWITCH GQL API HELPERS
  // ============================================================
  async function fetchLiveStreamsGQL(gameName) {
    try {
      const resp = await fetch('https://gql.twitch.tv/gql', {
        method: 'POST',
        headers: {
          'Client-Id': GQL_CLIENT_ID,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          query: `query {
            game(name: "${gameName}") {
              streams(first: 30) {
                edges {
                  node {
                    broadcaster {
                      login
                      displayName
                    }
                    type
                    title
                    game {
                      name
                    }
                  }
                }
              }
            }
          }`
        })
      });
      const json = await resp.json();
      const edges = json?.data?.game?.streams?.edges || [];
      return edges.map(e => ({
        login: e.node.broadcaster.login,
        displayName: e.node.broadcaster.displayName,
        type: e.node.type,
        title: e.node.title || '',
        game: e.node.game?.name || ''
      }));
    } catch (e) {
      return [];
    }
  }

  async function checkChannelStatusGQL(channelName) {
    if (!channelName) return { isLive: false, reason: 'no_channel' };
    try {
      const resp = await fetch('https://gql.twitch.tv/gql', {
        method: 'POST',
        headers: {
          'Client-Id': GQL_CLIENT_ID,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          query: `query {
            user(login: "${channelName.toLowerCase()}") {
              stream {
                id
                type
                title
                game {
                  name
                }
              }
            }
          }`
        })
      });
      const json = await resp.json();
      const stream = json?.data?.user?.stream;
      if (!stream || stream.type !== 'live') {
        return { isLive: false, reason: 'offline' };
      }
      return {
        isLive: true,
        game: stream.game?.name || '',
        title: stream.title || ''
      };
    } catch (e) {
      return { isLive: true, error: e };
    }
  }

  // ============================================================
  // AUTO-CLAIM ENGINE
  // ============================================================
  // ============================================================
  // AUTO-CLAIM ENGINE
  // ============================================================
  function autoClaimAllButtons() {
    if (isStopped) return 0;
    let claimedCount = 0;

    // Only click claim buttons within drops cards/panels, ignoring top navigation & profile menus
    const claimButtons = Array.from(document.querySelectorAll('button, a')).filter(btn => {
      if (btn.closest('header, nav, [data-a-target="top-nav-container"], .top-nav, [data-a-target="user-menu"], #user-menu')) {
        return false;
      }
      const text = (btn.innerText || btn.textContent || '').trim().toUpperCase();
      const testId = (btn.getAttribute('data-test-selector') || '').toLowerCase();
      const aria = (btn.getAttribute('aria-label') || '').toUpperCase();
      const isClaim = text === 'CLAIM NOW' || text === 'CLAIM' || text === 'ПОЛУЧИТЬ' ||
                      testId.includes('claim-button') ||
                      aria === 'CLAIM REWARD' || aria === 'CLAIM NOW' || aria === 'CLAIM';
      return isClaim && !btn.disabled;
    });

    for (const btn of claimButtons) {
      btn.click();
      claimedCount++;
      console.log('[Twitch Drops] Clicked Drop Claim button!');
      updateHUDStatus('🎁 <b>Claimed a Drop reward!</b>');
    }

    return claimedCount;
  }

  // ============================================================
  // STREAM PAGE OPTIMIZATIONS (160p Quality, Mute & Panels)
  // ============================================================
  async function openDropsPanel() {
    // 1. Ensure right sidebar is expanded (only click right column toggle)
    const expandBtn = document.querySelector('button[data-a-target="right-column__toggle-collapse-btn"]');
    if (expandBtn) {
      const aria = (expandBtn.getAttribute('aria-label') || '').toLowerCase();
      if (aria.includes('expand') || aria.includes('развернуть')) {
        expandBtn.click();
        try { await cancellableSleep(600); } catch (e) {}
      }
    }

    // 2. Only look INSIDE the right sidebar / chat column for Drops tab / banner
    const rightCol = document.querySelector('div[data-a-target="right-column"], div.stream-chat, #live-channel-stream-information');
    if (rightCol) {
      const dropTab = rightCol.querySelector('button[data-a-target="right-column-tab-drops"], button[aria-label*="Drops"], button[aria-label*="Дроп"]');
      if (dropTab) {
        dropTab.click();
        return true;
      }

      // Check "Available Drops" / "Drops & More" banner above chat inside rightCol
      const banners = Array.from(rightCol.querySelectorAll('div[role="button"], button'));
      for (const el of banners) {
        const text = (el.innerText || el.textContent || '').trim();
        if (/Available Drops|Drops & More|Дропы и награды/i.test(text)) {
          el.click();
          return true;
        }
      }
    }

    return false;
  }

  async function applyStreamPageOptimizations() {
    if (isStopped) return;

    // 1. Mute all HTML5 video elements directly
    document.querySelectorAll('video').forEach(video => {
      video.muted = true;
      video.volume = 0;
    });

    // 2. Click player mute button if unmuted
    const muteBtn = document.querySelector('button[data-a-target="player-mute-unmute-button"]');
    if (muteBtn) {
      const aria = (muteBtn.getAttribute('aria-label') || '').toLowerCase();
      if (aria.includes('mute') && !aria.includes('unmute')) {
        muteBtn.click();
      }
    }

    // 3. Open right panel and Drops & More tab (NEVER click top nav, user avatar or settings)
    await openDropsPanel();
  }

  // ============================================================
  // CAMPAIGN & INVENTORY CLAIM STATUS CHECKER
  // ============================================================
  function checkDSTCampaignStatus() {
    const pageText = (document.body ? document.body.innerText : '').toLowerCase();
    const dst = TARGET_GAMES[0];
    const hasDST = dst.aliases.some(a => pageText.includes(a)) ||
                   dst.signatureKeywords.some(k => pageText.includes(k));

    if (!hasDST) {
      return { found: false, allClaimed: false };
    }

    // Try finding the exact DST campaign section in DOM
    const allHeadings = Array.from(document.querySelectorAll('h3, h4, h5, h6, p, a, div[data-test-selector*="campaign"], div[class*="campaign"], div[class*="Campaign"]'));
    let dstCard = null;
    for (const el of allHeadings) {
      const t = (el.textContent || '').trim().toLowerCase();
      if (t === "don't starve together" || t === "dont starve together" || t === "dst") {
        let parent = el;
        for (let i = 0; i < 8 && parent; i++) {
          if (parent.querySelectorAll('button, a, img').length >= 2 && parent.innerText.length > 60) {
            dstCard = parent;
            break;
          }
          if (parent.parentElement) parent = parent.parentElement;
          else break;
        }
        if (dstCard) break;
      }
    }

    const cardText = (dstCard ? dstCard.innerText : pageText).toLowerCase();

    // Check if DST section explicitly indicates all rewards are earned
    const allEarnedNotice = /all (?:drop )?rewards (?:have been )?earned|все награды получены|all drops claimed|all rewards claimed/i.test(cardText);

    // Look for rewards and claimed statuses within DST section
    const watchMatches = cardText.match(/watch\s+(?:for\s+)?(?:\d+\s*(?:hours?|hrs?|h|minutes?|mins?|m|ч|мин))/gi) || [];
    const claimedMatches = cardText.match(/\b(?:claimed|получено|уже получено)\b/gi) || [];

    const progressMatches = cardText.match(/(\d+(?:\.\d+)?)%\s*(?:of|\/|из)\s*(\d+)/gi) || [];
    const hasActiveProgress = progressMatches.some(m => {
      const val = parseFloat(m);
      return val > 0 && val < 100;
    });

    const isAllClaimed = allEarnedNotice || (claimedMatches.length > 0 && claimedMatches.length >= watchMatches.length && !hasActiveProgress);

    return {
      found: true,
      allClaimed: isAllClaimed,
      claimedCount: claimedMatches.length,
      watchCount: watchMatches.length
    };
  }

  // ============================================================
  // PROGRESS EXTRACTION ENGINE (On-Stream Drops Panel + Page Text)
  // ============================================================
  function parseCurrentDropProgress(game) {
    const pageText = document.body ? document.body.innerText : '';
    if (!pageText) return null;

    // Check if all drops are already completed/claimed on-stream
    if (/all (?:drop )?rewards (?:have been )?earned|все награды получены|all drops claimed|all rewards claimed/i.test(pageText)) {
      return {
        allClaimed: true,
        percent: 100,
        totalMinutes: 180,
        currentMinutes: 180,
        remainingMinutes: 0,
        finalWaitMinutes: 0
      };
    }

    // Priority 1: Direct "Watch X to earn" on-stream Drops & More panel
    // e.g. "Watch 48m to earn", "Watch 1h 20m to earn", "Watch 2h to earn"
    const watchToEarnMatch = pageText.match(/Watch\s+(?:(\d+)\s*h(?:ours?|rs?)?)?\s*(?:(\d+)\s*m(?:inutes?|ins?)?)?\s+to\s+earn/i);
    if (watchToEarnMatch && (watchToEarnMatch[1] || watchToEarnMatch[2])) {
      const hours = watchToEarnMatch[1] ? parseInt(watchToEarnMatch[1], 10) : 0;
      const mins = watchToEarnMatch[2] ? parseInt(watchToEarnMatch[2], 10) : 0;
      const remainingMins = (hours * 60) + mins;
      if (remainingMins > 0) {
        const totalMins = (remainingMins > 180) ? Math.ceil(remainingMins / 60) * 60 : 180;
        const currentMins = Math.max(0, totalMins - remainingMins);
        const percent = Math.round((currentMins / totalMins) * 100);
        return {
          allClaimed: false,
          percent: percent,
          totalMinutes: totalMins,
          currentMinutes: currentMins,
          remainingMinutes: remainingMins,
          finalWaitMinutes: remainingMins + EXTRA_BUFFER_MINUTES
        };
      }
    }

    // Priority 2: Slicing strategy by "End Date:" or "About This Drop"
    const sections = pageText.split(/(?:End Date:|Дата окончания:|Fecha de finalización:|Date de fin:|About This Drop)/i);

    for (const sec of sections) {
      const lower = sec.toLowerCase();
      const isTargetGame = game.aliases.some(a => lower.includes(a)) ||
                           game.signatureKeywords.some(k => lower.includes(k));

      if (isTargetGame) {
        const match = sec.match(/(\d+(?:\.\d+)?)%\s*(?:of|\/|из|de|von)?\s*(\d+(?:\.\d+)?)\s*(hours?|hrs?|h|minutes?|mins?|m|ч|мин)?/i);
        if (match) {
          const percent = parseFloat(match[1]);
          const dur = match[2] ? parseFloat(match[2]) : 3;
          const unit = (match[3] || 'h').toLowerCase();
          let totalMins = (unit.startsWith('h') || unit.startsWith('ч') || unit === 'h') ? (dur * 60) : dur;
          if (totalMins === 0 || totalMins > 720) totalMins = 180;

          if (percent >= 100) {
            return {
              allClaimed: true,
              percent: 100,
              totalMinutes: totalMins,
              currentMinutes: totalMins,
              remainingMinutes: 0,
              finalWaitMinutes: 0
            };
          }

          const rem = Math.max(1, Math.ceil(totalMins * (1 - (percent / 100))));
          return {
            allClaimed: false,
            percent: percent,
            totalMinutes: totalMins,
            currentMinutes: Math.round(totalMins * (percent / 100)),
            remainingMinutes: rem,
            finalWaitMinutes: rem + EXTRA_BUFFER_MINUTES
          };
        }
      }
    }

    // Priority 3: Direct Substring Search around signature keywords
    for (const keyword of game.signatureKeywords) {
      const idx = pageText.toLowerCase().indexOf(keyword);
      if (idx !== -1) {
        const sub = pageText.slice(Math.max(0, idx - 200), idx + 800);
        const match = sub.match(/(\d+(?:\.\d+)?)%\s*(?:of|\/|из|de|von)?\s*(\d+(?:\.\d+)?)\s*(hours?|hrs?|h|minutes?|mins?|m|ч|мин)?/i);
        if (match) {
          const percent = parseFloat(match[1]);
          const dur = match[2] ? parseFloat(match[2]) : 3;
          const unit = (match[3] || 'h').toLowerCase();
          let totalMins = (unit.startsWith('h') || unit === 'h') ? (dur * 60) : dur;
          if (totalMins === 0 || totalMins > 720) totalMins = 180;

          if (percent >= 100) {
            return {
              allClaimed: true,
              percent: 100,
              totalMinutes: totalMins,
              currentMinutes: totalMins,
              remainingMinutes: 0,
              finalWaitMinutes: 0
            };
          }

          const rem = Math.max(1, Math.ceil(totalMins * (1 - (percent / 100))));
          return {
            allClaimed: false,
            percent: percent,
            totalMinutes: totalMins,
            currentMinutes: Math.round(totalMins * (percent / 100)),
            remainingMinutes: rem,
            finalWaitMinutes: rem + EXTRA_BUFFER_MINUTES
          };
        }
      }
    }

    return null;
  }

  // Helper: Find "Live Channels" tab button on directory page
  function findLiveChannelsTab() {
    const direct = document.querySelector('a[data-a-target="category-live-channels-tab"], [data-a-target*="live-channels"]');
    if (direct) return direct;

    const candidates = Array.from(document.querySelectorAll('a[role="tab"], button[role="tab"], [role="tablist"] a, [role="tablist"] button, nav a, div[role="tab"]'));
    return candidates.find(el => {
      const text = (el.innerText || el.getAttribute('aria-label') || '').trim().toLowerCase();
      return text.includes('live channels') || text === 'live' || text.includes('прямые трансляции') || text.includes('прямой эфир');
    });
  }

  // Helper: Extract top non-Russian live channel from directory page
  function findNonRussianChannel() {
    const failed = getFailedChannels();
    const streamCards = Array.from(document.querySelectorAll(
      '[data-target="directory-game__card"], [data-target="directory-container"] [data-a-target^="preview-card-image-link"], div[class*="ScTower"] article, article, [data-a-target="preview-card-image-link"]'
    ));

    for (const card of streamCards) {
      const text = card.innerText || '';
      const link = card.querySelector('a[data-a-target="preview-card-image-link"], a[data-a-target="preview-card-channel-link"], a[href^="/"]') || (card.tagName === 'A' ? card : null);
      if (!link) continue;

      const href = link.getAttribute('href');
      if (!href || href.startsWith('/directory') || href.includes('/videos') || href.includes('/drops') || href.includes('/inventory')) continue;

      if (RU_REGEX.test(text) || RU_REGEX.test(href)) {
        continue;
      }

      const channel = href.replace(/^\/+|\/+$/g, '').split('/')[0].split('?')[0];
      if (channel && !failed.includes(channel.toLowerCase())) {
        return channel;
      }
    }

    const anyLinks = Array.from(document.querySelectorAll('a[data-a-target="preview-card-channel-link"], a[data-a-target="preview-card-image-link"]'));
    for (const a of anyLinks) {
      const href = a.getAttribute('href');
      if (!href || href.startsWith('/directory') || href.includes('/videos') || href.includes('/drops')) continue;
      const text = a.innerText || '';
      if (!RU_REGEX.test(href) && !RU_REGEX.test(text)) {
        const channel = href.replace(/^\/+|\/+$/g, '').split('/')[0].split('?')[0];
        if (channel && !failed.includes(channel.toLowerCase())) {
          return channel;
        }
      }
    }

    return null;
  }

  // ============================================================
  // STEP 1: CAMPAIGNS PAGE (Scan for DST & Check if Claimed)
  // ============================================================
  async function handleCampaignsPage() {
    if (isStopped) return;
    updateHUDStatus('🔍 Scanning active campaigns for <b>Don\'t Starve Together (DST)</b>...');
    updateHUDButtons(true);

    try {
      await cancellableSleep(4000);
    } catch (e) {
      return;
    }

    if (isStopped) return;

    // Auto-claim any ready drops on campaigns page
    autoClaimAllButtons();

    const status = checkDSTCampaignStatus();

    if (!status.found) {
      updateHUDStatus('🏁 <b>No active drop campaigns found for Don\'t Starve Together (DST).</b> Closing tab...');
      try { await cancellableSleep(3000); } catch (e) { return; }
      if (!isStopped) {
        if (typeof GM_closeTab === 'function') GM_closeTab();
        else window.close();
      }
      return;
    }

    if (status.allClaimed) {
      updateHUDStatus('✨ <b>All Don\'t Starve Together drops have already been claimed!</b> Closing tab in 3s...');
      try { await cancellableSleep(3000); } catch (e) { return; }
      if (!isStopped) {
        if (typeof GM_closeTab === 'function') GM_closeTab();
        else window.close();
      }
      return;
    }

    const dst = TARGET_GAMES[0];
    const state = getState();
    state.active = true;
    state.stopped = false;
    state.gameIndex = 0;
    state.currentGame = dst;
    state.currentChannel = null;
    setState(state);

    updateHUDStatus(`🎯 Active DST drops found! Navigating to live streams...`);
    try { await cancellableSleep(1500); } catch (e) { return; }

    if (!isStopped) {
      window.location.href = `https://www.twitch.tv/directory/category/${dst.slug}?filter=drops`;
    }
  }

  // ============================================================
  // STEP 1B: INVENTORY PAGE (Check if DST Claimed & Auto-Close)
  // ============================================================
  async function handleInventoryPage(state) {
    if (isStopped) return;
    updateHUDStatus('🔍 Checking Drops Inventory for <b>Don\'t Starve Together (DST)</b>...');
    updateHUDButtons(true);

    try { await cancellableSleep(3500); } catch (e) { return; }
    if (isStopped) return;

    autoClaimAllButtons();

    const dst = TARGET_GAMES[0];
    const status = checkDSTCampaignStatus();

    if (status.found && status.allClaimed) {
      updateHUDStatus('✨ <b>All Don\'t Starve Together drops are already claimed!</b> Closing tab in 3s...');
      try { await cancellableSleep(3000); } catch (e) { return; }
      if (!isStopped) {
        if (typeof GM_closeTab === 'function') GM_closeTab();
        else window.close();
      }
      return;
    }

    updateHUDStatus('🎯 Unfinished DST drops found. Navigating to live streams...');
    try { await cancellableSleep(1500); } catch (e) { return; }
    if (!isStopped) {
      window.location.href = `https://www.twitch.tv/directory/category/${dst.slug}?filter=drops`;
    }
  }

  // ============================================================
  // STEP 2: DIRECTORY PAGE (Tap "Live Channels" & Pick Stream)
  // ============================================================
  async function handleDirectoryPage(state) {
    if (isStopped) return;
    const game = state.currentGame || TARGET_GAMES[0];
    updateHUDStatus(`🔎 Auto-discovering live <b>${game.name}</b> streams...`);
    updateHUDButtons(true);

    try { await cancellableSleep(2500); } catch (e) { return; }
    if (isStopped) return;

    // 1. Automatically tap "Live Channels" button to fix empty stream list bug
    const liveTab = findLiveChannelsTab();
    if (liveTab) {
      console.log('[Twitch Drops] Auto-tapping "Live Channels" tab button');
      liveTab.click();
      try { await cancellableSleep(3000); } catch (e) { return; }
      if (isStopped) return;
    }

    // 2. Pick top non-Russian live channel
    let chosenChannel = findNonRussianChannel();

    // 3. Fallback: scroll slightly to trigger hydration
    if (!chosenChannel) {
      window.scrollBy({ top: 300, behavior: 'smooth' });
      try { await cancellableSleep(2000); } catch (e) { return; }
      chosenChannel = findNonRussianChannel();
    }

    // 4. Fallback: query Twitch GQL API directly
    if (!chosenChannel) {
      const liveStreams = await fetchLiveStreamsGQL(game.name);
      const failed = getFailedChannels();
      for (const s of liveStreams) {
        if (s.type !== 'live') continue;
        if (RU_REGEX.test(s.title) || RU_REGEX.test(s.login) || RU_REGEX.test(s.displayName)) continue;
        if (failed.includes(s.login.toLowerCase())) continue;
        chosenChannel = s.login;
        break;
      }
    }

    // If still empty, inform user & retry
    if (!chosenChannel) {
      updateHUDStatus(`⚠️ No active streams found for <b>${game.name}</b>. Retrying in 10s...`);
      try { await cancellableSleep(10000); } catch (e) { return; }
      if (!isStopped) window.location.reload();
      return;
    }

    updateHUDStatus(`📺 Selected live stream: <b>${chosenChannel}</b>. Opening channel...`);
    state.currentChannel = chosenChannel;
    setState(state);

    try { await cancellableSleep(1200); } catch (e) { return; }
    if (!isStopped) {
      window.location.href = `https://www.twitch.tv/${chosenChannel}`;
    }
  }

  // ============================================================
  // STEP 3: STREAM PAGE (160p, Mute, Drops Panel, Timer & Claim)
  // ============================================================
  async function handleStreamPage(state) {
    if (isStopped) return;
    const channel = window.location.pathname.replace(/\//g, '');
    state.currentChannel = channel;
    setState(state);

    const game = state.currentGame || TARGET_GAMES[state.gameIndex || 0];
    updateHUDStatus(`🎬 Loaded stream: <b>${channel}</b>. Lowering to 160p & setting up drops...`);
    updateHUDButtons(true);

    try { await cancellableSleep(3500); } catch (e) { return; }
    if (isStopped) return;

    // 1. Lower video quality to lowest and mute
    await applyStreamPageOptimizations();

    // 2. Auto-claim any ready drops on arrival
    autoClaimAllButtons();

    // 3. Extract exact drop progress and remaining time
    let timing = parseCurrentDropProgress(game);

    if (timing && timing.allClaimed) {
      updateHUDStatus('✨ <b>All Don\'t Starve Together drops have already been claimed!</b> Closing tab in 3s...');
      try { await cancellableSleep(3000); } catch (e) { return; }
      if (!isStopped) {
        if (typeof GM_closeTab === 'function') GM_closeTab();
        else window.close();
      }
      return;
    }

    if (!timing) {
      // Default: 3 hours watch time
      timing = {
        percent: 0,
        currentMinutes: 0,
        totalMinutes: 180,
        finalWaitMinutes: 180 + EXTRA_BUFFER_MINUTES
      };
    }

    state.progressPercent = timing.percent;
    state.currentMinutes = timing.currentMinutes;
    state.totalMinutes = timing.totalMinutes;
    state.calculatedWaitMinutes = timing.finalWaitMinutes;
    state.targetEndTime = Date.now() + (timing.finalWaitMinutes * 60 * 1000);
    setState(state);

    console.log(`[Twitch Drops] Watching ${channel} for ${game.name}: ${timing.percent}% of ${timing.totalMinutes}m -> ${timing.finalWaitMinutes}m remaining`);

    // 4. Start active stream watchdog
    runStreamWatchdog(state);
  }

  // ============================================================
  // STEP 4: STREAM WATCHDOG (Health Guard, Live Timer, Auto-Claim)
  // ============================================================
  function runStreamWatchdog(state) {
    if (isStopped) return;

    registerInterval(async () => {
      if (isStopped || isSwitchingStreamer || isNavigating) return;

      const now = Date.now();
      const game = state.currentGame || TARGET_GAMES[state.gameIndex || 0];
      const channel = state.currentChannel || 'Stream';

      // 1. Auto-claim check every cycle
      const claimed = autoClaimAllButtons();
      if (claimed > 0) {
        // Drop was claimed! Check if there is next drop tier or advance
        handleDropClaimed(state);
        return;
      }

      // 2. Automatic stream health check every 10s
      if (now - lastHealthCheckTime > HEALTH_CHECK_INTERVAL_MS) {
        lastHealthCheckTime = now;
        if (state.currentChannel) {
          const health = await checkChannelStatusGQL(state.currentChannel);
          if (!health.isLive) {
            console.warn(`[Twitch Drops] Streamer ${state.currentChannel} is offline. Auto-switching...`);
            markChannelFailed(state.currentChannel);
            autoSwitchStreamer(state);
            return;
          }
        }
      }

      // 3. Periodic progress re-evaluation every 15s
      if (now - lastProgressRefreshTime > PROGRESS_REFRESH_INTERVAL_MS) {
        lastProgressRefreshTime = now;
        const freshTiming = parseCurrentDropProgress(game);
        if (freshTiming && (freshTiming.percent !== state.progressPercent || freshTiming.totalMinutes !== state.totalMinutes)) {
          state.progressPercent = freshTiming.percent;
          state.currentMinutes = freshTiming.currentMinutes;
          state.totalMinutes = freshTiming.totalMinutes;
          state.calculatedWaitMinutes = freshTiming.finalWaitMinutes;
          state.targetEndTime = Date.now() + (freshTiming.finalWaitMinutes * 60 * 1000);
          setState(state);
        }
      }

      const remainingMs = Math.max(0, state.targetEndTime - now);
      const clockTarget = formatClockTime(state.targetEndTime);
      const totalHoursStr = (state.totalMinutes >= 60) ? `${state.totalMinutes / 60}h` : `${state.totalMinutes}m`;
      const watchedMins = state.currentMinutes || Math.round(state.totalMinutes * (state.progressPercent / 100));

      // 4. Timer Completed -> Auto-claim drop & advance
      if (remainingMs <= 0) {
        updateHUDStatus('⏰ <b>Calculated watch time complete!</b> Claiming drop & checking next tier...');
        autoClaimAllButtons();
        try { await cancellableSleep(2000); } catch (e) { return; }
        handleDropClaimed(state);
        return;
      }

      // 5. Update floating HUD
      updateHUDStatus(`
        <div>🎮 <b>${game.name}</b> (📺 ${channel})</div>
        <div style="font-size: 12px; color: #cfd8dc; margin-top: 2px;">📊 Progress: <b>${state.progressPercent}% of ${totalHoursStr}</b> (${watchedMins} / ${state.totalMinutes} mins)</div>
        <div style="margin-top: 4px; color: #a970ff; font-weight: 600;">⏳ ${formatTimeRemaining(remainingMs)} remaining</div>
        <div style="font-size: 11px; color: #aaa; margin-top: 2px;">⏰ Claim target: <b>${clockTarget}</b></div>
      `);
    }, CHECK_INTERVAL_MS);
  }

  // ============================================================
  // DROP CLAIMED & TIER / GAME PROGRESSION
  // ============================================================
  async function handleDropClaimed(state) {
    if (isNavigating || isStopped) return;
    isNavigating = true;

    updateHUDStatus('🎉 <b>Drop completed & claimed!</b> Checking for next reward tier...');
    try { await cancellableSleep(3000); } catch (e) { return; }

    const game = state.currentGame || TARGET_GAMES[state.gameIndex || 0];
    const freshTiming = parseCurrentDropProgress(game);

    // If next tier exists for this game (e.g. Portrait / Icon)
    if (freshTiming && freshTiming.percent < 100) {
      updateHUDStatus(`🎁 Starting next drop tier for <b>${game.name}</b> (${freshTiming.percent}%)...`);
      state.progressPercent = freshTiming.percent;
      state.currentMinutes = freshTiming.currentMinutes;
      state.totalMinutes = freshTiming.totalMinutes;
      state.calculatedWaitMinutes = freshTiming.finalWaitMinutes;
      state.targetEndTime = Date.now() + (freshTiming.finalWaitMinutes * 60 * 1000);
      setState(state);
      isNavigating = false;
      return;
    }

    // No more tiers for DST -> Finish and close
    finishClaimingProcess(state);
  }

  function finishClaimingProcess(state) {
    if (isStopped) return;
    updateHUDStatus('🏁 <b>All Don\'t Starve Together drops completed and claimed!</b> Closing tab...');
    registerTimeout(() => {
      if (!isStopped) {
        if (typeof GM_closeTab === 'function') GM_closeTab();
        else window.close();
      }
    }, 3000);
  }

  // ============================================================
  // AUTOMATIC STREAMER SWITCHER (100% Hands-Free)
  // ============================================================
  async function autoSwitchStreamer(state) {
    if (isStopped || isSwitchingStreamer) return;
    isSwitchingStreamer = true;

    try {
      const game = state.currentGame || TARGET_GAMES[state.gameIndex || 0];
      const oldChannel = state.currentChannel;
      updateHUDStatus(`🤖 <b>Streamer offline:</b> Auto-selecting next live <b>${game.name}</b> streamer...`);

      const failed = getFailedChannels();
      const liveStreams = await fetchLiveStreamsGQL(game.name);

      let nextChannel = null;
      for (const s of liveStreams) {
        if (s.type !== 'live') continue;
        if (RU_REGEX.test(s.title) || RU_REGEX.test(s.login) || RU_REGEX.test(s.displayName)) continue;
        if (failed.includes(s.login.toLowerCase())) continue;
        nextChannel = s.login;
        break;
      }

      if (nextChannel) {
        state.currentChannel = nextChannel;
        setState(state);
        updateHUDStatus(`✨ <b>Auto-switched stream:</b> Now opening <b>${nextChannel}</b>...`);
        try { await cancellableSleep(1500); } catch (e) { return; }
        if (!isStopped) {
          window.location.href = `https://www.twitch.tv/${nextChannel}`;
        }
        return;
      }

      // Navigate to directory to discover
      updateHUDStatus(`🔍 Auto-navigating to <b>${game.name}</b> live directory...`);
      try { await cancellableSleep(1500); } catch (e) { return; }
      if (!isStopped) {
        window.location.href = `https://www.twitch.tv/directory/category/${game.slug}?filter=drops`;
      }
    } finally {
      isSwitchingStreamer = false;
    }
  }

  // ============================================================
  // ROUTER & PROCESS START
  // ============================================================
  function startClaimProcess(manual = false) {
    createHUD();
    isStopped = false;
    clearAllTimers();

    let state = getState();
    state.stopped = false;
    state.active = true;
    setState(state);

    const path = window.location.pathname;

    if (manual && !path.includes('/drops/campaigns') && !path.startsWith('/directory/category/') && path.length <= 1) {
      updateHUDStatus('🔄 Navigating to Drops Campaign Hub (DST)...');
      window.location.href = 'https://www.twitch.tv/drops/campaigns';
      return;
    }

    if (path.includes('/drops/campaigns')) {
      handleCampaignsPage();
    } else if (path.includes('/drops/inventory')) {
      handleInventoryPage(state);
    } else if (path.includes('/directory/category/')) {
      handleDirectoryPage(state);
    } else {
      const channel = path.replace(/\//g, '');
      if (channel && !path.startsWith('/directory') && !path.startsWith('/downloads') && !path.startsWith('/drops')) {
        handleStreamPage(state);
      } else {
        updateHUDStatus('Ready. Click <b>"Start / Resume"</b> to begin.', false);
        updateHUDButtons(false);
      }
    }
  }

  // Auto-init on page load
  window.addEventListener('load', () => {
    registerTimeout(() => {
      createHUD();
      const state = getState();

      if (state.stopped) {
        isStopped = true;
        updateHUDStatus('⏹ <b>Auto-claimer paused.</b> Click Start / Resume to begin.', false);
        updateHUDButtons(false);
        return;
      }

      startClaimProcess(false);
    }, 1500);
  });
})();
