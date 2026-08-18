You are the SDK session for the NOVA flow-feel page.

Repo: this folder. Sources: `source/`. The page uses `@swapped/connect-sdk@0.0.5`. Only `source/src/real/swapped.js` may import the SDK.

## Files you may edit

- `source/src/real/swapped.js`
- `source/src/app.js` (flow / money / events only)

## Files you must not edit

- `source/src/style.css`
- `source/src/page.html` except a data-action / id you need for a handler (prefer no markup)
- Figma expected values in `source/eval/figma-spec.json`

A second session owns pixels. If a fix is CSS, write it in a one-line note and leave it.

## Product rules

- Match the hosted widget’s *behaviour*, not its iframe.
- Trusted Phantom / MetaMask must auto-connect (no extra “Log in” if the wallet is already authorized). Same as the iframe widget.
- “Already connected” is success. Adopt the live connection and open the amount screen. Never leave the user on a dead banner.
- Error copy from `ConnectSdkError.code`, never from raw gateway strings.
- Do not hardcode Phantom art or Phantom copy for other wallets.
- Exchange Pay `createOrder` amount is FIAT. Token rows come from the SDK. Eligibility is `balance.eligible`.
- Staging is the default env. Production gateway may be 403 — do not treat that as a page bug.

## Bugs to fix (PO 2026-08-18)

1. Phantom says it is already connected, but Continue never happens. Root: `WALLET_ALREADY_CONNECTED` then snapshot lookup misses (`walletId` is like `phantom:injected`, compare by provider prefix). If already connected → `onSdkConnected(live)` and open amount.
2. “Try again” is inert. Same family: CTA may have no `data-action`, or retry re-throws already-connected. Wire retry; if already connected, continue; cancel a stale pairing first (`cancelPairing`).
3. Auto-login: on session load, if the SDK reports a connected / restorable injected wallet (Phantom, MetaMask), reconnect silently (`reconnect` / snapshot) and skip the login sheet. Do not force a signature for the *connection*.
5. Token drawer Refresh does nothing. `tokens-refresh` must `forceRefetch` balances and repaint. If the handler is dead, fix the action.
6. Only Solana balances show. `getWalletBalance` / `getBalances` must show every token the SDK returns for this wallet (EVM + Solana + …). Do not filter to SOL. If the session is Solana-only, say so in a note — do not hide other chains the SDK marked eligible.
7. Coinbase tile must start OAuth immediately (`coinbase.connect()`), not wait for a second “Log in”. On `oauth:error` type `closed` / `blocked`, leave the login step, show the failed banner, enable retry. Do not stay on a spinner.
13. Exchange Pay currency dropdown: a selected row shows `$1` while USDC/USDT read `0`. Amounts must come from the SDK currency (`minAmountFiat` / `exchangeRateFiat`). `$1` must not appear unless that is the real min. Never invent balances.
15. Login ring / badge must use **this** wallet’s icon (`method.icon` / `walletIcon(provider)`). Default is not Phantom.
16. WalletConnect wallets (Binance wallet, etc.): do not leave CTA on “Connecting…”. Show the WC QR (`onUri`) with **that** wallet’s badge only — no second overlapping Phantom/Binance logo. If `connect()` hangs, the existing timeout must surface Try again.

## Verify

```bash
cd source
node --check src/app.js
# if you have a session: load it, connect Phantom twice, hit Try again, open Coinbase tile, open a WC wallet
```

Do not run Figma eval. Do not restyle. Commit only your files when a coherent unit works.
