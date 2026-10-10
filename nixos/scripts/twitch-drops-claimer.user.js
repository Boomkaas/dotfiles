// ==UserScript==
// @name         Twitch Drops Auto-Claimer (DST)
// @namespace    https://github.com/Boomkaas/dotfiles
// @version      4.0.0
// @description  Farms Don't Starve Together Twitch Drops: reads drop progress from Twitch's API, watches a live drops-enabled DST stream (muted, 160p), claims finished drops, and stops once everything is claimed.
// @author       Peng
// @match        https://www.twitch.tv/*
// @grant        none
// @run-at       document-start
// ==/UserScript==

(function () {
  'use strict';

  if (window.self !== window.top) return;

  // ============================================================
  // CONFIG
  // ============================================================
  const GAME_SLUG = 'dont-starve-together';
  const GQL_URL = 'https://gql.twitch.tv/gql';
  const CLIENT_ID = 'kimne78kx3ncx6brgo4mv6wki5h1ko';
  const SKIP_LANGUAGES = ['RU'];

  const TICK_MS = 60 * 1000;                  // how often progress is re-checked
  const PLAYER_TUNE_MS = 10 * 1000;           // how often mute/play/mature-gate are enforced
  const STALL_MS = 12 * 60 * 1000;            // no progress for this long on one channel -> switch
  const UNSTARTED_GRACE_MS = 20 * 60 * 1000;  // campaign never shows up in inventory -> give up on it
  const SKIP_CHANNEL_MS = 60 * 60 * 1000;

  const START_HASH = '#dst-drops';
  const STOP_HASH = '#dst-drops-stop';
  const ACTIVE_KEY = 'dstDrops.active';  // sessionStorage: this tab is the farming tab
  const STATE_KEY = 'dstDrops.state';    // sessionStorage: survives page navigations in this tab
  const STOP_KEY = 'dstDrops.stop';      // localStorage: cross-tab stop signal (used by `twitch stop`)
  const INVENTORY_URL = 'https://www.twitch.tv/drops/inventory';

  const CLAIM_TEXT = /^(claim( now)?|получить)$/i;
  const RESERVED_PATHS = new Set(['directory', 'drops', 'settings', 'search', 'downloads', 'subscriptions', 'inventory', 'wallet', 'videos', 'p', 'turbo', 'prime', 'jobs']);

  // Lowest quality + muted before the player initialises
  try {
    localStorage.setItem('video-quality', JSON.stringify({ default: '160p30' }));
    localStorage.setItem('video-muted', JSON.stringify({ default: true }));
  } catch (e) {}

  // ============================================================
  // STATE
  // ============================================================
  let stopped = true;
  let busy = false;
  let tickTimer = null;
  let tuneTimer = null;

  function freshState() {
    return {
      startedAt: Date.now(),
      channel: null,
      progressTotal: -1,
      progressAt: Date.now(),
      stalls: 0,
      unstartedSince: null,
      skipped: {},          // login -> skip until timestamp
      claiming: false,
      claimingIds: [],
      claimAttempted: [],   // dropInstanceIDs already sent through the inventory page once
      result: null,         // final message, kept so it survives navigation
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
  const onInventoryPage = () => location.pathname.startsWith('/drops/inventory');

  function getCookie(name) {
    const match = document.cookie.match(new RegExp('(?:^|; )' + name + '=([^;]*)'));
    return match ? decodeURIComponent(match[1]).replace(/^"|"$/g, '') : null;
  }

  function pageChannel() {
    const seg = location.pathname.split('/').filter(Boolean);
    if (seg.length !== 1 || RESERVED_PATHS.has(seg[0].toLowerCase())) return null;
    return seg[0].toLowerCase();
  }

  // ============================================================
  // TWITCH GQL
  // ============================================================
  async function gql(query, variables = {}) {
    const headers = { 'Client-Id': CLIENT_ID, 'Content-Type': 'application/json' };
    const token = getCookie('auth-token');
    if (token) headers.Authorization = `OAuth ${token}`;
    const deviceId = getCookie('unique_id');
    if (deviceId) headers['X-Device-Id'] = deviceId;

    const res = await fetch(GQL_URL, { method: 'POST', headers, body: JSON.stringify({ query, variables }) });
    if (!res.ok) throw new Error(`Twitch API HTTP ${res.status}`);
    const json = await res.json();
    if (json.errors?.length) throw new Error(`Twitch API: ${json.errors.map((e) => e.message).join('; ')}`);
    return json.data;
  }

  const DROPS_QUERY = `query {
    currentUser {
      login
      dropCampaigns { id name status endAt game { slug } self { isAccountConnected } }
      inventory {
        dropCampaignsInProgress {
          id name status endAt
          game { slug }
          allow { isEnabled channels { name } }
          timeBasedDrops {
            id name requiredMinutesWatched requiredSubs startAt endAt
            benefitEdges { benefit { name } }
            self { currentMinutesWatched isClaimed dropInstanceID }
          }
        }
      }
    }
  }`;

  // Optional: lets us tell apart "not started yet" from "already fully claimed" / "sub-only".
  // Twitch may gate this behind an integrity check, so failures are tolerated.
  const CAMPAIGN_DETAILS_QUERY = `query {
    currentUser {
      dropCampaigns { id timeBasedDrops { requiredMinutesWatched requiredSubs endAt benefitEdges { benefit { id } } } }
      inventory { gameEventDrops { id } }
    }
  }`;

  const STREAMS_QUERY = `query($slug: String!) {
    game(slug: $slug) {
      streams(first: 50, options: { sort: VIEWER_COUNT, systemFilters: [DROPS_ENABLED] }) {
        edges { node { type broadcaster { login broadcastSettings { language } } game { slug } } }
      }
    }
  }`;

  async function filterUnstarted(unstarted) {
    if (!unstarted.length) return unstarted;
    try {
      const user = (await gql(CAMPAIGN_DETAILS_QUERY)).currentUser;
      const owned = new Set((user?.inventory?.gameEventDrops || []).map((d) => d.id));
      const details = new Map((user?.dropCampaigns || []).map((c) => [c.id, c.timeBasedDrops]));
      const now = Date.now();
      return unstarted.filter((c) => {
        const drops = details.get(c.id);
        if (!drops?.length) return true; // no details -> assume it's farmable
        return drops.some((d) => !d.requiredSubs && d.requiredMinutesWatched > 0 && Date.parse(d.endAt) > now &&
          (d.benefitEdges || []).some((e) => !owned.has(e.benefit?.id)));
      });
    } catch (e) {
      log('Campaign details unavailable, falling back to watch-and-see:', e.message);
      return unstarted;
    }
  }

  async function fetchDrops() {
    const user = (await gql(DROPS_QUERY)).currentUser;
    if (!user) throw new Error('Not logged in to Twitch');

    const now = Date.now();
    const isDst = (c) => c?.game?.slug === GAME_SLUG;
    const isRunning = (c) => c.status === 'ACTIVE' && Date.parse(c.endAt) > now;

    const dashboard = (user.dropCampaigns || []).filter((c) => isDst(c) && isRunning(c));
    const inProgress = (user.inventory?.dropCampaignsInProgress || []).filter(isDst);
    const drops = inProgress.flatMap((c) => (c.timeBasedDrops || []).map((d) => ({ ...d, campaign: c })));

    const claimable = drops.filter((d) => d.self?.dropInstanceID && !d.self.isClaimed);
    const pending = drops.filter((d) =>
      !d.requiredSubs && d.requiredMinutesWatched > 0 &&
      Date.parse(d.startAt) <= now && Date.parse(d.endAt) > now &&
      !d.self?.isClaimed && !d.self?.dropInstanceID &&
      (d.self?.currentMinutesWatched || 0) < d.requiredMinutesWatched);
    const unstarted = await filterUnstarted(dashboard.filter((c) => !inProgress.some((p) => p.id === c.id)));
    const disconnected = dashboard.filter((c) => c.self && !c.self.isAccountConnected);
    const progressTotal = drops.reduce((sum, d) => sum + (d.self?.currentMinutesWatched || 0), 0);

    // Channels allowed by the campaigns we still need; null means any drops-enabled channel works
    let allowed = new Set();
    for (const c of new Set(pending.map((d) => d.campaign))) {
      if (!c.allow?.isEnabled || !c.allow.channels?.length) { allowed = null; break; }
      c.allow.channels.forEach((ch) => allowed.add(ch.name.toLowerCase()));
    }
    if (unstarted.length) allowed = null;

    return { dashboard, claimable, pending, unstarted, disconnected, progressTotal, allowed };
  }

  async function fetchCandidateChannels(state, allowed) {
    const data = await gql(STREAMS_QUERY, { slug: GAME_SLUG });
    const now = Date.now();
    return (data.game?.streams?.edges || [])
      .map((e) => e.node)
      .filter((s) => s.type === 'live' && s.game?.slug === GAME_SLUG)
      .filter((s) => !SKIP_LANGUAGES.includes((s.broadcaster.broadcastSettings?.language || '').toUpperCase()))
      .map((s) => s.broadcaster.login.toLowerCase())
      .filter((login) => !(state.skipped[login] > now))
      .filter((login) => !allowed || allowed.has(login));
  }

  // ============================================================
  // HUD
  // ============================================================
  let hud = null;

  function ensureHud() {
    if (hud && document.body.contains(hud.root)) return hud;
    const root = document.createElement('div');
    root.style.cssText = 'position:fixed;right:16px;bottom:16px;z-index:999999;width:320px;padding:12px 14px;' +
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

  function describeDrops(info, state) {
    const left = (d) => d.requiredMinutesWatched - (d.self?.currentMinutesWatched || 0);
    const lines = info.pending
      .slice()
      .sort((a, b) => left(a) - left(b))
      .map((d) => {
        const name = d.benefitEdges?.[0]?.benefit?.name || d.name;
        return `• ${name}: ${d.self?.currentMinutesWatched || 0}/${d.requiredMinutesWatched}m (~${left(d)}m left)`;
      });
    info.unstarted.forEach((c) => lines.push(`• ${c.name}: not started yet`));
    if (info.disconnected.length) lines.push('⚠️ Klei account not linked — link it on twitch.tv/drops/campaigns');
    if (state.stalls >= 2) lines.push('⚠️ Progress keeps stalling — make sure AdGuard/tracking protection isn\'t blocking twitch.tv');
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
  // CLAIMING (via Twitch's own inventory UI, which handles the integrity check)
  // ============================================================
  async function clickClaimButtons() {
    let clicked = 0;
    for (let i = 0; i < 20 && !stopped; i++) {
      const buttons = Array.from(document.querySelectorAll('button'))
        .filter((b) => !b.disabled && !b.closest('nav, header') && CLAIM_TEXT.test((b.textContent || '').trim()));
      buttons.forEach((b) => b.click());
      clicked += buttons.length;
      if (clicked && !buttons.length) break;
      await sleep(1500);
    }
    log(`Clicked ${clicked} claim button(s)`);
    await sleep(3000);
  }

  // ============================================================
  // MAIN LOOP
  // ============================================================
  async function tick() {
    const state = loadState();

    if (!getCookie('auth-token')) {
      return finish('🔑 Log in to Twitch in this browser, then press Start.');
    }

    if (state.claiming) {
      if (!onInventoryPage()) { location.href = INVENTORY_URL; return; }
      show('🎁 Claiming finished drops…');
      await clickClaimButtons();
      state.claiming = false;
      state.claimAttempted.push(...state.claimingIds);
      saveState(state);
    }

    const info = await fetchDrops();
    const claimable = info.claimable.filter((d) => !state.claimAttempted.includes(d.self.dropInstanceID));
    const unclaimed = info.claimable.length - claimable.length;

    if (claimable.length) {
      state.claiming = true;
      state.claimingIds = claimable.map((d) => d.self.dropInstanceID);
      saveState(state);
      show(`🎁 ${claimable.length} drop(s) ready — opening inventory to claim…`);
      location.href = INVENTORY_URL;
      return;
    }

    const manualNote = unclaimed ? `\n⚠️ ${unclaimed} finished drop(s) couldn't be auto-claimed — claim them on the inventory page.` : '';

    if (!info.dashboard.length && !info.pending.length) {
      return finish('😴 No active Don\'t Starve Together drop campaign right now.', manualNote.trim());
    }
    if (!info.pending.length && !info.unstarted.length) {
      return finish('✅ All Don\'t Starve Together drops claimed!', manualNote.trim());
    }

    const watching = state.channel && pageChannel() === state.channel;

    // A campaign that never appears in the inventory despite watching can't be farmed (sub-only, restricted, …)
    if (!info.pending.length) {
      if (watching) state.unstartedSince = state.unstartedSince || Date.now();
      if (state.unstartedSince && Date.now() - state.unstartedSince > UNSTARTED_GRACE_MS) {
        return finish('✅ All watchable DST drops are done — these never started progressing:',
          info.unstarted.map((c) => `• ${c.name}`).join('\n') + manualNote);
      }
    } else {
      state.unstartedSince = null;
    }

    // Progress watchdog: switch channels if watched minutes stop increasing
    if (info.progressTotal > state.progressTotal) {
      state.progressTotal = info.progressTotal;
      state.progressAt = Date.now();
      state.stalls = 0;
    } else if (watching && info.pending.length && Date.now() - state.progressAt > STALL_MS) {
      log(`No progress on ${state.channel} for ${STALL_MS / 60000}m, switching`);
      state.skipped[state.channel] = Date.now() + SKIP_CHANNEL_MS;
      state.stalls++;
      state.channel = null;
    }

    const candidates = await fetchCandidateChannels(state, info.allowed);
    const details = describeDrops(info, state) + manualNote;

    if (state.channel && candidates.includes(state.channel)) {
      saveState(state);
      if (!watching) { location.href = `https://www.twitch.tv/${state.channel}`; return; }
      tunePlayer();
      return show(`📺 Watching ${state.channel}`, details);
    }

    if (!candidates.length) {
      state.channel = null;
      saveState(state);
      pausePlayer();
      return show('⏳ No eligible DST stream is live — checking again every minute.', details);
    }

    state.channel = candidates[0];
    state.progressAt = Date.now();
    saveState(state);
    show(`➡️ Switching to ${state.channel}…`, details);
    location.href = `https://www.twitch.tv/${state.channel}`;
  }

  async function loop() {
    if (stopped || busy) return;
    busy = true;
    try {
      await tick();
    } catch (e) {
      console.error('[DST Drops]', e);
      show(`⚠️ ${e.message} — retrying in a minute.`);
    } finally {
      busy = false;
      if (!stopped) tickTimer = setTimeout(loop, TICK_MS);
    }
  }

  function start() {
    sessionStorage.setItem(ACTIVE_KEY, '1');
    saveState(freshState());
    resume();
  }

  function resume() {
    stopped = false;
    show('🔄 Checking drop progress…');
    clearInterval(tuneTimer);
    tuneTimer = setInterval(() => {
      if (pageChannel() && pageChannel() === loadState().channel) tunePlayer();
    }, PLAYER_TUNE_MS);
    loop();
  }

  function stop(message, details = '') {
    stopped = true;
    clearTimeout(tickTimer);
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

    const result = loadState().result;
    if (result && sessionStorage.getItem(STATE_KEY)) show(result.message, result.details);
    else if (location.pathname.startsWith('/drops')) show('Idle — press Start to farm DST drops in this tab.');
  }

  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', boot, { once: true });
  else boot();
})();
