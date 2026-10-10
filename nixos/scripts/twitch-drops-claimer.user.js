// ==UserScript==
// @name         Twitch Drops Auto-Claimer (DST)
// @namespace    https://github.com/Boomkaas/dotfiles
// @version      5.0.0
// @description  Farms Don't Starve Together Twitch Drops using Twitch's own pages: reads progress from the real Drops Campaigns/Inventory pages, watches a live drops-enabled DST stream (muted, 160p), clicks "Claim Now", and stops once everything is claimed.
// @author       Peng
// @match        https://www.twitch.tv/*
// @grant        none
// @inject-into  page
// @run-at       document-start
// ==/UserScript==

// How it works
// ------------
// Twitch protects logged-in API calls with an anti-bot "integrity" token that only its own page
// can obtain, so this script never makes logged-in API calls itself. Instead it:
//   1. opens /drops/campaigns and /drops/inventory and reads the data those pages fetch
//      (by observing the page's own fetch() responses),
//   2. clicks the page's own "Claim Now" buttons,
//   3. watches a stream like a normal viewer, returning to the inventory page whenever the next
//      drop should be finished (and at least every CHECK_MAX_MS) to refresh progress.
// Only public, logged-out queries (live DST streams) are sent directly.

(function () {
  'use strict';

  if (window.self !== window.top) return;

  // ============================================================
  // CONFIG
  // ============================================================
  const GAME = { id: '488634', slug: 'dont-starve-together', name: "don't starve together" };
  const GQL_URL = 'https://gql.twitch.tv/gql';
  const PUBLIC_CLIENT_ID = 'kimne78kx3ncx6brgo4mv6wki5h1ko';
  const SKIP_LANGUAGES = ['RU'];

  const WATCH_TICK_MS = 60 * 1000;          // stream health check while watching
  const PLAYER_TUNE_MS = 10 * 1000;         // mute / play / mature-gate enforcement
  const CHECK_MIN_MS = 3 * 60 * 1000;       // shortest time between inventory checks
  const CHECK_MAX_MS = 15 * 60 * 1000;      // longest time between inventory checks
  const STALL_MIN_WATCH_MS = 8 * 60 * 1000; // watched this long with zero progress -> switch channel
  const PROBE_ROUNDS = 2;                   // watch rounds for a campaign that hasn't started progressing
  const PAGE_DATA_TIMEOUT_MS = 30 * 1000;
  const SKIP_CHANNEL_MS = 60 * 60 * 1000;

  const URLS = {
    campaigns: 'https://www.twitch.tv/drops/campaigns',
    inventory: 'https://www.twitch.tv/drops/inventory',
    channel: (login) => `https://www.twitch.tv/${login}`,
  };
  const START_HASH = '#dst-drops';
  const STOP_HASH = '#dst-drops-stop';
  const ACTIVE_KEY = 'dstDrops.active';  // sessionStorage: this tab is the farming tab
  const STATE_KEY = 'dstDrops.state';    // sessionStorage: survives navigations within this tab
  const STOP_KEY = 'dstDrops.stop';      // localStorage: cross-tab stop signal (used by `twitch stop`)

  const CLAIM_TEXT = /^(claim( now)?|получить( сейчас)?)$/i;
  const RESERVED_PATHS = new Set(['directory', 'drops', 'settings', 'search', 'downloads', 'subscriptions', 'inventory', 'wallet', 'videos', 'p', 'turbo', 'prime', 'jobs', 'login', 'signup']);

  // Lowest quality + muted before the player initialises
  try {
    localStorage.setItem('video-quality', JSON.stringify({ default: '160p30' }));
    localStorage.setItem('video-muted', JSON.stringify({ default: true }));
  } catch (e) {}

  // ============================================================
  // PAGE DATA SNIFFER — reads what Twitch's own page fetches
  // ============================================================
  const seen = { inventory: null, dashboard: null, session: null };

  function scan(node, depth = 0) {
    if (!node || typeof node !== 'object' || depth > 12) return;
    if (Array.isArray(node)) { node.forEach((n) => scan(n, depth + 1)); return; }
    if ('dropCampaignsInProgress' in node) seen.inventory = node.dropCampaignsInProgress || [];
    if (Array.isArray(node.dropCampaigns) && node.dropCampaigns.some((c) => c && 'status' in c && 'game' in c)) {
      seen.dashboard = node.dropCampaigns;
    }
    if (node.dropCurrentSession && typeof node.dropCurrentSession === 'object') seen.session = node.dropCurrentSession;
    for (const key in node) scan(node[key], depth + 1);
  }

  const realFetch = window.fetch;
  window.fetch = function (input, init) {
    const promise = realFetch.apply(this, arguments);
    try {
      const url = typeof input === 'string' ? input : (input && input.url) || '';
      if (url.startsWith(GQL_URL)) {
        promise.then((res) => res.clone().json().then(scan)).catch(() => {});
      }
    } catch (e) {}
    return promise;
  };

  function waitForSeen(key, timeoutMs) {
    return new Promise((resolve) => {
      const started = Date.now();
      const poll = () => {
        if (stopped) return resolve(null);
        if (seen[key]) return setTimeout(() => resolve(seen[key]), 1500); // let batched responses settle
        if (Date.now() - started > timeoutMs) return resolve(null);
        setTimeout(poll, 500);
      };
      poll();
    });
  }

  // ============================================================
  // STATE
  // ============================================================
  let stopped = true;
  let watchTimer = null;
  let tuneTimer = null;

  function freshState() {
    return {
      startedAt: Date.now(),
      phase: 'campaigns',     // campaigns -> inventory -> watch -> inventory -> ...
      campaigns: null,        // [{ id, name, connected }] active DST campaigns from the dashboard
      channel: null,
      nextCheckAt: 0,
      watchStartedAt: null,
      watchedMs: 0,           // time spent watching since the last inventory check
      lastTotal: -1,          // total watched minutes at the last inventory check
      progress: [],           // last known [{ name, done, required }]
      progressAt: 0,
      skipped: {},            // login -> skip until timestamp
      stalls: 0,
      claimRounds: 0,
      manualClaims: 0,
      probeRounds: 0,
      readFails: 0,
      note: '',
      result: null,           // final message, kept so it survives navigation
    };
  }

  function loadState() {
    try { return { ...freshState(), ...JSON.parse(sessionStorage.getItem(STATE_KEY) || '{}') }; }
    catch (e) { return freshState(); }
  }

  function saveState(state) {
    sessionStorage.setItem(STATE_KEY, JSON.stringify(state));
  }

  const log = (...args) => console.log('[DST Drops]', ...args);
  const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
  const minutes = (ms) => Math.max(0, Math.round(ms / 60000));
  const onPath = (prefix) => location.pathname.startsWith(prefix);

  function go(url) {
    log('→', url);
    location.href = url;
  }

  function pageChannel() {
    const seg = location.pathname.split('/').filter(Boolean);
    if (seg.length !== 1 || RESERVED_PATHS.has(seg[0].toLowerCase())) return null;
    return seg[0].toLowerCase();
  }

  function isDst(game) {
    if (!game) return false;
    const names = [game.name, game.displayName].filter(Boolean).map((n) => n.toLowerCase().replace(/’/g, "'"));
    return game.id === GAME.id || game.slug === GAME.slug || names.includes(GAME.name);
  }

  // ============================================================
  // DROP ANALYSIS (on data read from the inventory page)
  // ============================================================
  function analyzeInventory(campaigns) {
    const now = Date.now();
    const inWindow = (d) => (!d.startAt || Date.parse(d.startAt) <= now) && (!d.endAt || Date.parse(d.endAt) > now);
    const dst = campaigns.filter((c) => isDst(c.game));
    const drops = dst.flatMap((c) => (c.timeBasedDrops || []).map((d) => ({ ...d, campaign: c })));
    const dropName = (d) => d.benefitEdges?.[0]?.benefit?.name || d.name || 'Drop';

    const claimable = drops.filter((d) => d.self?.dropInstanceID && !d.self.isClaimed);
    const pending = drops.filter((d) =>
      inWindow(d) && !(d.requiredSubs > 0) && d.requiredMinutesWatched > 0 &&
      !d.self?.isClaimed && !d.self?.dropInstanceID &&
      (d.self?.currentMinutesWatched || 0) < d.requiredMinutesWatched);

    return {
      campaignIds: dst.map((c) => c.id),
      claimable,
      progress: pending
        .map((d) => ({ name: dropName(d), done: d.self?.currentMinutesWatched || 0, required: d.requiredMinutesWatched }))
        .sort((a, b) => (a.required - a.done) - (b.required - b.done)),
      total: drops.reduce((sum, d) => sum + (d.self?.currentMinutesWatched || 0), 0),
    };
  }

  // ============================================================
  // PUBLIC TWITCH QUERIES (logged out — no integrity check needed)
  // ============================================================
  async function publicGql(query, variables) {
    const res = await realFetch(GQL_URL, {
      method: 'POST',
      credentials: 'omit',
      headers: { 'Client-Id': PUBLIC_CLIENT_ID, 'Content-Type': 'application/json' },
      body: JSON.stringify({ query, variables }),
    });
    if (!res.ok) throw new Error(`Twitch API HTTP ${res.status}`);
    const json = await res.json();
    if (json.errors?.length) throw new Error(`Twitch API: ${json.errors.map((e) => e.message).join('; ')}`);
    return json.data;
  }

  const STREAMS_QUERY = `query($slug: String!) {
    game(slug: $slug) {
      streams(first: 50, options: { sort: VIEWER_COUNT, systemFilters: [DROPS_ENABLED] }) {
        edges { node { type broadcaster { login broadcastSettings { language } } game { slug } } }
      }
    }
  }`;

  async function fetchCandidateChannels(state) {
    const data = await publicGql(STREAMS_QUERY, { slug: GAME.slug });
    const now = Date.now();
    return (data.game?.streams?.edges || [])
      .map((e) => e.node)
      .filter((s) => s.type === 'live' && s.game?.slug === GAME.slug)
      .filter((s) => !SKIP_LANGUAGES.includes((s.broadcaster.broadcastSettings?.language || '').toUpperCase()))
      .map((s) => s.broadcaster.login.toLowerCase())
      .filter((login) => !(state.skipped[login] > now));
  }

  // ============================================================
  // HUD
  // ============================================================
  let hud = null;

  function ensureHud() {
    if (hud && document.body.contains(hud.root)) return hud;
    const root = document.createElement('div');
    root.style.cssText = 'position:fixed;right:16px;bottom:16px;z-index:999999;width:330px;padding:12px 14px;' +
      'background:#18181b;color:#efeff1;border:1px solid #9147ff;border-radius:8px;font:13px/1.45 Inter,Roobert,sans-serif;' +
      'box-shadow:0 6px 24px rgba(0,0,0,.5)';
    const title = document.createElement('div');
    title.textContent = '🎮 DST Drops';
    title.style.cssText = 'font-weight:700;color:#bf94ff;margin-bottom:6px';
    const status = document.createElement('div');
    const details = document.createElement('div');
    details.style.cssText = 'margin-top:6px;color:#adadb8;font-size:12px;white-space:pre-line';
    const button = document.createElement('button');
    button.style.cssText = 'margin-top:10px;padding:5px 12px;border:0;border-radius:4px;color:#fff;font-weight:600;cursor:pointer';
    button.addEventListener('click', () => (stopped ? start() : stop('Stopped')));
    root.append(title, status, details, button);
    document.body.appendChild(root);
    hud = { root, status, details, button };
    return hud;
  }

  function show(status, details = '') {
    log(status, details);
    if (!document.body) return;
    const h = ensureHud();
    h.status.textContent = status;
    h.details.textContent = details;
    h.button.textContent = stopped ? '▶ Start' : '⏹ Stop';
    h.button.style.background = stopped ? '#9147ff' : '#e91916';
  }

  function progressLines(state, extraMs = 0) {
    const extra = minutes(extraMs);
    const lines = state.progress.map((p) => {
      const done = Math.min(p.required, p.done + extra);
      return `• ${p.name}: ${done}/${p.required}m (~${p.required - done}m left)`;
    });
    if (!lines.length && state.campaigns?.length) lines.push(...state.campaigns.map((c) => `• ${c.name}: waiting for progress to start`));
    if (state.campaigns?.some((c) => c.connected === false)) lines.push('⚠️ Klei account not linked — link it on the All Campaigns tab');
    if (state.stalls >= 2) lines.push('⚠️ Progress keeps stalling — check AdGuard/tracking protection isn\'t blocking twitch.tv');
    if (state.note) lines.push(state.note);
    return lines.join('\n');
  }

  // ============================================================
  // PLAYER
  // ============================================================
  function tunePlayer() {
    document.querySelector('[data-a-target="content-classification-gate-overlay-start-watching-button"]')?.click();
    document.querySelector('[data-a-target="player-overlay-mature-accept"]')?.click();
    const video = document.querySelector('video');
    if (!video) return;
    video.muted = true;
    if (video.paused) video.play().catch(() => {});
  }

  function pausePlayer() {
    document.querySelectorAll('video').forEach((v) => v.pause());
  }

  // ============================================================
  // PHASE: campaigns page — which DST campaigns are running?
  // ============================================================
  async function campaignsPhase(state) {
    if (!onPath('/drops/campaigns')) return go(URLS.campaigns);
    show('📋 Reading Drops campaigns…');
    const dashboard = await waitForSeen('dashboard', PAGE_DATA_TIMEOUT_MS);
    if (stopped) return;
    if (!dashboard) return readFailed(state, 'campaigns');

    const now = Date.now();
    state.campaigns = dashboard
      .filter((c) => isDst(c.game) && c.status === 'ACTIVE' && (!c.endAt || Date.parse(c.endAt) > now))
      .map((c) => ({ id: c.id, name: c.name, connected: c.self ? c.self.isAccountConnected !== false : null }));
    state.readFails = 0;
    log('Active DST campaigns:', state.campaigns);

    if (!state.campaigns.length) return finish('😴 No active Don\'t Starve Together drop campaign right now.');
    state.phase = 'inventory';
    saveState(state);
    go(URLS.inventory);
  }

  // ============================================================
  // PHASE: inventory page — progress, claiming, what to do next
  // ============================================================
  async function inventoryPhase(state) {
    if (!onPath('/drops/inventory')) return go(URLS.inventory);
    show('📦 Reading drop progress from your inventory…');
    const inventory = await waitForSeen('inventory', PAGE_DATA_TIMEOUT_MS);
    if (stopped) return;
    if (!inventory) return readFailed(state, 'inventory');
    state.readFails = 0;

    const info = analyzeInventory(inventory);
    log('Inventory:', info);

    // 1. Claim finished drops with the page's own buttons, then reload to confirm
    if (info.claimable.length) {
      if (state.claimRounds < 2) {
        state.claimRounds++;
        saveState(state);
        show(`🎁 Claiming ${info.claimable.length} finished drop(s)…`);
        const clicked = await clickClaimButtons();
        log(`Clicked ${clicked} claim button(s)`);
        await sleep(4000);
        return location.reload();
      }
      state.manualClaims = info.claimable.length;
    } else {
      state.manualClaims = 0;
    }
    state.claimRounds = 0;
    state.note = state.manualClaims ? `⚠️ ${state.manualClaims} finished drop(s) need claiming by hand on the Inventory page.` : '';

    // 2. Progress watchdog: watched a while but minutes didn't move -> blame the channel
    if (state.lastTotal >= 0 && state.channel && state.watchedMs >= STALL_MIN_WATCH_MS && info.total <= state.lastTotal && info.progress.length) {
      log(`No progress on ${state.channel} after ${minutes(state.watchedMs)}m, skipping it for a while`);
      state.skipped[state.channel] = Date.now() + SKIP_CHANNEL_MS;
      state.stalls++;
      state.channel = null;
    } else if (state.lastTotal >= 0 && info.total > state.lastTotal) {
      state.stalls = 0;
    }
    state.lastTotal = info.total;
    state.watchedMs = 0;
    state.progress = info.progress;
    state.progressAt = Date.now();

    // 3. Decide what's next
    const unstarted = (state.campaigns || []).filter((c) => !info.campaignIds.includes(c.id));
    if (info.progress.length) {
      state.probeRounds = 0;
      const soonest = Math.min(...info.progress.map((p) => p.required - p.done));
      return startWatching(state, Math.min(CHECK_MAX_MS, Math.max(CHECK_MIN_MS, (soonest + 2) * 60000)));
    }
    if (unstarted.length && state.probeRounds < PROBE_ROUNDS) {
      state.probeRounds++;
      return startWatching(state, CHECK_MAX_MS);
    }
    if (unstarted.length) {
      return finish('✅ All watchable DST drops are done — these campaigns never started progressing by watching:',
        unstarted.map((c) => `• ${c.name}`).concat(state.note || []).join('\n'));
    }
    return finish('✅ All Don\'t Starve Together drops claimed!', state.note);
  }

  async function clickClaimButtons() {
    let clicked = 0;
    for (let i = 0; i < 10 && !stopped; i++) {
      const buttons = Array.from(document.querySelectorAll('button'))
        .filter((b) => !b.disabled && !b.closest('nav, header') && CLAIM_TEXT.test((b.textContent || '').trim()));
      if (!buttons.length && clicked) break;
      for (const b of buttons) { b.click(); clicked++; await sleep(800); }
      await sleep(1500);
    }
    return clicked;
  }

  function readFailed(state, what) {
    state.readFails++;
    saveState(state);
    if (state.readFails <= 2) {
      show(`⚠️ Couldn't read the ${what} page yet — reloading (try ${state.readFails}/2)…`);
      setTimeout(() => { if (!stopped) location.reload(); }, 3000);
      return;
    }
    finish(`⚠️ Couldn't read your Drops ${what}. Are you logged in to Twitch in this tab? Press Start to retry.`);
  }

  // ============================================================
  // PHASE: watch a stream until the next inventory check
  // ============================================================
  async function startWatching(state, checkInMs) {
    const candidates = await fetchCandidateChannels(state);
    if (stopped) return;
    if (!candidates.length) {
      state.channel = null;
      state.phase = 'waiting';
      state.checkInMs = checkInMs;
      saveState(state);
      pausePlayer();
      show('⏳ No live drops-enabled DST stream right now — checking every minute.', progressLines(state));
      return scheduleTick();
    }
    if (!state.channel || !candidates.includes(state.channel)) state.channel = candidates[0];
    state.phase = 'watch';
    state.nextCheckAt = Date.now() + checkInMs;
    state.watchStartedAt = null;
    saveState(state);
    show(`➡️ Going to ${state.channel}…`, progressLines(state));
    go(URLS.channel(state.channel));
  }

  async function waitingPhase(state) {
    const candidates = await fetchCandidateChannels(state);
    if (stopped) return;
    if (candidates.length) return startWatching(state, state.checkInMs || CHECK_MAX_MS);
    show('⏳ No live drops-enabled DST stream right now — checking every minute.', progressLines(state));
    scheduleTick();
  }

  async function watchPhase(state) {
    if (pageChannel() !== state.channel) return go(URLS.channel(state.channel));
    if (!state.watchStartedAt) { state.watchStartedAt = Date.now(); saveState(state); }
    tunePlayer();

    const watchedNow = Date.now() - state.watchStartedAt;
    if (Date.now() >= state.nextCheckAt) {
      state.watchedMs += watchedNow;
      state.phase = 'inventory';
      saveState(state);
      show('📦 Time for a progress check…');
      return go(URLS.inventory);
    }

    // Still a live, drops-enabled DST stream?
    const candidates = await fetchCandidateChannels(state);
    if (stopped) return;
    if (!candidates.includes(state.channel)) {
      log(`${state.channel} is no longer an eligible DST stream`);
      state.watchedMs += watchedNow;
      state.channel = null;
      saveState(state);
      return startWatching(state, Math.max(CHECK_MIN_MS, state.nextCheckAt - Date.now()));
    }

    const session = seen.session;
    const sessionLine = session?.requiredMinutesWatched
      ? `\nLive session: ${session.currentMinutesWatched || 0}/${session.requiredMinutesWatched}m`
      : '';
    show(`📺 Watching ${state.channel} — next progress check in ~${minutes(state.nextCheckAt - Date.now())}m`,
      progressLines(state, Date.now() - state.progressAt) + sessionLine);
    scheduleTick();
  }

  function scheduleTick() {
    clearTimeout(watchTimer);
    if (!stopped) watchTimer = setTimeout(run, WATCH_TICK_MS);
  }

  // ============================================================
  // DRIVER
  // ============================================================
  const PHASES = { campaigns: campaignsPhase, inventory: inventoryPhase, watch: watchPhase, waiting: waitingPhase };

  async function run() {
    if (stopped) return;
    const state = loadState();
    try {
      await (PHASES[state.phase] || campaignsPhase)(state);
    } catch (e) {
      console.error('[DST Drops]', e);
      show(`⚠️ ${e.message} — retrying in a minute.`);
      scheduleTick();
    }
  }

  function start() {
    sessionStorage.setItem(ACTIVE_KEY, '1');
    saveState(freshState());
    resume();
  }

  function resume() {
    stopped = false;
    show('🔄 Starting…');
    clearInterval(tuneTimer);
    tuneTimer = setInterval(() => {
      const state = loadState();
      if (state.phase === 'watch' && pageChannel() === state.channel) tunePlayer();
    }, PLAYER_TUNE_MS);
    run();
  }

  function stop(message, details = '') {
    stopped = true;
    clearTimeout(watchTimer);
    clearInterval(tuneTimer);
    sessionStorage.removeItem(ACTIVE_KEY);
    pausePlayer();
    show(`⏹ ${message}`, details);
  }

  function finish(message, details = '') {
    const state = loadState();
    state.result = { message, details };
    saveState(state);
    stop(message, details);
    show(message, details);
  }

  // ============================================================
  // BOOT
  // ============================================================
  function boot() {
    if (location.hash === STOP_HASH) {
      localStorage.setItem(STOP_KEY, String(Date.now()));
      history.replaceState(null, '', location.pathname);
      show('⏹ Stop signal sent to the farming tab. You can close this tab.');
      return;
    }

    window.addEventListener('storage', (e) => {
      if (e.key === STOP_KEY && e.newValue && !stopped) stop('Stopped from the command line');
    });

    if (location.hash === START_HASH) {
      history.replaceState(null, '', location.pathname);
      return start();
    }

    if (sessionStorage.getItem(ACTIVE_KEY)) {
      if (Number(localStorage.getItem(STOP_KEY) || 0) > loadState().startedAt) return stop('Stopped from the command line');
      return resume();
    }

    const result = sessionStorage.getItem(STATE_KEY) && loadState().result;
    if (result) show(result.message, result.details);
    else if (onPath('/drops')) show('Idle — press Start to farm DST drops in this tab.');
  }

  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', boot, { once: true });
  else boot();
})();
