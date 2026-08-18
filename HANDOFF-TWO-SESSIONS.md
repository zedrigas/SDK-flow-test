# Two Claude sessions — split after PO field test (2026-08-18)

Do **not** start both in the same tree on the same files. SDK owns `source/src/app.js` + `source/src/real/swapped.js`. Frontend owns `source/src/style.css` + markup/classes in `source/src/page.html`. If both need `app.js`, stop and hand off.

## Eval vs PO notes

| # | PO note | Eval? | Session |
|---|---|---|---|
| 1 | Phantom “already connected” but cannot continue | No (behaviour) | **SDK** |
| 2 | Try again does nothing | No (behaviour) | **SDK** (same root as #1) |
| 3 | Widget auto-connects a trusted Phantom/MetaMask; we prompt | No (behaviour) | **SDK** |
| 4 | Select-token rows squished | Partial — Grok failed **icons**, not row height | **Frontend** |
| 5 | Refresh does nothing | No (behaviour) | **SDK** |
| 6 | Only Solana balances | No (behaviour / data) | **SDK** |
| 7 | Coinbase tile does not open OAuth; cancel popup leaves stale UI | No (behaviour) | **SDK** |
| 8 | Picker logos not filling the square (border around) | **Missed** — Grok passed picker | **Frontend** |
| 9 | Index “Recent” / labels not coloured | Grok **ignored** as fixture — PO wants them | **Frontend** |
| 10 | Flash of `0` / `—` / `0s`; no lazy load | No | **Frontend** skeletons + **SDK** must not paint `0` before data |
| 11 | Exchange Pay “cancel order” not in Figma | No | **Frontend** (hide). Back may still close the order. |
| 12 | Select-crypto overlay top radius / shape ≠ Figma | Not graded this run | **Frontend** |
| 13 | Dropdown shows $1 but 0 USDC / 0 USDT | No (money) | **SDK** |
| 14 | Transitions awful | No | **Parked** — wait for widget repo |
| 15 | Every wallet shows Phantom loader art | No | **SDK** paints the badge; **Frontend** if assets missing |
| 16 | WC wallets stuck on Connecting; Phantom+Binance icons overlap instead of QR | No | **SDK** first; Frontend only after QR markup is correct |

Grok eval (8 screens, 2026-08-18): **tokens FAIL** (broken/missing coin icons). **m-wallet is 29px short** (500×654 vs Figma 500×683) — spec and Grok both missed height. Frontend should add a height check after the visual pass.

## PO field shots (same day)

Files in `docs/field-shots/`. Use them as the target / bug pair.

| Shot | What it is | Use |
|---|---|---|
| `01-binance-qr.png` | WC QR with Binance mark, caption “Scan with Binance on your phone” | **#16 target.** Connecting… is ok **only** while this QR is up. |
| `02-xpay-select-min.png` | Select crypto: Min. amount $1 + right `$1` / `0 USDC` | **#13 bug.** Right column is min painted as a balance. Exchange Pay has no holding. |
| `03-coinbase-closed-or-prompt.png` | Widget Coinbase after the popup closed | **#7 target.** Banner + enabled Log in. Copy: “Window was closed before completion”. |
| `04-coinbase-widget-waiting.png` | Widget: “Confirm the Coinbase connection in a new tab”, CTA off | **#7 target** while OAuth is open. |
| `05-coinbase-nova-idle.png` | NOVA: “Please complete your login…”, spinning Log in, no window | **#7 current.** Tile must open OAuth; do not sit here. |

Figma Coinbase idle (`3006:2321`) uses the same “Please complete your login…” line. The **hosted widget** then swaps that line for waiting / closed copy. Match the widget.

## Parked: transitions (#14)

PO will later grant access to the production widget repo. Do **not** invent easing. When that repo is open, copy the widget’s motion (durations, easing, which nodes animate). Until then: no new animation work in either session.

## Prompts

Paste `PROMPT-SDK.md` into the SDK Claude session.  
Paste `PROMPT-FRONTEND.md` into the visual Claude session.  
Start SDK first if you can; visual can start in parallel **only** if it does not touch `app.js`.
