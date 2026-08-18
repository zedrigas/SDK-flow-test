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
7. Coinbase must match the **hosted widget**, not a toast.
   - Tile click → call `coinbase.connect()` at once. Do not wait for a second “Log in”.
   - While the popup is open (`oauth:popupOpenChanged` `isOpen`): body **“Confirm the Coinbase connection in a new tab”**. Disable the CTA. Widget copy (shot `docs/field-shots/04-coinbase-widget-waiting.png`).
   - User closes the popup (`oauth:error` type `closed`): stay on the login step. Show the red banner **“Window was closed before completion”**. Enable **Log in**. Stop the spinner. Widget shot `03-coinbase-closed-or-prompt.png`.
   - Popup blocked: stay on login, enable retry, say the browser blocked the window.
   - Do **not** leave NOVA on “Please complete your login to continue.” with a spinning Log in and no window (`05-coinbase-nova-idle.png`). That is the current bug.
   - `oauth:error` must paint the sheet. A `demoToast` alone is not enough.
13. Exchange Pay select-crypto (`renderXpayCurrencies`, shot `02-xpay-select-min.png`): USDC and USDT show **Min. amount $1** and **$1 / 0 USDC**. That pair is wrong.
   - This is **not** a wallet. There is no user USDC holding. Do not paint `minAmountFiat` as a balance on the right.
   - Left helper: `Min. amount: $` + SDK `minAmountFiat` (keep `$1` only if the SDK min is `$1`).
   - Right column: crypto of the **typed** fiat via `exchangeRateFiat` (same math as `xpayPaintChip`). If typed fiat is 0, show `0` / hide — do not reuse the min as cash.
   - Never show `$1` next to `0 USDC`. If the right fiat is `$1`, the crypto must be the $1 conversion (about `1 USDC`), not `0`.
   - Today the row uses `minAmountFiat` twice and raw `minAmountCrypto` on the right. That is the bug.
15. Login ring / badge must use **this** wallet’s icon (`method.icon` / `walletIcon(provider)`). Default is not Phantom.
16. WalletConnect (Binance wallet, shot `01-binance-qr.png`):
   - Target: one QR, that wallet’s mark **in** the QR, caption **“Scan with {wallet} on your phone”**, CTA may say **Connecting…** *while the QR is visible*.
   - Bug: CTA on Connecting… **with no QR**, or a second Phantom/Binance logo over the QR.
   - `onUri` must show the QR. Hide `#login-ring` / `#login-badge` once the QR is up. If `connect()` hangs with no URI, the timeout must show Try again.

## Verify

```bash
cd source
node --check src/app.js
# if you have a session: load it, connect Phantom twice, hit Try again, open Coinbase tile, open a WC wallet
```

Do not run Figma eval. Do not restyle. Commit only your files when a coherent unit works.
