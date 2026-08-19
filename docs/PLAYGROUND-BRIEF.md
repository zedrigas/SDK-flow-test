# Merchant playground (Stake shell) — brief for Claude

You are building a **reusable casino playground** we show to merchants.  
It must look like **their site**, with pay on it. It is not a licensed casino.

Do **not** rewrite the live NOVA payment flow in place (`sdk-flow-feel` v20.x).  
Do **not** clone `merchant-site/` (the fake Next.js casino with a Stripe webhook). That was the wrong replica.

## Goal

A playground we can copy for the next shop:

- Stake-look shell (sidebar, top bar, games, **Wallet**).
- Empty wallet is **short**. Connected wallet **grows**.
- Token pictures are **ours** (USDC, SOL, …), never a random API thumbnail/face.
- Pay uses Swapped (session + SDK or existing NOVA sheets). Secret never in the browser.
- Next merchant = new logo + colours, not a new site from zero.

This is the pitch: “it lives on your site.”  
If Wallet shows a face on USDC, the pitch dies.

## References

**Figma — Stake dashboard (shell)**  
https://www.figma.com/design/GI3r50KHCyw8HTGrUV1Drh/Swapped-Connect-Widget?node-id=6419-94769  
Frame name: `Stake Dashboard Type 14` (1470×760). Sidebar + VIP + Casino/Sports banners + search + trending games.  
This is the **merchant page**, not the iframe widget.

**Figma — Wallet modal (merchant)**  
https://www.figma.com/design/GI3r50KHCyw8HTGrUV1Drh/Swapped-Connect-Widget?node-id=6389-112208  
500×683 is the **connected / full** frame. Do **not** lock empty state to 683px.

**Figma — full widget state list (pay screens, do not drop fails)**  
https://www.figma.com/design/GI3r50KHCyw8HTGrUV1Drh/Swapped-Connect-Widget?node-id=2-2

**Old iframe playground (session generator only)**  
https://playground.swapped.app/  
This is a **form**: currency, walletAddress, Generate Session URL, env.  
It is **not** the casino UI. Do not rebuild that form as the shop.  
A hidden engineer drawer (paste session / env) is enough, like NOVA’s `{ }` bar.

**Existing lab (do not smash)**  
`/Users/martynasandriukaitis/Desktop/repos/sdk-flow-feel`  
Live: https://zedrigas.github.io/SDK-flow-test/  
Merchant HTML already copies 6419 (see `source/src/merchant.html`).  
Payment sheets live in `page.html` + `app.js`. That JS is a 3k-line poster with marker. Leave it running.

**Empty SDK hole (optional start)**  
`/Users/martynasandriukaitis/Desktop/repos/nova-host`  
Stake files with stub `swapped.js`. No payment SDK. Can copy shell assets from here or from sdk-flow-feel `source/src/merchant.*`.

## What to build

New sibling folder (recommended):

`/Users/martynasandriukaitis/Desktop/repos/merchant-playground`

Not inside the tests QA repo. Not a rewrite of live `index.html` until the PO says to swap.

### Stack

Use **React** (or web components) for the **shell only**:

- App layout (sidebar, top bar, balance chip, Wallet button)
- `<WalletModal />` as one component with props, not static HTML rows

Keep pay screens as a **hole**:

- For v1: open the existing Connect sheets **or** an iframe to the widget with a playground-generated session  
- Do not re-implement Coinbase closed / QR / amount snap in this playground pass

v1 is a **proper Stake shell** + “Deposit” that still works.  
The Connect **kit** is a later product.

### WalletModal contract (must)

Props (names can vary, meaning cannot):

- `connected: boolean`
- `wallets: { id, name, icon }[]`  // connected wallets
- `tokens: { symbol, name, network, amount, fiat, logo }[]`

Behaviour:

1. **Disconnected**  
   Hug content. Short modal. Two placeholder rows **USDC** and **SOL** with **local** art (`usdc.svg`, sol two-layer). No API thumbnail. Balance `$0.00`. No CONNECTED pill.

2. **Connected**  
   Grow to fit rows (cap at Figma 683 on desktop if needed). Show real tokens.  
   Logo rule: local map by `symbol` first (USDC, SOL, USDT, …). Else `logo` URL. **Never** `thumbnail` if it is a different asset. On disconnect, restore local USDC/SOL art. Do not leave a face or a `$` on SOL.

3. **Several wallets**  
   Extra connected rows. Modal grows. “Use Other Wallet” stays.

4. Tabs  
   Overview / Buy Crypto / Swap Crypto / **Settings** — all four words fully visible. Settings must not clip to “Settin”.

5. Deposit  
   Opens pay (widget iframe or existing NOVA sheets). Do not build a Stripe webhook.

### Shell

Match Figma 6419:94769:

- Desktop sidebar 260px: Casino / Sports, Promotions … Language
- Top bar: logo, balance + Wallet
- VIP card, Casino/Sports hero tiles, search, trending games
- Mobile: burger + compact top bar (NOVA already has this — copy geometry)

Games can be the existing webp cards. No need for a real game.

### Session / env

Copy the idea from playground.swapped.app **and** NOVA:

- Paste `sessionId` or landed widget URL
- Staging default
- Secret / API key **never** in the client bundle

If you add `POST /api/session` later, sign on the server. v1 paste-session is OK.

## Explicit bans

- Do not start from `tests/merchant-site/` (Stripe `DepositProvider` + cents webhook).
- Do not YOLO `@swapped/connect-sdk` into 20 React files. One adapter module if you wire pay.
- Do not lock `#wl-wallet { min-height: 683px }` on the empty state.
- Do not paint `balance.thumbnail` onto SOL/USDC placeholders.
- Do not invent Kraken, two-sign EVM, or motion from scratch.
- Do not ask the PO for an API key. If missing, shell still boots.

## Done means (v1)

1. `npm install && npm run build` (or `dev`) — page loads.
2. Open Wallet **disconnected**: short modal, correct USDC + SOL art, Settings readable.
3. Connect (or mock `connected=true` with two tokens): modal grows, logos correct, no face.
4. Disconnect: art and height go back. No leftover thumbnail.
5. Deposit still reaches a pay surface (iframe or existing flow).
6. Desktop **and** a phone width. Screenshot both.

Then stop. Write a 10-line report: folder path, how to run, what is still a hole (SDK kit).

## Later (do not do in v1)

- Full Connect UI kit (all fail states) as npm package  
- Per-merchant theme files for 7–8 shops  
- Replacing https://playground.swapped.app/ as the session factory (keep it or a drawer)
