// ==UserScript==
// @name         Epic Games Store - Auto Free Games Claimer
// @namespace    https://github.com/Boomkaas/dotfiles
// @version      2.0.0
// @description  Claims the weekly free Epic Games Store games in your logged-in Firefox. Stoppable and resumable at any step.
// @author       Peng
// @match        https://*.epicgames.com/*
// @connect      store-site-backend-static-ipv4.ak.epicgames.com
// @connect      store-site-backend-static.ak.epicgames.com
// @grant        GM_getValue
// @grant        GM_setValue
// @grant        GM_addValueChangeListener
// @grant        GM_xmlhttpRequest
// @grant        window.close
// @run-at       document-idle
// ==/UserScript==

// How it works
//   1. The list of free games comes from Epic's promotions API (layout-independent),
//      with a fallback that scrapes "Free Now" cards on the free-games page.
//   2. Each product page is opened in turn; the purchase button tells us whether the
//      game is already owned, needs a base game, or can be claimed with "Get".
//   3. Checkout lives in an overlay iframe. The same script runs inside that frame and
//      only acts while the top tab has armed it, so manual purchases are never touched.
//      The current flow is "This is free" -> "Add to library"; the older
//      "Place Order" flow is still handled, but only when the order total is zero.
//   4. A claim counts once Epic shows a thank-you screen or the button flips to "In Library".
//
// Run state lives in Violentmonkey storage so the top tab and the checkout iframe
// (a different origin) see the same state, and `epic stop` from another tab can halt it.

(function () {
  'use strict';

  const STATE_KEY = 'epic_claimer_v2';
  const EVENT_KEY = 'epic_claimer_v2_event';
  const STORE_HOST = 'store.epicgames.com';
  const FREE_GAMES_URL = 'https://store.epicgames.com/en-US/free-games';
  const PROMO_URLS = [
    'https://store-site-backend-static-ipv4.ak.epicgames.com/freeGamesPromotions?locale=en-US&country=US&allowCountries=US',
    'https://store-site-backend-static.ak.epicgames.com/freeGamesPromotions?locale=en-US&country=US&allowCountries=US',
  ];
  const START_HASH = '#epic-claim';
  const STOP_HASH = '#epic-stop';

  const PACE_MS = 1500;                  // calm pause between steps
  const POLL_MS = 800;                   // checkout polling interval
  const CTA_TIMEOUT_MS = 45000;          // product page must show its purchase button by then
  const CHECKOUT_TIMEOUT_MS = 90000;     // per attempt, extended while a captcha is shown
  const CHECKOUT_HARD_LIMIT_MS = 600000; // never wait longer than this on one game
  const ARM_MS = 5 * 60000;              // checkout frames only act this long after "Get"
  const STALE_MS = 15 * 60000;           // a run not touched for this long is abandoned
  const MAX_ATTEMPTS = 2;                // "Get" clicks per game before giving up
  const AUTO_CLOSE_MS = 8000;

  const isTop = window.self === window.top;
  const log = (...args) => console.log('[Epic Claimer]', ...args);
  const now = () => Date.now();
  const norm = (s) => (s || '').replace(/\s+/g, ' ').trim().toLowerCase();
  const textOf = (el) => norm(el.innerText || el.textContent || el.value);
  const bodyText = () => norm(document.body ? document.body.innerText : '');

  const SUCCESS_RE = /thanks for your order|thank you for your order|thank you for buying|it's all yours|order complete/;
  const REGION_RE = /unavailable in your (platform or )?region|not available in your (country|region)/;
  const REJECTED_RE = /your account is unable to|unable to complete (your|this) (order|purchase)|purchase failed/;

  // ==========================================
  // Shared state
  // ==========================================
  const loadState = () => GM_getValue(STATE_KEY, null);
  const isLive = (s) => !!s && s.status === 'running' && now() - (s.updatedAt || 0) < STALE_MS;

  function saveState(s) {
    s.updatedAt = now();
    GM_setValue(STATE_KEY, s);
    return s;
  }

  // ==========================================
  // DOM helpers
  // ==========================================
  function isVisible(el) {
    if (!el || !el.isConnected) return false;
    const r = el.getBoundingClientRect();
    if (r.width <= 0 || r.height <= 0) return false;
    const cs = getComputedStyle(el);
    return cs.visibility !== 'hidden' && cs.display !== 'none';
  }

  function isClickable(el) {
    return isVisible(el) &&
      !el.disabled &&
      el.getAttribute('aria-disabled') !== 'true' &&
      !el.querySelector('.payment-loading--loading, [aria-busy="true"]');
  }

  function visibleButtons() {
    return Array.from(document.querySelectorAll(
      'button, [role="button"], input[type="submit"], input[type="button"]'
    )).filter(isVisible);
  }

  // React listens for pointer/mouse events as well as click; send the full sequence.
  function realClick(el) {
    el.scrollIntoView({ block: 'center', inline: 'center' });
    const r = el.getBoundingClientRect();
    const opts = {
      bubbles: true, cancelable: true, composed: true, button: 0,
      clientX: r.left + r.width / 2, clientY: r.top + r.height / 2,
    };
    el.dispatchEvent(new PointerEvent('pointerdown', opts));
    el.dispatchEvent(new MouseEvent('mousedown', opts));
    el.dispatchEvent(new PointerEvent('pointerup', opts));
    el.dispatchEvent(new MouseEvent('mouseup', opts));
    el.click();
  }

  // Each kind of click fires at most once per cooldown, so polling never double-submits.
  const lastClick = {};
  function clickOnce(key, el, cooldownMs = 8000) {
    if (now() - (lastClick[key] || 0) < cooldownMs) return false;
    lastClick[key] = now();
    log('click:', key, `"${textOf(el)}"`);
    realClick(el);
    return true;
  }

  // ==========================================
  // Cancellation
  // ==========================================
  class Cancelled extends Error {}
  let ctl = { cancelled: true };

  function newCtl() {
    ctl.cancelled = true;
    ctl = { cancelled: false };
    return ctl;
  }

  async function sleep(ms, c) {
    const end = now() + ms;
    while (now() < end) {
      if (c.cancelled) throw new Cancelled();
      await new Promise((r) => setTimeout(r, Math.min(100, end - now())));
    }
    if (c.cancelled) throw new Cancelled();
  }

  async function waitFor(fn, timeoutMs, c, intervalMs = 500) {
    const end = now() + timeoutMs;
    for (;;) {
      const v = fn();
      if (v) return v;
      if (now() >= end) return null;
      await sleep(intervalMs, c);
    }
  }

  // ==========================================
  // Checkout (runs in the top page and inside the checkout iframe)
  // ==========================================
  function checkoutLooksFree() {
    const raw = document.body ? document.body.innerText : '';
    if (/this is free|add it to your library/i.test(raw)) return true;
    const lines = raw.split('\n').map((l) => l.trim()).filter(Boolean);
    const i = lines.findIndex((l) => /^(order )?total\b/i.test(l));
    if (i < 0) return false;
    const seg = lines[i].replace(/^(order )?total:?/i, '').trim() || lines[i + 1] || '';
    if (/\bfree\b/i.test(seg)) return true;
    const nums = seg.match(/\d+(?:[.,]\d+)*/g);
    return !!nums && nums.every((n) => Number(n.replace(/[.,]/g, '')) === 0);
  }

  function hasVisibleCaptcha() {
    return Array.from(document.querySelectorAll(
      'iframe[src*="hcaptcha"], iframe[src*="captcha"], iframe[title*="captcha" i], [id*="captcha_challenge" i]'
    )).some(isVisible);
  }

  // One polling step. Returns what happened (or null); each click is rate-limited by clickOnce.
  // `skip` is the product page's own button, which must not be clicked again from here.
  function checkoutStep(inTop, skip) {
    const text = bodyText();
    if (SUCCESS_RE.test(text)) return 'success';
    if (REGION_RE.test(text)) return 'unavailable';
    if (REJECTED_RE.test(text)) return 'error';
    if (hasVisibleCaptcha()) return 'captcha';

    const agree = document.querySelector('input#agree');
    if (agree && !agree.checked) {
      const target = isVisible(agree) ? agree : agree.closest('label');
      if (target && clickOnce('eula-checkbox', target, 3000)) return 'eula';
    }

    const buttons = visibleButtons().filter((b) => b !== skip && isClickable(b));
    const find = (re) => buttons.find((b) => re.test(textOf(b)));
    let b;
    if ((b = find(/^(i accept|i agree|accept)$/))) return clickOnce('accept', b) ? 'accept' : null;
    if ((b = find(/^add to library$/))) return clickOnce('add-to-library', b) ? 'add' : null;
    if ((b = find(/^place order$/))) {
      if (!checkoutLooksFree()) return 'not-free';
      return clickOnce('place-order', b) ? 'order' : null;
    }
    // "Device not supported" and "This edition contains something you already have" dialogs.
    if (inTop && (b = find(/^(continue|yes, buy now)$/))) return clickOnce('continue', b, 4000) ? 'continue' : null;
    return null;
  }

  // ==========================================
  // IFRAME: checkout frame worker
  // ==========================================
  if (!isTop) {
    let last = { type: '', at: 0 };
    setInterval(() => {
      const s = loadState();
      if (!isLive(s) || s.phase !== 'checkout' || now() - (s.armedAt || 0) > ARM_MS) return;
      let type = null;
      try {
        type = checkoutStep(false);
      } catch (e) {
        log('frame step failed:', e);
      }
      if (!type || (type === last.type && now() - last.at < 5000)) return;
      last = { type, at: now() };
      GM_setValue(EVENT_KEY, { runId: s.runId, index: s.index, type, at: now() });
    }, POLL_MS);
    return;
  }

  // ==========================================
  // TOP WINDOW: controller + HUD
  // ==========================================
  const TAB_ID = (() => {
    try {
      let id = sessionStorage.getItem('epic_claimer_tab');
      if (!id) {
        id = Math.random().toString(36).slice(2);
        sessionStorage.setItem('epic_claimer_tab', id);
      }
      return id;
    } catch {
      return 'no-session-storage';
    }
  })();
  const ownsRun = (s) => isLive(s) && s.owner === TAB_ID;

  let frameEvent = null;
  GM_addValueChangeListener(EVENT_KEY, (_name, _old, ev) => { frameEvent = ev; });
  GM_addValueChangeListener(STATE_KEY, (_name, _old, s, remote) => {
    if (!remote) return;
    if (!ownsRun(s)) ctl.cancelled = true;
    hud.render(s);
  });

  function takeFrameEvent(s) {
    const ev = frameEvent;
    frameEvent = null;
    if (!ev || ev.runId !== s.runId || ev.index !== s.index || ev.at < (s.armedAt || 0)) return null;
    return ev.type;
  }

  // ------------------------------------------
  // HUD (shadow DOM so Epic's CSS can't touch it)
  // ------------------------------------------
  const RESULT_LABEL = {
    claimed: '✅ claimed',
    owned: '📚 already owned',
    'base-game': '⏭ needs base game',
    'not-free': '⏭ not free here',
    unavailable: '🚫 unavailable in region',
    failed: '❌ failed',
  };

  const hud = (() => {
    let root = null;
    let minimized = false;
    let closeTimer = null;
    const $ = (id) => root && root.getElementById(id);

    function mount() {
      if (root || !document.body) return;
      const host = document.createElement('div');
      host.id = 'epic-claimer-hud';
      host.style.cssText = 'position:fixed;right:20px;bottom:20px;z-index:2147483647;';
      root = host.attachShadow({ mode: 'open' });
      root.innerHTML = `
        <style>
          .box { font: 13px/1.4 system-ui, sans-serif; color: #e8eaed; background: rgba(18,18,26,.96);
                 border: 1px solid rgba(51,204,255,.45); border-radius: 12px; padding: 12px 14px;
                 width: 330px; box-shadow: 0 10px 30px rgba(0,0,0,.6); }
          .head { display: flex; align-items: center; justify-content: space-between; gap: 8px; }
          .title { font-weight: 700; letter-spacing: .4px; color: #33ccff; font-size: 12px; }
          .min { background: none; border: 1px solid #555; color: #bbb; border-radius: 6px; cursor: pointer; padding: 0 7px; }
          .status { margin: 8px 0; color: #cfd8dc; }
          ol { margin: 0 0 10px; padding-left: 18px; max-height: 160px; overflow: auto; }
          li { margin: 2px 0; } li.cur { color: #33ccff; } .res { color: #9aa0a6; }
          .row { display: flex; gap: 8px; }
          .row button { flex: 1; border: 0; border-radius: 8px; padding: 7px 10px; font-weight: 600; cursor: pointer; font-size: 12px; }
          #go { background: #00a152; color: #fff; }
          #stop { background: rgba(244,67,54,.25); color: #ff8a80; border: 1px solid rgba(244,67,54,.5); }
          button[disabled] { opacity: .45; cursor: default; }
          .pill { font: 600 12px system-ui, sans-serif; background: rgba(18,18,26,.92); color: #33ccff;
                  border: 1px solid rgba(51,204,255,.45); border-radius: 999px; padding: 6px 12px; cursor: pointer; }
          .hidden { display: none; }
        </style>
        <button class="pill hidden" id="pill">🎮 Epic claimer</button>
        <div class="box" id="box">
          <div class="head"><span class="title">🎮 EPIC FREE GAMES CLAIMER</span><button class="min" id="min">_</button></div>
          <div class="status" id="status">Ready.</div>
          <ol id="list"></ol>
          <div class="row"><button id="go">▶ Start</button><button id="stop">⏹ Stop</button></div>
        </div>`;
      document.body.appendChild(host);
      $('min').addEventListener('click', () => { minimized = true; render(loadState()); });
      $('pill').addEventListener('click', () => { minimized = false; render(loadState()); });
      $('go').addEventListener('click', onGo);
      $('stop').addEventListener('click', () => {
        if (closeTimer) {
          clearTimeout(closeTimer);
          closeTimer = null;
          render(loadState());
          status('Tab kept open.');
          return;
        }
        stopRun('⏹ Stopped. Press Resume to continue.');
      });
    }

    function status(msg) {
      mount();
      if ($('status')) $('status').textContent = msg;
      log(msg);
    }

    function render(s) {
      mount();
      if (!root) return;
      const mine = ownsRun(s);
      const resumable = !!s && s.status === 'stopped' && s.index < (s.queue || []).length;
      $('box').classList.toggle('hidden', minimized);
      $('pill').classList.toggle('hidden', !minimized);

      const list = $('list');
      list.replaceChildren();
      for (const [i, g] of ((s && s.queue) || []).entries()) {
        const current = mine && i === s.index && !g.result;
        const li = document.createElement('li');
        li.textContent = g.title + ' ';
        const res = document.createElement('span');
        res.className = 'res';
        res.textContent = g.result ? RESULT_LABEL[g.result] || g.result : (current ? '⏳' : '');
        li.appendChild(res);
        if (current) li.className = 'cur';
        list.appendChild(li);
      }

      $('go').textContent = resumable ? `▶ Resume (${s.index + 1}/${s.queue.length})` : '▶ Start';
      $('go').disabled = mine || !!closeTimer;
      $('stop').textContent = closeTimer ? '✋ Keep open' : '⏹ Stop';
      $('stop').disabled = !mine && !closeTimer;
      if (isLive(s) && !mine) status('A claim run is active in another tab.');
    }

    // Close the tab after a delay; the Stop button turns into "Keep open" meanwhile.
    function closeLater(ms) {
      closeTimer = setTimeout(() => window.close(), ms);
      render(loadState());
    }

    return { status, render, closeLater, minimize: () => { minimized = true; } };
  })();

  // ------------------------------------------
  // Run control
  // ------------------------------------------
  function launch() {
    const c = newCtl();
    drive(c).catch((e) => {
      if (e instanceof Cancelled) return;
      log(e);
      hud.status(`⚠️ ${e.message}`);
    });
  }

  function startRun(autoClose) {
    const s = saveState({
      runId: Math.random().toString(36).slice(2),
      owner: TAB_ID,
      status: 'running',
      phase: 'scan',
      autoClose,
      queue: [],
      index: 0,
      navigatedTo: null,
      armedAt: 0,
    });
    hud.render(s);
    launch();
  }

  function resumeRun() {
    const s = loadState();
    s.status = 'running';
    s.owner = TAB_ID;
    s.navigatedTo = null; // re-open the current game's page
    s.phase = s.queue.length ? 'game' : 'scan';
    saveState(s);
    hud.render(s);
    launch();
  }

  function stopRun(msg) {
    ctl.cancelled = true;
    const s = loadState();
    if (s && s.status === 'running') {
      s.status = 'stopped';
      saveState(s);
    }
    hud.render(s);
    hud.status(msg);
  }

  function onGo() {
    const s = loadState();
    if (ownsRun(s)) return;
    if (s && s.status === 'stopped' && s.index < (s.queue || []).length) resumeRun();
    else startRun(false);
  }

  // ------------------------------------------
  // Main state machine (re-entered after every page load)
  // ------------------------------------------
  async function drive(c) {
    const s = loadState();
    if (!ownsRun(s)) return;
    hud.render(s);

    if (location.hostname !== STORE_HOST) {
      hud.status('Waiting — finish signing in; the claimer continues on the store page.');
      return;
    }
    if (s.phase === 'scan') return scan(c, s);
    if (s.index >= s.queue.length) return finish(s);

    if (s.navigatedTo !== s.index) {
      const g = s.queue[s.index];
      s.navigatedTo = s.index;
      s.phase = 'game';
      saveState(s);
      hud.status(`Opening ${g.title}…`);
      await sleep(PACE_MS, c);
      location.assign(g.url);
      return;
    }
    if (s.phase === 'checkout') {
      // The page reloaded mid-checkout: re-read the product page to see where we are.
      s.phase = 'game';
      saveState(s);
    }
    return claimGame(c, s);
  }

  // ------------------------------------------
  // Step 1: find this week's free games
  // ------------------------------------------
  function getJson(url) {
    return new Promise((resolve, reject) => {
      GM_xmlhttpRequest({
        method: 'GET',
        url,
        timeout: 15000,
        onload: (r) => {
          if (r.status !== 200) return reject(new Error(`HTTP ${r.status}`));
          try {
            resolve(JSON.parse(r.responseText));
          } catch (e) {
            reject(e);
          }
        },
        onerror: () => reject(new Error('network error')),
        ontimeout: () => reject(new Error('timeout')),
      });
    });
  }

  function parsePromotions(data) {
    const elements = (data && data.data && data.data.Catalog && data.data.Catalog.searchStore &&
      data.data.Catalog.searchStore.elements) || [];
    const t = now();
    const games = [];
    for (const e of elements) {
      const offers = ((e.promotions && e.promotions.promotionalOffers) || [])
        .flatMap((group) => group.promotionalOffers || []);
      const freeNow = offers.some((o) =>
        o.discountSetting && o.discountSetting.discountPercentage === 0 &&
        Date.parse(o.startDate) <= t && t < Date.parse(o.endDate));
      if (!freeNow) continue;

      // urlSlug is often an internal id, so it is the last resort.
      const slug = ((e.offerMappings || [])[0] || {}).pageSlug ||
        ((((e.catalogNs || {}).mappings) || [])[0] || {}).pageSlug ||
        (e.productSlug || '').replace(/\/home$/, '') ||
        e.urlSlug;
      if (!slug) continue;
      const url = `https://${STORE_HOST}/en-US/${e.offerType === 'BUNDLE' ? 'bundles' : 'p'}/${slug}`;
      if (!games.some((g) => g.url === url)) games.push({ title: e.title || slug, url });
    }
    return games;
  }

  async function fetchPromotionGames() {
    for (const url of PROMO_URLS) {
      try {
        return parsePromotions(await getJson(url));
      } catch (e) {
        log('promotions API failed:', url, e.message);
      }
    }
    return null;
  }

  function scrapeFreeGamesPage() {
    const games = [];
    for (const a of document.querySelectorAll('a[href*="/p/"], a[href*="/bundles/"]')) {
      if (!/\bfree now\b/i.test(a.innerText || '')) continue;
      const url = new URL(a.getAttribute('href'), location.origin);
      url.search = '';
      url.hash = '';
      if (games.some((g) => g.url === url.href)) continue;
      const heading = a.querySelector('h6, h5, h4, h3');
      const title = (heading && heading.textContent.trim()) || url.pathname.split('/').pop();
      games.push({ title, url: url.href });
    }
    return games;
  }

  async function scan(c, s) {
    hud.status("Looking up this week's free games…");
    let games = await fetchPromotionGames();
    if (c.cancelled) throw new Cancelled();

    if (!games || !games.length) {
      if (!location.pathname.endsWith('/free-games') && !s.scanRedirected) {
        s.scanRedirected = true;
        saveState(s);
        location.assign(FREE_GAMES_URL);
        return;
      }
      hud.status('Promotions API gave nothing; reading the free-games page…');
      games = (await waitFor(() => {
        const found = scrapeFreeGamesPage();
        return found.length ? found : null;
      }, 15000, c)) || [];
    }

    s.queue = games.map((g) => ({ title: g.title, url: g.url, attempts: 0, result: null }));
    s.index = 0;
    s.navigatedTo = null;
    s.phase = 'game';
    saveState(s);
    log('free games:', s.queue);
    if (!s.queue.length) return finish(s);
    hud.status(`Found ${s.queue.length} free game(s).`);
    await sleep(PACE_MS, c);
    return drive(c);
  }

  // ------------------------------------------
  // Step 2: product page
  // ------------------------------------------
  function readCta() {
    for (const b of document.querySelectorAll('[data-testid="purchase-cta-button"]')) {
      const t = textOf(b);
      if (isVisible(b) && t && t !== 'loading') return { el: b, text: t };
    }
    // Fallback when the test id changes: the product's own action button by its label.
    const buttons = visibleButtons();
    const b = buttons.find((x) => /^(get|add to library)$/.test(textOf(x))) ||
      buttons.find((x) => /^(in library|owned|requires base game)$/.test(textOf(x)));
    return b ? { el: b, text: textOf(b) } : null;
  }

  // Mature-content warning in front of the product page.
  function passAgeGate() {
    if (document.querySelector('[data-testid="AgeSelect"]')) {
      hud.status('Enter your date of birth on the page — the claimer continues afterwards.');
      return;
    }
    const b = visibleButtons().filter(isClickable).find((x) => /^(continue|view product)$/.test(textOf(x)));
    if (b && /mature|content warning|ages? \d+\+|age rating/.test(bodyText())) clickOnce('age-gate', b, 4000);
  }

  async function claimGame(c, s) {
    const g = s.queue[s.index];
    const label = `${g.title} (${s.index + 1}/${s.queue.length})`;
    hud.status(`Checking ${label}…`);

    const cta = await waitFor(() => {
      passAgeGate();
      return readCta();
    }, CTA_TIMEOUT_MS, c);

    if (!cta) {
      if (REGION_RE.test(bodyText())) return advance(c, s, 'unavailable');
      return advance(c, s, 'failed', 'no purchase button found');
    }

    const t = cta.text;
    if (/in library|owned/.test(t)) return advance(c, s, g.attempts > 0 ? 'claimed' : 'owned');
    if (/requires base game/.test(t)) return advance(c, s, 'base-game');
    if (!/^(get|add to library|free)$/.test(t)) return advance(c, s, 'not-free', `button says "${t}"`);
    if (g.attempts >= MAX_ATTEMPTS) return advance(c, s, 'failed', 'checkout never completed');

    g.attempts += 1;
    s.phase = 'checkout';
    s.armedAt = now();
    saveState(s);
    frameEvent = null;

    hud.status(`Clicking "${cta.el.innerText.trim()}" for ${label}…`);
    await sleep(PACE_MS, c);
    realClick(cta.el);
    return checkout(c, s, label, cta.el);
  }

  // ------------------------------------------
  // Step 3: watch the checkout until it resolves
  // ------------------------------------------
  async function checkout(c, s, label, ctaEl) {
    const started = now();
    let deadline = started + CHECKOUT_TIMEOUT_MS;
    let heartbeat = now();
    await sleep(2000, c);

    while (now() < deadline) {
      let ev = null;
      try {
        ev = checkoutStep(true, ctaEl);
      } catch (e) {
        log('top step failed:', e);
      }
      ev = takeFrameEvent(s) || ev;

      const cta = readCta();
      if (ev === 'success' || (cta && /in library|owned/.test(cta.text))) {
        hud.status(`🎉 ${label} added to your library.`);
        await sleep(2500, c);
        return advance(c, s, 'claimed');
      }
      if (ev === 'unavailable') return advance(c, s, 'unavailable');
      if (ev === 'not-free') return advance(c, s, 'not-free', 'checkout total is not zero');
      if (ev === 'error') return advance(c, s, 'failed', 'Epic rejected the order');

      if (ev === 'captcha') {
        hud.status(`🧩 Solve the captcha for ${label} — waiting for you.`);
        deadline = Math.min(Math.max(deadline, now() + 60000), started + CHECKOUT_HARD_LIMIT_MS);
      } else if (ev === 'add' || ev === 'order') {
        hud.status(`🛒 Order submitted for ${label}, waiting for confirmation…`);
      } else if (ev) {
        hud.status(`Checkout for ${label}: ${ev}…`);
      }

      if (now() - heartbeat > 10000) {
        heartbeat = now();
        saveState(s);
      }
      await sleep(POLL_MS, c);
    }

    // No confirmation in time: reload the product page; it shows the truth ("In Library" or "Get").
    hud.status(`No confirmation for ${label}, re-checking the page…`);
    s.phase = 'game';
    saveState(s);
    await sleep(PACE_MS, c);
    location.reload();
  }

  async function advance(c, s, result, why) {
    const g = s.queue[s.index];
    g.result = result;
    log(`${g.title}: ${result}${why ? ` (${why})` : ''}`);
    s.index += 1;
    s.phase = 'game';
    s.navigatedTo = null;
    s.armedAt = 0;
    saveState(s);
    hud.render(s);
    await sleep(PACE_MS, c);
    return drive(c);
  }

  // ------------------------------------------
  // Step 4: summary
  // ------------------------------------------
  function finish(s) {
    s.status = 'done';
    s.phase = 'done';
    saveState(s);
    hud.render(s);

    const claimed = s.queue.filter((g) => g.result === 'claimed').length;
    const failed = s.queue.filter((g) => g.result === 'failed').length;
    let msg;
    if (!s.queue.length) msg = 'No free games are on offer right now.';
    else if (failed) msg = `Done: ${claimed} claimed, ${failed} failed (details in the browser console).`;
    else msg = `Done: ${claimed} claimed, nothing left to claim.`;

    if (s.autoClose && !failed) {
      hud.status(`${msg} Closing tab in ${AUTO_CLOSE_MS / 1000}s.`);
      hud.closeLater(AUTO_CLOSE_MS);
    } else {
      hud.status(msg);
    }
  }

  // ------------------------------------------
  // Entry point
  // ------------------------------------------
  function clearHash() {
    history.replaceState(null, '', location.pathname + location.search);
  }

  function init() {
    if (location.hash === STOP_HASH) {
      clearHash();
      stopRun('⏹ Claimer stopped from the command line.');
      setTimeout(() => window.close(), 2000);
      return;
    }
    if (location.hash === START_HASH) {
      clearHash();
      startRun(true);
      return;
    }

    const s = loadState();
    if (ownsRun(s)) return launch();

    // Only the store gets the idle widget; other Epic pages stay untouched unless a run is active.
    if (location.hostname !== STORE_HOST && !isLive(s)) return;
    const stopped = !!s && s.status === 'stopped';
    if (!stopped) hud.minimize();
    hud.render(s);
    if (stopped) hud.status('⏹ Stopped. Press Resume to continue.');
  }

  init();
})();
