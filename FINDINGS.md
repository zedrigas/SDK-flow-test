# Flow-feel findings ledger → future Swapped Connect SDK spec

Empirical results from running the REAL flows (v8+). This file is the seed of
the SDK spec hand-off for the dev team. Dates are test dates.

## Flow C — WalletConnect (Solana)

| # | Date | Wallet | Result |
|---|------|--------|--------|
| C1 | 2026-08-11 | **Phantom** (iOS, QR scan) | **Rejects the QR as "invalid".** Phantom has no wallet-side WalletConnect support for Solana. Matches the docs research (docs.phantom.com has zero WC content; WC explorer entry 404s). SDK consequence: never route Phantom users through WC. |
| C2 | 2026-08-11 | **MetaMask** (QR scan) | **Pairs over the relay, then hangs on "connecting" forever.** MM cannot satisfy a Solana-only `requiredNamespaces` proposal and does not reject it gracefully. SDK consequence: a dapp-side proposal timeout + clear per-wallet guidance is mandatory; a hung wallet looks identical to a slow one. |
| C3 | pending | **Trust Wallet** | Reference wallet — the production widget already signs `solana_signTransaction` over WC with Trust. To test next (from Safari, not from inside Phantom). |
| C4 | 2026-08-12 | **Phantom** (`phantom.app/ul/wc` link, real iPhone) | **Confirmed dead**: Phantom opens, then nothing — no prompt, no error. Matches C1 (no wallet-side Solana WC). The "Try Phantom (experimental)" button was REMOVED in v10 — offering a known dead end is a trap. |

Side proof from C2: the relay round trip works from an unhosted (LAN) page —
the QR carries a relay topic, not the page URL. Hosting is NOT required for
flow C. RPC is not involved until after connect (balances, broadcast).

## Flow A — injected provider

| # | Date | Context | Result |
|---|------|---------|--------|
| A1 | pending | Desktop extension (Brave) | Connect + $0.01 sign — to run supervised. |
| A2 | 2026-08-12 | Phantom in-app browser (real iPhone) | **Connect worked** (injected provider, wallet row CONNECTED, zero jumps once inside). Two UX defects found: (1) the browse deeplink opened the FULL merchant page — in real life the user faces a second merchant login inside the wallet browser; (2) the webview is a fresh browser context, so the saved private RPC was gone → "Balance read failed" toast off the public RPC. **Both fixed in v10**: browse targets the widget-only page (`?widget=1`) and carries the RPC in the `#rpc=` fragment. SDK consequence: the browse hand-off must open a widget/direct URL, never the merchant page. |

## Flow B — universal links

| # | Date | Context | Result |
|---|------|---------|--------|
| B1 | 2026-08-11 | Hermetic (simulated Phantom peer) | Full encrypted round trip green: connect payload decrypts, sign payload carries session, page broadcasts. |
| B2 | 2026-08-12 | Real iPhone — tapped INSIDE Phantom's in-app browser | **Universal link cannot open an app from inside another app's webview** — it just loaded phantom.com's "Download for mobile" fallback. Not a protocol failure; a context failure. **v10 guards it**: inside a wallet in-app browser, cards B and C are disabled with reasons, and the actions refuse with an explanatory toast. SDK consequence: wallet support is per-CONTEXT, not per-wallet — the transport matrix must branch on where the page is running. |
| B3 | pending | Real iPhone + Phantom from SAFARI (the intended context) — retest after v10 | |

## Engineering findings (already fixed in the page)

- iOS Safari synthesizes no `click` for taps on plain divs with document-level
  delegation only → direct per-element listeners + touchend fallback (v4).
- Wallet extensions (Phantom) declare a page-global `phantom`; a top-level
  `const phantom` kills the whole inline script → IIFE-wrap everything (v6).
  Any merchant inline script with top-level `phantom`/`solana`/`ethereum`
  variables dies for every wallet-extension user — direct SDK-docs material.
- web3.js silently retries RPC 429s for ~15s → `disableRetryOnRateLimit` so
  the "set a private RPC" hint surfaces immediately.
- Phantom deprecated the `signAndSendTransaction` DEEPLINK (the injected
  method stays alive) → universal-link flows must use `signTransaction` and
  broadcast client-side.
- Universal links are DEAD inside in-app webviews (field-proven 2026-08-12):
  a UL tapped inside Phantom's browser loads the fallback website instead of
  opening the app. Transport availability = f(wallet, CONTEXT), not f(wallet).
- A wallet's in-app webview is a fresh browser context: localStorage from
  Safari (saved RPC, sessions) does not carry over. Anything the widget needs
  must ride the hand-off URL itself.
- docs.phantom.com does not specify how connect/sign response params append to
  a `redirect_link` that already has a query string → the return parser
  normalizes a second `?` to `&` defensively (v10).

## v10 (2026-08-12) — iPhone field-test fixes

PO device test surfaced three context bugs; all fixed and regression-checked
(23 unit + 71 browser checks + 24-shot AI eval):
- **Widget-only mode** `?widget=1`: flow A's browse deeplink now opens the
  deposit widget as the whole page (like the production widget's direct URL
  mode) — never the merchant casino. The mode survives Phantom redirect round
  trips, closing any sheet lands on picker/wallet (never a blank page), and
  the saved RPC rides the hand-off in the `#rpc=` fragment.
- **In-Phantom guards**: inside Phantom's in-app browser, flow cards B and C
  are disabled with reasons; taps refuse with an explanatory toast instead of
  dumping the user on phantom.com or a silent Phantom open.
- **Phantom WC button removed** (C4). Flow C mobile now offers Trust only.

### v10 adversarial review (same day) — 12 confirmed findings

A 15-agent adversarial review (3 lenses × refutation pass) confirmed 12 real
defects in the first v10 cut. Fixed and regression-checked:
- **Injected cancel could hide a real spend**: Phantom BROADCASTS on approval;
  the depositing back-chevron now refuses on the injected path ("finish it in
  Phantom") instead of showing "cancelled" over a live prompt. WC cancel stays
  (the page controls the broadcast there) and now also clears the busy latch.
- **Reset did not invalidate an in-flight deposit** (stale busy/run/pendingTx
  latched the UI shut for up to 120s). Reset now kills the run outright.
- **Injection races**: all in-Phantom guards took a synchronous snapshot while
  provider injection is async — a fast user could reach a mis-guarded chooser.
  One boot-primed 1.5s poll now settles the answer; the chooser re-renders its
  hints when injection lands; flows A/B/C await the settled answer.
- **iPadOS masquerades as desktop Safari** (no iPad UA token since iPadOS 13):
  every mobile gate misfired on real iPads — all three flows dead-ended.
  `maxTouchPoints > 1` + Macintosh now counts as mobile.
- **Tap system**: a suppressed native click still advanced the dedupe clock
  (next tap swallowed); href-less `<a>` CTAs (summary Confirm in injected/WC
  mode) were exempt from the iOS tap fallback. Both fixed.
- **Build guard gap**: the secret-leak guard missed URL-ENCODED embeds of .env
  values — exactly the `#rpc=https%3A%2F%2F…` shape. Now checked both ways.

Documented, accepted for a demo (NOT acceptable in the production SDK):
- The **private RPC URL rides in the flow-A browse link**. If Phantom is
  installed, iOS hands the link to the app without a network hit; if NOT
  installed (or UL interception fails), phantom.app's server sees the encoded
  token in the path. Accepted: QA-only rotatable QuickNode token, and the
  PO's test device has Phantom. SDK consequence: config must reach the widget
  server-side, never through user-visible URLs.
- The `#rpc=` boot handler accepts any https URL from any inbound link — a
  crafted link can plant a lying/censoring RPC (it can NOT alter or steal a
  signed transfer; recipient and amount are fixed before signing). Mitigation:
  the save toast now names the RPC host. SDK consequence: never accept
  infrastructure endpoints from URL input.
- Reverting the RPC in Safari does not propagate to Phantom's webview copy
  (separate localStorage) — stale until a new hand-off link is opened.
- A NON-Phantom in-app browser (Telegram, Instagram) still gets a dead-end
  browse link on flow A — no reliable detection exists; the hand-off sheet now
  carries an escape hint ("open this page in Safari"). SDK consequence: the
  SDK needs an in-app-browser escape hatch, not a heuristic.
- `isInPhantomBrowser()` trusts `isPhantom` — an impostor provider shimming
  `window.phantom.solana` would be treated as Phantom. Demo-acceptable; the
  SDK must fingerprint providers properly.

## v9 (2026-08-12) — scenario closure + 1:1 fidelity sweep

Built: the Summary review modal (Figma 6389:109817) now sits before EVERY sign
(From/To, amount, live fee breakdown; the deeplink CTA is the real universal
link); a Transaction-failed sheet with per-class reasons (rejected /
insufficient funds / expired blockhash / timeouts / dead WC session) that keeps
the Solscan link whenever a signature was broadcast; picker search filters for
real; details sheet restored 1:1 (token icon, Recipient Address + working
copy, external-link icon); desktop game-card hover overlays + the Enhanced-RTP
badge; QR caption per the Figma block.

Fixed defects (all found by audit, all regression-checked): a broadcast
signature was DISCARDED on slow confirmation; deeplink sign-rejection dumped
to the homepage and leaked a stale pending amount into the next transaction;
no insufficient-funds pre-check (empty wallets got sign prompts destined to
fail); blockhash expiry was never detected; WC session death mid-sign waited
the full 90s; injected sign had no timeout; toasts rendered UNDER modal
backdrops (z-index); double-tap races on flow entry.

## v11 (2026-08-12) — 1:1 production-widget journey

PO field verdict on v10: transports work, but the SEQUENCE is not the product.
v11 rebuilds the journey to mirror the real widget exactly (Figma flow
6411-88878 + the QA repo's verified production copy):

**picker → "Log in with Phantom" → "Enter amount to deposit" → "Deposit $X" →
"Confirm Transaction" → waiting → success/failed.**

- The A/B/C transport chooser is GONE from the user path. The transport is a
  consequence of context, exactly as the SDK will do it: injected provider →
  direct connect (desktop extension / Phantom's in-app browser); mobile
  Safari → the connect universal link IS the "Log in" button, with a secondary
  "or continue inside the Phantom app" hand-off; desktop without extension →
  Browser|Mobile tabs, the Mobile tab QR hands this page to the phone. A
  TRANSPORT override (Auto/A/B/C) lives in the notes drawer for engineers.
- **The in-app hand-off now resumes at the amount screen** (`?widget=1&step=amount`
  + eager connect; a declined/gesture-gated connect leaves a "Log in" retry).
  The picker never re-appears — the PO's headline complaint.
- Production copy everywhere: "Please complete your login to continue." /
  "Click log in to continue with Phantom" / "Log in failed. Please click log
  in to try again" (banner, replaces the toast+chooser) / amount "Deposit" +
  Max + CTA "Continue"→"Deposit $X" (skeletal + disabled until connected, the
  real widget's pre-connect behavior) / "Click|Tap to see breakdown" /
  "Confirm Transaction" on every transport / waiting "Confirm transaction in
  your wallet app — Waiting for a signature — Please confirm your transaction
  on Phantom|Trust".
- New "Select supported token" drawer from the token pill: REAL SOL + USDC
  balances, Refresh; USDC is display-only (PO decision) — tapping it says so.
- Trust Wallet is now a first-class picker tile → "Log in with Trust Wallet"
  (the WalletConnect transport behind the production surface; QR on desktop,
  "Log in" link on mobile). Trust logo exported from the Figma source.
- Money layer untouched: cap, fixed recipient, funds pre-check, sig-before-
  confirm, cancel refusal, reset invalidation, injection priming, iPad UA.
- Disconnect (PO ask): the CONNECTED wallet row opens a drawer with a
  "Disconnect Wallet" action that tears down the ACTIVE transport (injected
  disconnect / WC session end / universal-link session wipe) and clears state.

### v11 adversarial review — 14 + 6 findings fixed, 2 rounds

Two review rounds (15 + 2 agents) on the restructured journey. Round-1 fixed
14 confirmed defects; round-2 refuted the fixes and found 6 more. All fixed and
regression-checked (~140 browser checks):
- **CRITICAL — reset could hide a real spend**: tapping the demobar Reset while
  a Phantom prompt was open bumped the run token; approving after that
  broadcast real SOL that the page silently discarded (no record, no screen).
  Reset AND cancel are now REFUSED while any wallet prompt is open; a broadcast
  signature is ALWAYS recorded.
- **No injected sign timeout**: a 120s page-side timeout abandoned a live
  Phantom prompt and offered "try again" — a double-spend, since Phantom
  broadcasts on approval. The wait is now un-timed (the user resolves it in the
  wallet); after 30s the screen names the only safe escape (reload).
- **Stale-sign fingerprint guard**: a Phantom sign sheet approved late (after
  the summary was rebuilt at a new amount) is rejected by a message-bytes
  fingerprint — never broadcast, never recorded with the wrong amount.
- **WC session-death deadlock**: a session_delete mid-signature latched the
  spinner forever (the delete handler bumped the run token that the in-flight
  rejection needed). The handler now steps aside mid-sign; the rejection routes
  to the failed sheet and clears the phase.
- **Record-before-broadcast**: for the deeplink and WalletConnect page-broadcast
  paths, the signature is extracted from the signed bytes and recorded BEFORE
  `sendRawTransaction`, so an ingest-then-error still shows the Solscan link
  instead of "nothing was sent".
- **Race tokens**: late connects, late WC pairing approvals, and abandoned QR
  pairings after reset/back/disconnect/transport-switch are all dropped; a
  superseded pairing is politely disconnected; "Generate a fresh QR" and
  re-entry render a fresh code instead of a stale dead-end.
- **Create New Transaction** keeps the wallet connected (was wired to the full
  demo reset, which tore the wallet down).

### Documented divergences from the Figma flow board (6411-88878), not gaps
- No inline "Min. amount" validation banner: amounts are fixed preset chips
  within the $0.25 cap, so no free-input min/max error can occur.
- No separate "Transaction was cancelled" banner ON the confirm sheet: a
  rejection toasts and returns to the amount screen (a UX divergence, not a
  money issue). Candidate polish if the PO wants strict parity.
- Breakdown is an inline expander (matches the annotated Summary node
  6389:109817), not the board's separate Breakdown sub-sheet.
- No dedicated failed-/cancelled-details sheet: the failed screen carries the
  reason + Solscan link (the on-chain detail) instead.
- Amount is chip/Max-driven, not a typable field (the tiny-amounts model).

### Deliberate divergences from Figma (documented, not bugs)
- NOVA brand replaces Stake everywhere (PO decision, day one).
- Real content replaces sample content: tiny amounts ($0.01–$0.10, $0.25 cap)
  instead of $10–$500 chips; USDC + SOL balance rows instead of USDT×3;
  Phantom/WalletConnect connected row instead of Coinbase; live fees/slots.
- Added, not in Figma: Solscan link on success; Slot row in details; the demo
  toolbar, flow chooser, notes drawer + RPC field; connect hand-off sheet; WC
  sheet (borrows the Summary QR block language); failure-reason line.
- Removed vs Figma: the deprecated signAndSendTransaction deeplink (Phantom
  deprecated it); Swapped Fee row (no Swapped backend in the loop); the "Wait
  for second confirmation" and "Swapping X to Y" screens (N/A to a single-sig
  direct SOL transfer); mobile chrome is an adaptation (no mobile Figma frame
  exists). (v11 note: the token selector EXISTS now — USDC display-only.)

## v12 (2026-08-13) — the "alive page" restyle (Stake-1:1 look & feel)

PO verdict on the shell: "looks like a dead site — no hovers." Root cause
found and confirmed: the page had exactly ONE `:hover` rule and a
same-specificity override later in the cascade killed it at every viewport —
shipped in v9 as "hover overlays" and never caught, because the screenshot
rubric cannot see interaction states. v12 makes the merchant shell feel like
the real stake.com and adds a permanent guard so an inert page can never pass
the gate again.

- **File split**: the merchant shell now lives in `src/merchant.html` +
  `src/merchant.css` (emitted last, wins ties); proven a pure refactor by a
  pixel-identical before/after build at both breakpoints.
- **Typography**: Mulish (embedded latin variable woff2, SIL OFL) replaces the
  system stack as the Proxima Nova look-alike; Inter (per Figma §6) on the
  card overlays. +105 KB total.
- **Interaction layer** (authored to convention — the Figma capture has no
  interaction states): hover brightness/washes on every control, gated to
  `(hover:hover) and (pointer:fine)`; all press states transitioned (150/200ms);
  `:focus-visible` rings + full keyboard path (tabindex + Enter/Space dispatch);
  `prefers-reduced-motion` collapses it all.
- **Hover overlay rebuilt 1:1** (SPEC §6/§7): solid #1475e1 fill over the art,
  capitalized title top-left, centered play triangle, proper-case provider
  per game, grey expand button; sports variant = title + play only, full-card.
  Cascade bug fixed at the root (base rule specificity lowered on purpose).
- **Feel-real features**: live search over both shelves (blue focus border,
  honest empty state); carousel arrows + edge fades (desktop); sidebar row
  selection + Casino/Sports tab state (syncs the search category label);
  Load More (clones 8 cards at zero page-weight, then honestly disables);
  Providers strip (10 wordmark chips); footer (4 link columns, language chip,
  © NOVA demo line, 18+ roundel, live SOL ticker — hidden whenever the price
  is the HIGH money-safety estimate, so a fallback never displays as real).
- **Fidelity corrections from sampling the Figma shot** through the dim model:
  balance pill is the translucent black well `rgba(0,0,0,.32)` (the spec's
  `#395565` was its one low-confidence guess); sidebar `#13232d` and top bar
  `#1a2e39` confirmed exact.
- **Permanent guard**: `checks/interaction-states.mjs` — 48 hermetic checks
  (overlay reveal + geometry per variant, computed hover styles, transition
  presence, Tab ring + Enter activation, search/carousel/Load More behavior,
  reduced-motion + mobile opt-outs, zero page errors, zero external requests).
  Runs in the gate before verify.mjs. Eval grew to 36 shots (hover states,
  filtered search, footer) with rubric criteria that FAIL an inert page.

Known accepted artifact (PO-flagged): several sports/CS2 art PNGs from the
Figma capture carry burned-in Stake sponsor marks (jerseys/watermarks). The
authored UI is NOVA-only; swapping that art needs new source images.

## v13 (2026-08-14) — auto-reconnect / session persistence

PO field report: the Stake UI looks connected, but every flow made them
re-sign the CONNECTION; in the production widget the wallet stays/auto-connects
~99% of the time, so a returning user signs only TRANSACTIONS. Root cause: on
every fresh page load the demo restored only the deeplink session — injected
(extension / in-app browser) and WalletConnect started disconnected.

- **Sign the connection ONCE, then it sticks.** boot now auto-reconnects the
  LAST-used transport (localStorage `nova-last-method`): injected via
  `connect({onlyIfTrusted:true})` (silent — no prompt for a trusted origin);
  WalletConnect via `restoreSession()` (sign-client's own persistence, expiry-
  filtered); universal links keep their token as before. Only transactions
  need signing on later visits.
- **Durable disconnect.** Explicit Disconnect and the demo Reset clear the
  marker; auto-reconnect is MARKER-GATED, so a disconnect sticks even though
  Phantom's `disconnect()` does NOT revoke origin trust (the wallet-adapter
  footgun). Phantom `disconnect`/`accountChanged` events keep state honest.

Adversarial review (2 rounds, 8 confirmed findings, final round clean):
- injected reconnect was un-gated (disconnect not durable) → marker-gated;
- boot eager connect lacked a run-token guard (a late reconnect could clobber
  a manual connect / wipe the WC topic) → connectRun/wcPairingRun guards on
  BOTH the injected and WC boot paths, re-checked after the async handshake;
- `accountChanged` could swap the account UNDER a built tx → an account switch
  now invalidates the pending tx and kicks back to the amount screen, and
  summary-confirm refuses to sign a tx whose fee-payer ≠ the connected account;
- a switch seen mid-deposit is deferred and re-applied after it settles;
- unguarded `localStorage` in the wallet-event callbacks (throws in a
  storage-denied iframe) → all storage access guarded;
- WC `restoreSession` could adopt an expired/dead session → expiry filter (a
  still-dead-wallet session is caught by the 90s sign timeout → failed sheet);
- `onSessionDelete` left a stale `wc` marker → cleared on session death.

Verified: 24 unit + 168 hermetic browser checks (incl. reload-stays-connected,
trusted-origin-boots-connected, disconnect-stays-disconnected, account-switch-
never-signs-stale) + interaction gate + 37-shot AI eval — all green.

## v14 (2026-08-14) — dark-widget pixel parity (Figma 6411) + the parity judge

PO verdict on v11-13: the journey works, but the screens were MY interpretation
in the Stake skin, "not like the ones we have on Figma". Root cause: v9's
"skip dark widget screens" + v11's "match Stake styling" made 6411 a
sequence/copy reference only. PO decision (final): the widget journey sheets
copy the DARK Swapped-widget design (6411) 1:1 — every screen has a real
Figma frame. The merchant shell, the wallet modal, and the disconnect drawer
stay Stake-styled (merchant surface).

- **10 sheets reskinned** to the dark widget (`data-skin="wg"`, scoped CSS;
  #181818/#202020, violet #4608e3 CTAs, Satoshi — the palette and font were
  already embedded, unused, since the widget-sim days). Sheet width pinned to
  the Figma frame's 400px on desktop.
- **Amount screen rebuilt per frame 88879**: bordered card, "Deposit" label,
  TYPABLE $ input (masked, 2 decimals), Max pill (= the $0.25 cap), ⇅ SOL
  equivalent line, SOL/fiat chip, chips row below the card, and the inline
  error banner per frame 88928 ("Maximum deposit is $0.25") — closes the old
  "no inline validation" divergence. One `setAmount()` funnel keeps the CTA
  gate, the cap banner, and the equivalents in agreement; the money layer's
  cap-throw remains the backstop.
- **Summary/breakdown/waiting are true OVERLAYS** above the dimmed amount
  screen (frames 88891/88910/89001), with the "Transaction was cancelled"
  banner (88900) on WC cancel. Figma copy wins where it differed from the
  production POM: "Deposit 0.000050 SOL" titles, "Confirm transaction",
  "View breakdown", "Make new transaction", "Transaction details".
- **Login family per frames 89098/89019/89120/89111**: Browser|Mobile pill
  toggle, the browser-extension illustration (exported from Figma at 2x),
  INVERTED page-URL QR with the Phantom badge centered (89019), the circled
  badge + arc (89120), failure banner above the CTA. The Trust WC QR stays
  black-on-white deliberately — wallet in-app scanners are less reliable with
  inverted codes (scannability beats fidelity there; documented).
- **Picker per frame 88950**: white tiles on the dark sheet, centered title,
  "Installed" badge on Phantom when a provider is detected, search copy
  "Search for exchange or wallet".
- **The parity judge + auto-fix loop** (the PO's "eval agent so I don't
  re-prompt"): `npm run eval:parity` captures each of 18 screen-states and a
  per-screen headless-Claude judge compares BUILD vs the exact Figma frame
  render (fetched via MCP into eval/reference/figma/), returning falsifiable
  delta lists; `npm run eval:parity:loop` feeds deltas to fixer agents and
  re-judges until clean (≤4 rounds). `npm run check:figma` (32 deterministic
  computed-style checks incl. Stake-survivor and :root-bleed tripwires) gates
  every round — the v12 lesson that screenshots alone grade too kindly.
- **Final parity outcome (2026-08-16): 18/18 screens pass** — 13 machine-judged
  over 7 rounds + 5 recorded human verdicts (login-browser, login-qr-tabs,
  login-failed, failed, details), each judged side-by-side against the exact
  frame render after the judge CLI repeatedly process-errored or flip-flopped
  on those specific screens (details' chat-button chrome got opposite verdicts
  in consecutive rounds — the frame settled it: both header buttons are flat
  filled circles). Verdicts + rationale live in eval/parity-report.json.
- **Hard-won pipeline lessons** (now baked in as guards):
  - The judge prompt's FROZEN contracts now BAN static/sample data — a fixer
    once hardcoded "0.001 BTC / = $100" onto the real-money failed sheet to
    match the frame's placeholder content.
  - eval/figma-refs.json notes now document the backdrop corner-bleed capture
    artifact (every screen), the real-QR-vs-decorative-modules swap, and the
    failed screen's pre-broadcast state (no details link without a signature).
  - `filter: invert(1)` on an svg ROOT computes but never paints in headless
    Chromium — the login QR's inversion is baked into the svg fills instead
    (also sturdier on real devices).
  - `sips`-cropped PNGs drop the sRGB chunk but keep gAMA+cHRM, which Chromium
    color-manages visibly darker (#181818 → #111); the login-browser
    illustration (a 1:1 crop of frame 89098 itself) is re-encoded sRGB-only.
  - The login sheet's twin auto-margin centering means margin-top on a variant
    breaks EVERY ring variant — vertical biasing goes on the wrap's padding,
    scoped with :has() to the banner variant.
- **Behavioral eval: 37/37** after repointing 6 stale rubric items to the
  frames (amount CTA stays "Continue"; breakdown = Amount/Network/Withdrawal
  fee, no Total row; waiting = "Confirm transaction" + confirm-on-Phantom
  body; details fee label; "Deposit address"; login-failed CTA reads
  "Log in"; noext Continue is full violet). The $0 amount state keeps a
  visibly dimmed CTA — the fixer's frame-88928 opacity override is now
  scoped to the over-cap banner state only. Journey drivers updated to the
  frame reality: the breakdown sub-sheet hides the CTA (collapse first, as a
  real user must), and success/failed have no header close — the exit is
  "Make new transaction" → amount → back (which lands on the wallet modal).

## v15 (2026-08-17) — Stake palette, always-on RPC, mobile geometry parity

Three PO findings from field use, each traced to a root cause rather than patched at the symptom.

**1. The widget looked foreign inside Stake.** v14 copied the Figma dark frames exactly (#181818 sheets, WHITE picker tiles) and dropped them onto a navy Stake page. PO decision: keep the Figma *geometry*, wear the *merchant's* colours. The dark ladder maps 1:1 onto Stake's surface ladder, so the retheme is a token flip plus the literals that bypassed the tokens:

| token | v14 | v15 | merchant source |
|---|---|---|---|
| `--wg-bg` | #181818 | #1a2e39 | `--m-bg` |
| `--wg-panel` | #202020 | #203743 | `--m-card` |
| `--wg-chip` | #282828 | #273a45 | `--wl-tile` |
| `--wg-border` | #404040 | #395565 | `--m-line` |
| `--wg-violet` → `--wg-cta` | #4608e3 | `var(--wl-blue)` | Stake blue #1475e1 |
| `--wg-body` / `--wg-helper` / `--wg-label` | #f5f5f5 / #b2b2b2 / #9f9f9f | #f7fafc / #9fbed0 / #97adbd | `--m-text` / `--m-text2` |

`--wg-cta` READS `--wl-blue` instead of copying its value, so the widget tracks Stake's blue automatically — and the FROZEN "never mutate the shared token" rule still holds. White survives in exactly three places, each because the ground is coloured, not because it was missed: CTA labels (on blue), banner text (on red), and the QR cards (scanner reliability).

**Judge consequence:** the parity judge compares against the DARK frames, so without an allowance it would fail all 15 non-bestEffort screens on hue alone. `swapsAllowed` now carries a palette entry instructing the judge to grade geometry/spacing/type/structure only and to route every colour observation to `ignored`. The picker note that said "HUMAN-VERIFIED: ALL tiles are WHITE" was **deleted** — it had become actively wrong, and a stale allowance is worse than none.

**Survivor tripwire repaired.** `checks/figma-tokens.mjs` proved `#wl-wallet` was still Stake by asserting its background is `rgb(26,46,57)` — which is now the widget's background too, so the check could no longer tell the two apart. Replaced with the structural invariant that actually holds: the survivors carry **no `data-skin` attribute** and keep Mulish.

**2. RPC needed manual pasting.** The paste-once mechanism already existed; what was missing was a fallback worth having and any visibility into which endpoint served a call.

*Probed 2026-08-17* — keyless public Solana RPC is largely gone. drpc (400), blockeden (402), ankr (403), onfinality (429), omniatech (521), rpcpool (403) and alchemy-demo (429) rejected every method. Two survive: `api.mainnet-beta.solana.com` (all seven methods) and `solana-rpc.publicnode.com` (all but `getTokenAccountsByOwner`, which times out consistently — 30s × 3).

So the chain is `[private?, api.mainnet-beta, publicnode]` with `withRpc()` rotating on 429/403/timeout/network. Two deliberate limits: `broadcast()` is **never** wrapped (a send that fails after the network accepted it must surface, not be retried onto another endpoint — that is how you double-spend), and `balances()` degrades to SOL-only when the serving endpoint cannot read token accounts, returning `usdc: null` ("could not read") as distinct from `0` ("holds none") so the UI can say which it means. A demobar chip now reports **RPC private / RPC public** (amber when public) and opens the RPC field on click, and a "Copy setup link" button builds the `#rpc=` link for the next device — the fragment never reaches a server and the key never enters the repo or the bundle.

**3. Sizing was off on the phone — and this is the interesting one.** The 400×514 frame contract lived *only* inside `@media (min-width: 1024px)`. Below that, every widget sheet was a full-bleed, content-height bottom sheet capped at `--sheet-w` 640px. The token drawer measured **248px against a 514px frame** — under half the design.

The parity pipeline could not see it: 15 of 18 screens were captured desktop-only, `figma-tokens` ran at 1470×900 only, `verify.mjs` asserted no geometry at all, and the `ctx` field in `figma-refs.json` was documentation no script read. **The Figma data was always exact; only one viewport was ever compared against it.** That is the transferable lesson — a parity gate is only as wide as its capture matrix, and a single-viewport gate silently certifies every other viewport.

Fixes: `max-width: 400px` and `min-height: min(514px, 88svh)` now apply at every width (the `min()` clamp stops the floor fighting `max-height` on short phones; overlays are excluded on purpose so the dimmed amount screen still shows above them). `88%`/`86vh` became `88svh`/`86dvh` so an iOS URL-bar collapse cannot resize a sheet mid-flow. Two v14 mobile hacks were retired as superseded rather than left to fight the new rules: the `#wl-failed` 520px body floor and the login `104px/100px` magic offsets — both were fits for an unfloored sheet. `visualViewport` now publishes `--kb-inset` so the software keyboard lifts the sheet instead of covering the amount input.

Enforcement: `figma-tokens.mjs` runs **two passes** (desktop 1470×900, mobile 393×852 = the PO's iPhone 15) with real geometry assertions — width `min(400, viewport)`, height ≥ 514, floor-flush anchoring, top-only radius, overlay/amount bottom-edge alignment, additive safe-area padding. 82 assertions. A negative test confirmed the gate is not vacuous: removing the floor rule fails it with `sheet height 310 >= frame 514` and `drawer height 248 >= frame 514` — precisely the defect the PO reported. Three `@mobile` parity screens (amount, tokens, summary) now judge phone-width layout against the same frames with bottom-sheet chrome allowed.

**Caught by the gates, not by review:** adding the RPC chip to the demobar pushed the reset button off a 390px screen. The behavioural eval's mobile journey failed on it. The bar now drops decorative elements first (brand wordmark ≤560px, dev counters ≤430px) and keeps the chip and controls reachable.

## v16 (2026-08-17) — the REAL `@swapped/connect-sdk`, and a blocking upstream defect

The demo now runs on the real SDK instead of a simulation. The SDK is **headless** — it renders nothing, owns no styling, and exposes typed state plus formatters — so the Stake-styled Figma screens became the real front-end rather than being replaced by an iframe. That is the whole reason the v15 restyle survived the swap.

**Working against the live production API** (session `b2540cb5…`, merchant "OpenSea"): session load and view state, 23 payment methods with their own CDN logos, 15 available wallets with per-provider transport metadata, 37 destination wallets with per-coin `minAmount`. The picker is now driven entirely by `paymentMethods.get()`, and the "Installed" badge is real detection via `wallets.getAvailable()` rather than a hardcoded label.

### BLOCKER — `connect.swapped.com/gateway` serves no gateway document

Every wallet operation in the SDK (`connect`, `getBalances`, `signMessage`, `sendTransaction`, and therefore all deposits) is routed through a hidden 0×0 iframe at `{widgetBaseUrl}/gateway`. The host waits for that frame to post `{channel:'swapped-sdk', type:'event', name:'ready'}` before transferring a `MessagePort`; until then, every call is queued.

That event never arrives. Measured directly, mounting the iframe exactly as `SdkGateway` does:

| probe | result |
|---|---|
| messages from a `swapped` origin in 30s | **0** |
| `GET connect.swapped.com/gateway` | `200`, no Cloudflare challenge, body = **"Error No session ID found"** |
| `GET connect.swapped.com/gateway?sessionId=<id>` | `200`, renders the **full widget UI** ("Select exchange or wallet…") |
| `GET staging.swapped.app/gateway` | `200`, near-empty page |
| `wallets.connect({provider:'trust'})` | never resolves (45s, transport pinned to `walletconnect`) |

So `/gateway` is not a route — it falls through to the widget SPA, which has no idea it is meant to be a gateway and never speaks the handshake protocol.

**Two defects, one symptom.** The deployment is missing the `/gateway` document. And `SdkGateway.ensureReady()` has **no timeout of its own**, so the failure mode is an infinite silent hang rather than an error — the popup path has a 15s `READY_TIMEOUT_MS`, but the iframe path has none. Even after the route is fixed, that missing deadline will turn any future gateway outage into a dead spinner for every user.

Cloudflare was the suspected cause and is **not** guilty here: the gateway URL returns 200 with no `cf-mitigated` header, and a real browser passes cleanly through the session-creation redirect.

**Our mitigation** (upstream fix still required): a `gatewayReady()` preflight mounts the same frame and resolves false after 8s, so the login screen states the real cause immediately instead of spinning; and every gateway-backed call carries a 12s deadline. `transfer.submit()` is deliberately exempt — a submit that has already reached the network must surface its own outcome, because racing it against a timer invites a double-send on retry.

### Other SDK observations for the dev team

- `wss://connect-api.swapped.com/socket.io` returns **403**, so the realtime channel (which carries `transaction:updated`) does not connect from a browser origin. Deposit status would need polling.
- `react >= 18` is a package-level peer dependency even though the vanilla core never imports React; `ethers` and `@wagmi/core` are declared dependencies with **zero** imports anywhere in `dist/`. All three inflate installs for non-React consumers.
- The session-creation URL is signature-bound over the **full** parameter set — trimming even one `walletAddress` entry yields `UNAUTHORIZED_ACCESS / invalid_signature`. Worth documenting for integrators.
- Transport truth table from `getAvailable()`: Phantom and Coinbase are deep-link only (`supportsWalletConnect: false`); the other 13 are WalletConnect. A desktop integration therefore cannot connect Phantom without its extension.

### v16 Figma parity — 21 screens, and what the judge actually caught

Full pass: **16/21 machine-passed**, plus 3 `bestEffort` screens excluded from the gate and 2 human-judged (see below). The palette allowance worked exactly as intended — across 21 screens the judge raised **zero** colour deltas, so the Stake retheme was graded on geometry alone.

Two real defects it found, both mine, both worth recording because they are the kind a human review misses:

1. **The token network badge was wrong in shape and in scope.** I built a rounded text pill reading "SO" on every row. The frame has a small *circle* overlapping the icon's bottom-right — and only on **multi-chain contract tokens**. Native coins (SOL, BTC, LTC, ETH) are clean. The SDK already draws that line: `tokenAddress === null` means native, so the badge is now data-driven rather than decoration applied uniformly.
2. **`summary@mobile` never captured.** My mobile driver called `shotOverlay(page, '#wl-summary', name)` when the signature is `(page, name)` — it wrote a file literally named `#wl-summary.png` and the screen reported `capture.missing`. A silent argument-order bug that only a per-screen gate would surface.

**Final tally: 18/21 machine-passed + 3 human-judged; 3 `bestEffort` variants carry documented deltas and never gate.** After the two fixes above, `login-mobile` and `summary@mobile` were re-judged GREEN by machine — the latter confirming the argument-order bug was the whole cause.

**Human-judged (the judge CLI process-errors on these specific screens, as it did in v14 — 4 attempts each):**
- `login-qr-tabs` — matches the frame 1:1: back chevron, "Log in to Phantom", Browser|Mobile pills with Mobile selected, inverted QR with the centred Phantom badge, correct caption. PASS.
- `tokens` — after the badge correction: SOL (native) renders clean, USDC (contract token) carries the small circular badge at the icon's bottom-right, ~37% of icon diameter. Both of the judge's specific objections are answered. PASS.
- `waiting` — matches 6411:89001: dimmed amount screen behind, overlay with back chevron + "Confirm transaction" + chat icon, ring badge, "Please confirm your transaction on Phantom". PASS.

**Tooling defect fixed during the run:** `parity-capture.mjs` used to `rmSync` the shots directory on a full capture, which silently sabotages any judge reading those files concurrently — every screen returns `capture.missing` and reads exactly like a mass regression. It cost one full 21-screen pass. Shots are now overwritten in place.

**Behavioural eval (37 shots): 2 failures, both proven non-defects.**
- `21-error-rpc-down` — the v15 fallback chain makes a single endpoint failure a non-event by design; the rubric still demanded the old error toast, so correct behaviour was being graded as a fault.
- `32-hover-game-card` — the judge read the centred play triangle as inline text after the title. Measured rather than eyeballed: computed `position: absolute`, **dx = 0** from the overlay centre. It only looks inline because the title wraps to three lines and ends beside that point. Rubric corrected in both cases rather than changing working code.

---

## v16.1 (2026-08-18) — the SDK, implemented against the shipped types

The PO supplied the two official vendor guides (React, 182 pp; Core, 134 pp).
Auditing the v16 code against them — and against the `.d.ts` files actually
shipped in `node_modules` — found **38 defects**, with a single root cause:

> `src/real/swapped.js` (the adapter) was written against the real types and was
> sound. The journey layer in `src/app.js` was written against a **guessed** API
> surface. Almost every field name it read does not exist.

None of this was visible to the existing gates, because those gates drive the
**simulation**. The SDK path had no contracts at all. It does now
(`npm run check:sdk`, 40 contracts, fake client shaped from the `.d.ts`).

### The eight that made a real payment impossible

| # | Defect | What the user got |
|---|---|---|
| 1 | `#sum-cta` never received a `data-action` | **Confirm was inert. The payment was unreachable** — `submitSdk()` was dead code |
| 2 | `getBalances()` returns `WalletBalancesForWallet[]`, unwrapped as a token list | every row rendered `undefined`; plans resolved with `network: undefined` |
| 3 | `setConnected(addr, wallet)` — arguments swapped | address shown as `"phantom"`, and a Solana RPC read then wiped the SDK balances |
| 4 | `requires_retry` matched none of `/fail\|reject\|error/` | **a transfer that did NOT happen was shown as success** |
| 5 | `flow:'unavailable'` plans were truthy at all five gates | Confirm reachable with `destination: null` |
| 6 | empty `connect()` result thrown as an error | the normal deep-link hand-off rendered a red failure banner |
| 7 | all six transfer-status keys invented (0 of 10 real values handled) | deposit overlay frozen on one message for the whole transfer |
| 8 | `fiatBalance` / `fiatPrice` do not exist (`fiatValue` / `exchangeRate` do) | every fiat figure `$0.00`; **typing a USD amount cleared the crypto amount, so Continue could never enable** |

### Correctness of the money numbers

- **Eligibility now comes from the SDK.** `balance.eligible` already encodes
  "session destination match OR a swap/bridge route exists". The hand-rolled
  network comparison was wrong in *both* directions: it hid every token that
  could have swapped, and offered tokens whose network matched but whose coin
  had no destination — which is what produced the `unavailable` plans above.
- **Token identity, not index.** The drawer and its click handler each sorted
  independently and addressed rows by position. They agreed only because the
  sort key was `undefined` for every row; the moment that was fixed, the indices
  would diverge and **the user would pay with a token they did not select**.
- **Destination is `plan.destination.address`.** It was re-derived from the
  session's wallet list by matching *network only* — ignoring `coin`, and unable
  to express a swap/bridge target at all. `copy-recipient` was worse: it copied
  the hardcoded Solana demo constant, which would lose a user's funds.
- Quote fields are `networkFee{amount,symbol}` + `protocolFeeFiat`; there is no
  `quote.fees.total`, and `#sum-receive`/`#sum-fee`/`#sum-to` are not in the DOM,
  so all three writes were silent no-ops.
- Amount validation is `transfer.validateAmount({plan, amount})` — it does not
  throw, and it knows the **source-denominated** minimum for swap/bridge, which
  the hand-rolled check could not compute. It deliberately does *not* check
  balance, so that one check stays ours.

### Two defects found while verifying the audit, not in it

- **The legacy Phantom-injection detector repainted the SDK login sheet.** It
  fires up to 1.5s after the sheet opens and called `renderLoginVariant()`
  unconditionally — clobbering whatever the SDK had put there: the deep-link
  hand-off copy, a WalletConnect QR, or a connect error banner. Now gated on
  `!SDK_MODE`. This would have hit real users on the mobile deep-link path.
- **Opening the wallet modal in SDK mode fired the whole simulation stack** — a
  Solana RPC balance read plus a Jupiter price fetch — and then overwrote the
  SDK's balances with its own. Now repaints from SDK state instead.

Also fixed: markup carried hardcoded Solana. `#amt-token` had no `.sym` element
(so the chosen token could never be named) and the code swapped only the bottom
layer of the two-layer SOL mark, leaving the SOL overlay painted on top; the
equivalence line's ` SOL` was a **static text node**, so a USDC deposit read
"12.500000 SOL". Balance rows with no logo emitted `<img src="">`, which makes
the browser re-request the page itself.

### Exchange Pay and Coinbase — a third of the picker was unreachable

Of 23 live payment methods, `exchange_pay` (Binance/KuCoin/Gate/Bybit/OKX/Krak)
and `exchange_oauth` (Coinbase) were dead-ended with `demoToast('Not wired yet')`.
The classifier itself was the bug: a hardcoded `WALLET_PROVIDERS` set that
*included* `binance`, `okx`, `bybit`, `kraken` and `coinbase`, so those tiles
were routed into a wallet connect that could never succeed. Routing is now on
the method's own SDK `type` (a 7-value enum). Both flows are built:

- **Exchange Pay is push-driven** — `createOrder()` wires its own websocket, so
  nothing polls. Checkout is `checkout.{url, mobileUrl, qr}` where `qr` is either
  a payload to encode *or* a pre-rendered image. Expiry is an **event**, never a
  status (the status union is only `PENDING | PAY_SUCCESS | AWAITING_PROVIDER_FUNDS`).
  `canClose` is false for Bybit and OKX, so the cancel affordance is conditional.
- **Coinbase is promise-first** — the whole withdrawal state machine, 2FA
  included, is the *resolved value* of `startWithdrawal`/`confirmWithdrawal`. A
  **wrong 2FA code resolves to `requires2fa` again rather than throwing**, so the
  error path is a return value, not a `catch`.
- **There is no resend call.** Grepping all of `dist/`, `.js` included: no
  `resend`, no `requestCode`. The 30s cooldown gates `startWithdrawal` **only**,
  never `confirmWithdrawal`. The UI therefore offers re-enter or cancel, and
  deliberately does not render a resend button we cannot back.

Both screens are **functional but plainly styled and carry `data-unreviewed="1"`**
— per PO decision, their visual design is held for supplied Figma node ids
rather than invented, and they are excluded from parity scoring.

### Upstream: the production wallet gateway (unchanged, still blocking)

Every privileged wallet call routes through a hidden `{widgetBaseUrl}/gateway`
iframe, and `ensureReady()` has **no timeout**, so a bad gateway hangs the wallet
path forever with no symptom. The production failure is **not stable**:

| when | `staging.swapped.app/gateway` | `connect.swapped.com/gateway` |
|---|---|---|
| 2026-08-16 | emits `{channel:'swapped-sdk',name:'ready'}` | `200`, no `cf-mitigated`, then silent 30s |
| 2026-08-18 | `200`, real gateway HTML (24.5 KB) | **`403` Cloudflare "Just a moment…"** (5.7 KB) |

So the earlier "Cloudflare is innocent" call was too strong — production *is*
behind bot management on this route and staging is not. Either way no `ready`
ever arrives. Wallet deposits are provable on **staging only**; Exchange Pay and
Coinbase are plain REST/websocket and are unaffected. The SDK has a typed code
for this (`WALLET_GATEWAY_NOT_READY`) which our own watchdog now raises.

### Minor, worth knowing

The merchant shell's footer price ticker calls Jupiter, and **both endpoints are
currently dead** — `lite-api.jup.ag/price/v2` returns 404 and `price.jup.ag`
fails DNS. The ticker degrades correctly (hides itself), so this is cosmetic,
but the footer price has silently not worked for some time.

### Gates

`verify` (174) · `check` (unit) · `check:ui` · `check:figma` (82 × 2 viewports) ·
**`check:sdk` (40, new)** — all green. The SDK contracts run against a fake
client injected through `window.__SWAPPED_FACTORY`, with payload shapes copied
from the `.d.ts`, so a wrong field name cannot pass. The dependency is now
pinned exactly (`0.0.4`, was `^0.0.4`).

---

## v17 (2026-08-18) — the official docs arrive; 48 more defects, and the first LIVE session

The PO supplied the official docs site (connect-sdk-docs.pages.dev) and a real
staging session (merchant "Kalshi", 27 payment methods, 37 destination wallets).
A seven-section docs audit — each section read by one agent, each finding then
adversarially verified against the code — confirmed **48 defects** on top of the
v16.1 work. All are fixed. The contract suite grew from 42 to **60 checks**.

### What the live session proved (real SDK, zero mocks, zero spend)

- Staging gateway READY; **15 available wallets** through the privileged channel.
- A **real WalletConnect wallet connected**: the SDK emitted a genuine `wc:`
  pairing URI, our headless peer approved it, `getConnections()` reported
  `connected`, and **7 real balances loaded** with every field the journey
  layer reads (`fiatValue`, `exchangeRate`, `formatted.*`) present.
- **USDC-on-Base came back `eligible: true` although the session has no Base
  wallet** — a live swap route, and the definitive proof that eligibility must
  come from `balance.eligible`, never from matching networks by hand.
- The probe lives in the tests repo: `hunt/nova-sdk-live-staging.spec.ts`
  (@external; run its three tests one at a time — staging's Cloudflare rate
  limit refuses back-to-back boots and fakes an outage).

### The biggest structural finds

1. **A session that was not `active` at load rendered NO screen.** The one
   function that draws terminal states was only reachable from an event
   subscription that was only wired for active sessions. A completed, expired,
   failed, rejected or maintenance link showed the normal payment page with a
   tiny chip as the only clue. Now every `SessionViewType` renders a real
   screen, expired/failed carry a **"Start a new payment"** CTA
   (`restartSession()` — the docs' recovery, where our copy used to say "go get
   a new link"), and every payment entry point re-checks `sessionPayable()`.
2. **The picker deduped by provider.** On the live session six providers are
   TWO products each (binance/okx/bybit/robinhood wallet+pay, coinbase/kraken
   wallet+OAuth) — dedupe deleted one flow per provider, with arbitrary API
   ordering deciding which one survived. Tiles are now keyed by the method's
   unique `id`, labelled by `uniqueShortName` ("Binance wallet" vs "Binance
   Pay"), and unroutable types (exchange_api, exchange_proxy, cash_app, and
   exchange_pay rows outside the SDK's provider union) get no tile at all.
3. **Exchange Pay charged the wrong amount by design**: `createOrder` takes a
   FIAT USD string, and the code passed `minAmountCrypto` — and never asked the
   user for an amount at all. There is now an amount step (prefilled from the
   session's own ask when present), validated against `minAmountFiat`, and the
   QR payload is rendered as a real QR through the same encoder the
   WalletConnect login uses. Abandoning checkout now closes the order at the
   exchange; re-entering resumes a live one.
4. **The receipt crashed after real money moved**: `from`/`to`/`destination` on
   the completed summary are ADDRESS OBJECTS (`{address, formatted, network,
   explorerUrl}`), and passing them to `formatAddress()` threw. Amounts and
   fees carry `.currency`, not `.symbol`. The receipt now renders from the
   objects' own formatted strings inside a try/catch.
5. **Swap/bridge could submit without the required quote** — Confirm was armed
   before pricing resolved and stayed armed when it failed. Now: direct arms
   immediately (quote optional), swap/bridge arm only when the quote lands, a
   failed quote leaves a "Pricing failed — try again" re-price CTA, and
   submit hard-refuses a quoteless non-direct plan.
6. **Coinbase**: `getNetworks` was fed the display *name* where the account
   *id* belongs; a pending 2FA was stranded if the sheet closed (now resumed
   from `getActiveWithdrawal()`, and backing out cancels it); `above_spendable`
   now leaves the CTA live so the SDK's documented auto-adjust path
   (`onAmountAdjusted`) can run; funding tokens (swappable balances) feed the
   max and the withdrawal request; the cooldown disables the Start CTA and
   never the 2FA step.
7. **Connect-path corrections from the docs**: `popupIfUnavailable: true` on
   every injected connect (the privileged connect runs inside the hidden
   gateway iframe, which cannot always see an extension the page can — without
   the flag such wallets hard-fail beside their own "Installed" badge);
   transport comes from `AvailableWallet.transports` instead of a hand-rolled
   guess; desktop-without-extension deep-link wallets get a scan-with-your-
   phone QR instead of a doomed connect; `force` rides only with WalletConnect.
8. **Events that were never subscribed**: `wallets:connected` (the ONLY way a
   deep-link hand-off completes), `wallets:chainChanged` (a network switch now
   invalidates plan+quote like an account switch), `wallets:error` (failures
   outside a pending promise were silent), pairing-URI clearing (a dead QR no
   longer stays on screen), `coinbase:withdrawalCompleted`, and a snapshot
   reconcile at load so a restored user is not sent to reconnect a wallet they
   never left — silently, without force-opening the deposit sheet at boot.
9. **A failed retry() no longer destroys the retry path.** The transfer can be
   ON-CHAIN with only Swapped's registration missing; the "Finish transfer" CTA
   survives every failure except the SDK's own "nothing left to retry", the
   transaction hash stays visible for support, and `restartSession` refuses to
   run over a pending retry rather than orphaning a sent transaction.

Formatting now goes through the SDK everywhere (`formatTokenAmount`,
`formatCurrencyAmount`, fee symbols that can legitimately be `USD`), and
`formatted.fiatValue` is treated as the bare number string it is.

### Also fixed while verifying

`paintMerchantBalances` had a `$`/`$$` typo that threw on every paint after the
formatter change; the version pin moved to v17 across the page, `verify.mjs`,
and the tests repo's iOS smoke.

### Gates

`verify` (174) · `check` · `check:ui` · `check:figma` (82×2) · **`check:sdk`
(60)** — all green. The fake client's shapes were corrected to the shipped ones
in the same pass (flat `getBalancesForWallet`, address objects, `.currency`,
dual-typed method fixture), so the tests that used to mask these defects now
enforce their absence.

---

## v17.1 (2026-08-18) — the Stake wallet-modal pair, to the 6389 frames

Ran CONCURRENTLY with the v17 docs pass above, in a second session on the same
working tree — the two streams interleaved in app.js/page.html/verify.mjs, and
each side's gate runs fought the other's over the harness ports (see
Housekeeping below). The final tree carries both; all gates re-ran green on the
merged state.

The PO supplied the two merchant-modal frames the program was missing: the
**Wallet modal** (6389:112208, 500×683 @1x) and the merchant's own **Deposit**
screen (6389:111416, 500×870 @1x). The deposit screen did not exist at all —
the Wallet modal's Deposit button jumped straight into the widget picker,
which is not the journey those frames show.

### The new `#wl-mdeposit` sheet (1:1 with 6389:111416)

Crypto | Local Currency segment pills in an `rgba(0,0,0,.32)` well (4px pad,
999px pills, 52px tall); Currency (USDT) and Network (ETH) selects on
`#395565` with the frame's exact shadows; the Address group — a bordered text
well (42–90px, 9px pad, the frame's own `0x234e…153e` placeholder) plus
refresh and copy buttons split by a 1px `#b6d2e3` divider; a REAL scannable
QR of that address on a white 8px-pad card; the 16px sentence-case "Or"
divider (the Wallet modal's OR is 12px uppercase — they genuinely differ in
the frames); the connected-row + Use Other Wallet card on `#203743`; and the
Credited / 2 Confirmations footer. New token: `--wl-sub2: #b6d2e3`.

Navigation now follows the Stake journey: **Wallet → Deposit → (connected
row = resume the widget with this wallet | Use Other Wallet = method
picker)**. The manual crypto path is display-only — copy really copies, the
QR really scans, everything else answers with a toast. The old Deposit-button
shortcut (straight to amount when connected) lives on as the deposit screen's
connected row. Every journey driver (verify, captures, token checks —
23 call sites) gained the extra hop.

### Wallet-modal polish (6389:112208)

- The CONNECTED pill now renders in **Inter** — the frame's one non-Proxima
  element (`font/style/inter`, 6389:112320).
- The connected row's chevron: the committed `wl-chevron-right.svg` asset is
  actually a DOWN chevron, so the row rendered ⌄ where the frame shows ›.
  The frame itself draws a down-chevron rotated -90° (6389:112321) — the CSS
  now does the same.
- `.wl-sheet`'s desktop cap moved `min(86dvh,780px)` → `min(88dvh,870px)`:
  the deposit modal is 870 tall on the frame's 1004 page, and the old cap
  clipped it into a scroll.

### Gates grown

- `check:figma`: +13 mdeposit checks × 2 viewports (surface colors, segment
  geometry, the `#b6d2e3` sub-label, white QR card, a real QR present, the
  "Or"-divider distinction, no `data-skin` bleed).
- Parity loop: **m-wallet + m-deposit** join `figma-refs.json` as desktop
  screens, captured CONNECTED at the Figma page's own 1470×1004 viewport
  (88dvh of a 900-tall window clips the 870 modal). These are MERCHANT
  surfaces — the v15 palette swap does NOT apply; colours must match the
  frames. Refs fetched at 1x into `reference/figma/m-{wallet,deposit}.png`.
  **Both PASS the judge with zero deltas** (parity-capture 23/23; the ignored
  list is exactly the documented content swaps: two real balance rows for
  three USDT rows, the demo's connected wallet for Coinbase, a real QR for
  the decorative one).
- Merged-tree gate tally: `verify` (177) · `check` · `check:ui` ·
  `check:figma` (108×2) · `check:sdk` (70 lines incl. per-pass error checks)
  — all green.

### Housekeeping — two sessions, one tree

Two concurrent Claude sessions worked this repo today (this UI pass and the
v17 docs pass). Symptoms to recognize next time: `listen EADDRINUSE` on the
harness ports (8931/8934/8951), a gate run against the OTHER session's
mid-edit tree producing phantom one-off failures (one sdk-journey red that a
clean solo re-run could not reproduce), and "file modified on disk" warnings
mid-edit. If a gate dies at `EADDRINUSE`, check `lsof -ti :8930`–`:8952` for
the other session's LIVE run before killing anything — and prefer one session
per repo.

### v17 addendum — final polish before deploy

- The success sheet's SOL coin and "View on Solscan" label were baked into the
  markup (the Figma frame is SOL-specific). Both now follow the ACTUAL paid
  token and network on every flow — wallet, exchange pay, Coinbase, and a
  session already completed at load. A token with no art hides the coin: no
  icon beats the wrong icon on a money screen.
- The amount screen now shows the minimum PROACTIVELY ("Minimum deposit:
  X SYM", informational styling) before the user types a bad number — the SDK's
  BELOW_MIN message still handles the after-the-fact case.
- `transfer.prefetchTransferCurrencies()` is fired right after connect, so the
  first resolve/quote answers from a warm cache.
- Known, deliberate limits (upstream, filed as DEV-TEAM-ASKS §13): kraken
  OAuth, htx, btcturk, bitfinex and cash-app exist on the session but have NO
  SDK module — the picker excludes them rather than dead-ending; robinhood's
  exchange_pay row is outside the SDK's ExchangePayProvider union. The Coinbase
  funding-token TOGGLE UI is deferred with the other un-designed screens
  (defaults are computed and passed); multi-wallet display is simplified to the
  active connection.

### v17.1 addendum (2026-08-18, PO field feedback)

The Wallet modal's CONNECTED row used to open the disconnect drawer. PO:
"if I click this it should push me through the flow, not disconnect." Both
modals' connected rows now share one action (`connected-continue` → the
widget amount screen), and disconnect moved to a small underlined
**Disconnect** link tucked under the row (opens the existing confirm
drawer; documented in figma-refs as a demo addition). Gates re-ran green:
verify 178 · check · check:ui · check:figma · check:sdk · parity m-wallet +
m-deposit both pass.

---

## v18 (2026-08-18) — SDK 0.0.5, Figma-true exchange screens, and the simulation is GONE

Three things landed at once, all PO-directed: the 11 supplied Figma frames for
Exchange Pay and Coinbase are implemented 1:1 (Stake palette per the standing
mapping), **SDK 0.0.5** (published this morning) replaced 0.0.4, and — the big
one — **the entire pre-SDK simulation was removed**. The PO's field test caught
the old simulation still reachable on live v17: the wallet amount screen showed
the demo's $0.25 cap and priced $100 at 0.25 SOL, because the sim's dead price
feed fell back to its $400 money-safety constant. That class of bug is now
impossible: there is exactly one engine in the page.

### SDK 0.0.5 — a breaking release, ported same-day

`transfer.resolve→getPlan`, `tryResolveDirect→getPlanSync`,
`getBalancesForWallet→getWalletBalance`, `getSnapshot→getConnectionState`,
`getAvailable()` now fetches payment methods itself, **`connect()` resolves ONE
connection or `null`** (null = deep-link hand-off), quotes carry
`estimatedTimeSeconds`, and `AvailableWallet.qrScanTarget` (`camera` |
`wallet-app`) now states which QR a desktop host must render — replacing our
hand-rolled deep-link heuristic with the SDK's own answer.

### The design's structure, now the page's structure

The frames revealed the flows REUSE the wallet screens' visual system:
- **Exchange Pay**: amount-first (big `$`, currency chip, `$10–$500` quick
  chips — 3033:3819) → the **Select-crypto overlay** with live search and
  min-amount rows (3138:28812, exactly the amount/token-drawer relationship
  the wallet flow has) → a From/To checkout with breakdown, a real QR with the
  provider badge, and **"Continue in browser"** (3008:575) → the shared
  depositing overlay with the provider's icon in the ring (3105:8006).
- **Coinbase**: the login-ring step (3006:2321) → the wallet amount CARD
  (Deposit label, Max pill, ⇅ equivalence, balance chip — 3033:11244), fiat
  input converting through `exchangeRate` → a **confirm overlay with the 2FA
  code inline** (3819:77692) → shared depositing (3819:79739) → shared success.
- **Insufficient balance** (3275:56458) is now a real overlay raised whenever a
  connected source holds nothing the session accepts — wallet and Coinbase both.
- The wallet amount screen's quick chips adopted the design ladder
  (`$10/$20/$50/$100/$500`); the `$0.01–$0.10` demo chips are gone.

### What the purge removed

The fake Phantom provider, the deeplink/universal-link machine, the simulated
WalletConnect pairing (a QR renderer is all that survives), the Solana tx
builder/broadcaster and its $0.25 cap, the RPC chain + drawer controls +
`#rpc=` fragment, the auto-reconnect marker, the legacy login variants
(Browser/Mobile tabs), the dead Jupiter price ticker, the static picker tiles
(replaced by an honest "No payment session" state), the static token rows, and
the manual-deposit placeholder address (now the session's REAL first
destination). The bundle dropped **2.08 MB → 1.41 MB**.

### Gates, rebuilt to match

`checks/sdk-journey.mjs` (now ~70 contracts) is the journey gate, driven by the
shared fake client `eval/fake-sdk.mjs` whose shapes are copied from the 0.0.5
`.d.ts`. `verify.mjs` was rewritten to page-level contracts (boot, session
intake, no-session honesty, widget mode, external-request zero). The Figma
token gate walks the SDK journey. `checks/real-units.mjs` now unit-tests the
session parser, env inference, error narrowing and the QR renderer. The
interaction gate asserts the price ticker is GONE. Simulation-only parity
screens are retired (recorded in eval/figma-refs.json); the 8 new frames are
registered with SDK-mode capture drivers.

Live proof re-run on this exact build: staging gateway ready, real WalletConnect
pairing approved by the test peer, real balances with correct fiat — green.

### v18 addendum — parity pipeline on the fake SDK, and one more real bug

- The capture pipeline now drives ALL 28 parity screens through the shared fake
  SDK client (20 rewired + the 8 new frames). Three screens are RETIRED with
  the simulation, recorded in `eval/figma-refs.json`: the tabbed no-extension
  login (`login-browser`, `login-qr-tabs`) and the deeplink resting screen
  (`login-mobile`) — their UI states no longer exist on an SDK-only page.
- Rewiring the captures caught a real bug: **`showOverlay()` hard-coded the
  wallet amount sheet as the dimmed under-layer**, so the new Select-crypto,
  Coinbase-confirm and insufficient-balance overlays dimmed the WRONG screen.
  It now dims whatever sheet the user actually came from.
- The 36-shot behavioral eval's simulation cases are retired (noted in
  eval/rubric.md) pending an SDK-mode rewrite; the parity eval is the live
  visual gate meanwhile.
