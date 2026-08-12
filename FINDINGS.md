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

### Deliberate divergences from Figma (documented, not bugs)
- NOVA brand replaces Stake everywhere (PO decision, day one).
- Real content replaces sample content: tiny amounts ($0.01–$0.10, $0.25 cap)
  instead of $10–$500 chips; USDC + SOL balance rows instead of USDT×3;
  Phantom/WalletConnect connected row instead of Coinbase; live fees/slots.
- Added, not in Figma: Solscan link on success; Slot row in details; the demo
  toolbar, flow chooser, notes drawer + RPC field; connect hand-off sheet; WC
  sheet (borrows the Summary QR block language); failure-reason line.
- Removed vs Figma: the deprecated signAndSendTransaction deeplink (Phantom
  deprecated it); Swapped Fee row (no Swapped backend in the loop); token-chip
  chevron (no token selector in scope); mobile chrome is an adaptation (no
  mobile Figma frame exists).
