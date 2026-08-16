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
