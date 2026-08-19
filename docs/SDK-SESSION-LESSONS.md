# SDK session lessons — NOVA flow-feel (written 2026-08-19, source: the v19→v19.6 session)

Brief for a fresh Claude taking over the SDK side of this page. Everything below
happened in one real session; nothing is speculative. The page is
`source/src/app.js` + `source/src/real/swapped.js` on `@swapped/connect-sdk@0.0.5`;
a SEPARATE session owns pixels (`style.css`/`page.html`) — coordinate via
`HANDOFF-*.md` files at `source/` root and `PROMPT-SDK.md` / `PROMPT-FRONTEND.md`.

## 1. What shipped (v19.6 behaviour)

- Already-connected wallet tile → straight to the amount screen (snapshot pre-check
  in `sdkConnect`, provider-prefix matcher `connProvider()`, needsReconnect rows get
  ONE silent `reconnect()`). Boot silently adopts restorable wallets.
- Try again works on every failure path; retry `cancelPairing()`s first; camera-QR
  and pairing-cancelled paths arm the CTA instead of leaving a dead "Connecting…".
- Injected connects pass `namespaces: meta.injectedNamespaces` → Phantom shows
  EVM+BTC+SOL balances, not Solana-only.
- Coinbase: tile click auto-opens OAuth; in-sheet state machine `cbLoginState`
  (idle/waiting/closed/blocked/timeout); never a toast-only failure.
- xpay select-crypto right column = the TYPED fiat and its conversion, or nothing.
- Login ring badge + QR mark = this wallet's icon or none; 28s no-URI watchdog.
- Wallet decline → summary + "Transaction was cancelled" banner (never the failed
  sheet, never a raw gateway string). ⇅ flips fiat⇄token entry. Token drawer
  Refresh shows "Refreshing…". `tokenConverts()` gates the default-token pick and
  the amount card against garbage staging rates.
- Behavior gate = the real-Phantom zero-spend probe
  (`tests repo: tests/e2e-money/nova-page-phantom-probe.spec.ts`), green 13.3s vs
  v19.6. The fake-SDK behavior tests are DELETED (PO order); `eval/reference-client.mjs`
  is a screen stager for the visual pipeline only.

## 2. Where I was stuck longest

**The dead amount card (3+ probe cycles, most of a day).** Symptom: Continue never
enabled, token chip `$0.00`, equivalence `0`. Wrong attempts, in order:
1. Chased a console 429 — it was the SDK's own Sentry telemetry endpoint. Noise.
2. Suspected a stale build twice (root `index.html` vs `source/index.html`, the
   python server's docroot). Real, but not the bug.
3. Fixed the default-token pick to prefer "rated" rows — insufficient, because a
   GARBAGE rate (staging returns them) passes `rate > 0` yet truncates $1 to zero.
4. Added a no-rate banner — it never showed, because the rate was present-but-garbage.

What finally worked: **stop inferring from screenshots.** Exposed the page state as
`window.__NOVA_SDK` under `?debug=1` and made the probe dump it on failure. One dump
ended four theories: it showed a healthy SOL rate under a dead card, a PLAN whose
source was BONK (a superseded token's slow resolve had overwritten the picked
token's plan → `resolvePlan` run token), and `$1` in the input with `sdk.amount`
empty (typed BEFORE rate enrichment; nothing re-derived it → the
`wallets:balancesUpdated` re-derive). The previous day's green run was timing luck.

Smaller sinkholes: trace.zip was corrupt on every failed probe run (never rely on
it — instrument the spec output); Playwright body-attachments are a rabbit hole to
extract from reports; the money-config probe MUST run from the tests repo root
(`playwright.money.config.ts does not exist` = wrong cwd — hit twice); the tests
repo style gate wants its suppression comment ON the offending line.

## 3. PO corrections, verbatim, and what I had done wrong

- "cuz i saw you get 404'dd" — I had built docs coverage from fallback sources
  after 404s without clearly flagging it; the canonical docs domain was stale and
  only the preview deploy worked.
- "am i able to test SDK implementation yet or we're waiting for something?" —
  twice I left readiness unclear; the PO could not tell if they were blocked.
- "On this session lets focus on the SDK part making it work" (+ 5 field bugs) —
  my 119 fake-SDK checks were green while the real page failed on icons, dead
  tiles, wallet switching, Coinbase, and sendTransaction. Fakes hid field bugs.
- "so youre testing something?" — my probe restarts were invisible; narrate live
  runs.
- "delete everything related to fake sdk test" — after the field bugs the PO
  ordered the fake behavior tests gone. I had presented keeping them as an option.
- "what does it mean it loses machine gate?" — my question used jargon; the PO
  had to ask what I meant. Plain words.
- "can we rename it to like reference?" — the surviving stager still carried the
  word "fake" everywhere (filename, export, comments).
- "i see on the front end v19" — I shipped v19.1→v19.5 without ever bumping the
  visible version label; the PO could not tell which build they were testing.
  The header now names the exact build and the device-smoke pin asserts it.
- "also commit evertyhign from all sessions and upload teh latest one so i can
  test manually" — I had been holding work uncommitted mid-flow.
- The PROMPT-SDK.md brief itself was a correction: my v19.1 already-connected fix
  compared `walletId === provider` (walletIds are `provider:transport`, so it
  never matched), and my Coinbase handling was second-click + toasts, not the
  widget's auto-connect + in-sheet states.

## 4. SDK 0.0.5 traps — do not re-learn

- **Already-connected**: `connect()` THROWS `WALLET_ALREADY_CONNECTED` (never
  returns the existing row). Snapshot rows have `walletId: 'provider:transport'`
  (`phantom:injected`, `metamask:wc:<topic>`) and a NULLABLE `provider` field —
  match with `connProvider()` (provider ?? walletId prefix), never equality.
  Adopt only `status === 'connected'`; "pay/sign only when connected".
- **reconnect()**: no-args is SILENT iframe re-hydration. `{force:true}` opens the
  Swapped popup for `requiresPopup` connections (trust) — never call it at boot or
  outside a user gesture.
- **Coinbase**: `coinbase.connect()` opens the popup ITSELF → must be reached
  within the tile click's user activation. Blocked/closed/timeout do NOT throw —
  connect resolves `false` and the reason arrives ONLY via the `oauth:error`
  event, discriminant `payload.error.type` ∈ 'blocked'|'closed'|'timeout' (nested,
  not top-level). `OAUTH_POPUP_*` error codes exist in the enum but 0.0.5 never
  throws them — do not branch on them. The `.spinning` class was a no-op: the CSS
  arc animates unconditionally, `#cb-arc.hidden` IS the spinner switch.
- **Banner id**: the Coinbase LOGIN banner is `#cb-login-banner` (text span
  `#cb-banner-text`). It was born as a duplicate `#cb-banner`, which hijacked the
  amount step's `$('#cb-banner')` in cbValidate. Never reintroduce the duplicate.
- **xpay right column**: `minAmountFiat`/`minAmountCrypto` are LIMITS, not money.
  Right column = typed fiat + `xpayCryptoFor()` conversion
  (`exchangeRateFiat || minFiat/minCrypto`, fiat-per-crypto); typed 0 → no column.
- **WC QR**: one QR; the mark inside it comes from `meta.icon || walletIcon()` or
  is OMITTED — never fall back to `#login-badge-img.src` (its markup default is
  Phantom art → wrong logo in other wallets' QRs). Hide ring+badge when the URI
  lands. `qrScanTarget`: 'camera' = phone-camera browse link (phantom/coinbase),
  'wallet-app' = wc: URI (everything else). 28s no-URI watchdog → cancelPairing +
  Try again.
- **Production gateway 403s** (`connect.swapped.com/gateway`) — upstream, not a
  page bug. Staging is the default env; wallet flows are provable on staging only.
- **Balances arrive RATE-LESS first**, enrich via `wallets:balancesUpdated`. A $
  typed before enrichment converts to nothing and stays dead unless re-derived on
  the enrichment event. Staging also returns garbage rates whose $1 conversion
  truncates to 0 — `tokenConverts()` is the gate, `rate > 0` is not enough.
- **Async races**: `resolvePlan` carries a run token (a superseded token's plan
  landed late and overwrote the picked token's). Multichain grants make
  `accountsChanged`/`chainChanged` fire late — they must never clobber an explicit
  token pick (`sdk.tokenAuto` guards it).

## 5. What the frontend session must not break

IDs and attributes JS depends on:
- `#cb-login-banner` (+ its `span`), `#cb-connect-cta` (JS toggles `.disabled`),
  `#cb-arc` (JS toggles `hidden`), `#cb-connect .wl-progress-txt` (JS rewrites),
  `#cb-banner` stays the AMOUNT step's banner.
- `#login-cta` (JS rewires text + `data-action`), `#login-badge-img` (JS sets or
  REMOVES `src` — src-less img must stay CSS-hidden), `#login-qr`,
  `#login-qr-caption`, `#login-banner`, `#login-body`.
- `.amt-equiv[data-action="amt-flip"]` with role/tabindex; `#amt-usd`, `#amt-sol`,
  `#amt-sym`, `#amt-fiat`, `#amt-banner`, `#amt-cta`, `#sum-banner`.
- `.tok-refresh` — JS swaps its trailing TEXT NODE to "Refreshing…"; keep the
  svg+text structure.
- `.db-ver` names the exact build; the tests-repo device smoke asserts its text.

Copy that is state (tests/probe assert on it): "Confirm Coinbase connection in a
new tab", "Window was closed before completion", "Click log in to continue with
Coinbase", "Transaction was cancelled", "Scan with {wallet} on your phone",
"You declined the transaction in your wallet."

Contracts from the joint passes: empty data slots stay EMPTY (CSS skeleton — no
literal 0/—/…), well backgrounds are CSS-owned (JS paints only the img), one QR
mark maximum on the login sheet.

## 6. Unfinished on the SDK side (honest)

- The Coinbase state machine is code-and-gate verified only; the real popup dance
  (open OAuth, close it, blocked-popup branch) has not been walked with a live
  Coinbase login.
- The WC/Binance QR path and the 28s watchdog are not re-verified live post-fix
  (needs a WC wallet or a blackholed relay).
- The staging session returned a swap plan carrying
  `issues: [NO_SESSION_WALLET]`; `planUnusable()` only fails a plan on
  flow/destination, so a "usable" plan with a blocking issue may still arm the
  CTA. Unresolved — needs a live check on what submit does with such a plan.
- `tokens-refresh` was hardened, but the PO's original "does nothing" (tap never
  reaching the handler) was never reproduced or excluded live.
- `.db-ver` discipline: the smoke pin (`tests/core/flowfeel-ios.spec.ts`) is
  synced to the live header ('v20.1', 2026-08-19). Standing hazard: the v20.2
  build shipped still LABELED v20.1 — every deploy must bump the header, and
  every bump must re-sync the pin, or the device smoke fails on the label.
- Parked from the visual session's PASS-3 note (PO to schedule): data-URI icon
  artwork for `eval/reference-client.mjs` fixtures (3 grok screens); the
  Coinbase parity-capture drivers are stale against auto-connect (they click
  `cb-connect`, which connected fixtures now skip); optionally surface the
  2FA no-resend copy in the wrong-code error path.
- Multichain event storms (late accountsChanged/chainChanged) are guarded but not
  stress-tested against a real multi-namespace approval.
