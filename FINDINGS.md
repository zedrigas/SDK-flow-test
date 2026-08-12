# Flow-feel findings ledger → future Swapped Connect SDK spec

Empirical results from running the REAL flows (v8+). This file is the seed of
the SDK spec hand-off for the dev team. Dates are test dates.

## Flow C — WalletConnect (Solana)

| # | Date | Wallet | Result |
|---|------|--------|--------|
| C1 | 2026-08-11 | **Phantom** (iOS, QR scan) | **Rejects the QR as "invalid".** Phantom has no wallet-side WalletConnect support for Solana. Matches the docs research (docs.phantom.com has zero WC content; WC explorer entry 404s). SDK consequence: never route Phantom users through WC. |
| C2 | 2026-08-11 | **MetaMask** (QR scan) | **Pairs over the relay, then hangs on "connecting" forever.** MM cannot satisfy a Solana-only `requiredNamespaces` proposal and does not reject it gracefully. SDK consequence: a dapp-side proposal timeout + clear per-wallet guidance is mandatory; a hung wallet looks identical to a slow one. |
| C3 | pending | **Trust Wallet** | Reference wallet — the production widget already signs `solana_signTransaction` over WC with Trust. To test next. |

Side proof from C2: the relay round trip works from an unhosted (LAN) page —
the QR carries a relay topic, not the page URL. Hosting is NOT required for
flow C. RPC is not involved until after connect (balances, broadcast).

## Flow A — injected provider

| # | Date | Context | Result |
|---|------|---------|--------|
| A1 | pending | Desktop extension (Brave) | Connect + $0.01 sign — to run supervised. |
| A2 | pending | Phantom in-app browser (needs hosting) | |

## Flow B — universal links

| # | Date | Context | Result |
|---|------|---------|--------|
| B1 | 2026-08-11 | Hermetic (simulated Phantom peer) | Full encrypted round trip green: connect payload decrypts, sign payload carries session, page broadcasts. |
| B2 | pending | Real iPhone + Phantom (needs public HTTPS hosting — redirect_link cannot be a LAN address) | |

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
