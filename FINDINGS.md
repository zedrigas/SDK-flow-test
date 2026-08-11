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
