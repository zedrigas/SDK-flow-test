# Why this still looks wrong — and how to polish it

PO 2026-08-19. Live: https://zedrigas.github.io/SDK-flow-test/ (header must say the real build, last miss was **v19.6** on a v20.1 ship).

SDK behaviour for the 2026-08-18 field list is largely in. **The frontend is not.** A visual session reported 4/8/9/10/11/12/15 + wallet height “fixed” and `check:figma-spec` 184/184. The PO still says the UI is terrible. Trust the eye, not the gate.

## What the two sessions were for

| Session | Files | Job |
|---|---|---|
| SDK | `source/src/app.js`, `source/src/real/swapped.js` | Widget *behaviour* |
| Frontend | `source/src/style.css`, `page.html` markup, `merchant.css` | Pixels |

Do not let both edit `app.js`. If a pixel bug needs JS, stop and hand off.

`source/` is **gitignored**. Only root `index.html` is what GitHub Pages serves. After a visual change: `cd source && node build.mjs && cp index.html ../index.html`, then commit that file. Bump `<span class="db-ver">` in `page.html` **before** the build or the bar lies.

## Why green gates still look bad

This cost many re-prompts.

1. **`check:figma-spec` measures boxes.** It missed `#wl-wallet` 29px short (500×654 vs Figma 500×683). It will miss “this feels cheap” every time.
2. **`eval:grok` grades structure/icons.** It **passed the picker** while logos sat in a letterbox. It **ignored** Installed/Recent as fixture. It failed token *icons* and called that the screen. Colour vs Figma purple is *not* a bug (Stake navy v15).
3. **Figma is not the live widget.** Dark frames use `#181818` and purple `#4608E3`. Do not restyle the sheet to that. Judge geometry, type, radius, row height. Palette stays Stake navy.
4. **Figma money is dummy.** Select-crypto shows `$1` / `1 USDT` with `Min. amount: $0`. That is artwork. Exchange Pay has **no user balance**. Do not hardcode those numbers. SDK already paints typed fiat + conversion.
5. **Grok 24/28 leftovers are eval, not product.** Missing fixture icons in `reference-client.mjs`. Stale Coinbase capture (flow auto-skips login). Do not “fix” the product to make those four green.

## Where the SDK session was hardest

(So a polish pass does not undo them.)

- **`WALLET_ALREADY_CONNECTED` does not return the live wallet.** `walletId` is `phantom:injected`. Match `provider` / prefix, then `onSdkConnected`. A second Log in is a regression.
- **`reconnect({ force: true })` opens a popup.** Auto-login must use silent `reconnect()` / snapshot only.
- **Coinbase `connect()` must run on the tile tap** (user gesture). It **resolves `false`** on close/block; it does not throw. Read `oauth:error` → `error.type`. Codes `OAUTH_POPUP_*` exist and are **never thrown** in 0.0.5.
- **Login banner id is `#cb-login-banner`.** A second `#cb-banner` collided with the amount-step banner and broke validation. Do not rename it back.
- **Waiting copy** = `Confirm Coinbase connection in a new tab` + grey disabled CTA. **Closed copy** = `Window was closed before completion`. Not a toast.
- **Select-crypto right column** = typed fiat + rate. Never `minAmountFiat` painted as cash. `$1` next to `0 USDC` is the old bug.
- **WC:** one QR, that wallet’s mark *in* the QR, caption `Scan with {wallet} on your phone`. `Connecting…` is ok **only** while the QR is visible.
- **Production `/gateway` may 403.** Staging is the default. Do not treat that as a CSS bug.

Field shots (targets): `docs/field-shots/`.

## Where the PO had to re-prompt (do not repeat)

| Loop | What Claude did | What was wanted |
|---|---|---|
| Replica host | Built a new Next casino (`merchant-site/` in the **tests** repo) with a Stripe webhook seam | Copy **this** Stake host; hole = `swapped.js` |
| First frontend reply | A Figma measurement dump, no pixels | Paint, then run gates |
| First SDK reply | A 0.0.5 API dump, no product fix | Change `app.js` / `swapped.js` |
| “Purity” | Never name Swapped | Name the product and the widget |
| Version bar | Shipped v20.1, bar still **v19.6** | Change `db-ver` in the same build |
| Paths | Relative `PROMPT-*.md` / handoff files in a **tests** chat | Absolute path under `sdk-flow-feel` |
| Banner | New `id="cb-banner"` | Unique id; amount step already had it |
| Transitions (#14) | Temptation to invent easing | **Parked** until the widget repo is open |

The empty clone host (no SDK) is `/Users/martynasandriukaitis/Desktop/repos/nova-host`, not `merchant-site/`.

## Rules for the next frontend pass

1. Open the **live** page. Walk every sheet the way a user does. Screenshot. Then open Figma + `docs/field-shots/`.
2. Fix **one screen per commit**. Rebuild, copy `index.html`, bump `db-ver`.
3. Run `check:figma-spec` and `eval:grok` yourself. A green gate is not permission to stop. If it looks wrong, it is wrong.
4. Do not edit `app.js`. Do not edit `figma-spec.json` expected numbers. Do not hardcode amounts.
5. Do not invent motion (#14). Do not build Kraken. Do not build two-sign bridge screens.
6. Stake navy on widget sheets. Neutral wells; brand fill only from the mark in the well. No hardcoded Phantom purple.
7. If JS is required, write a one-line note and stop.

## Still open (product)

Parked: **#14 transitions**. Kraken. Two-sign swap/bridge.

Everything else the PO can still *see* as wrong is in scope: spacing, type, icon wells, overlays, merchant chrome vs widget sheets, empty/loading states, Coinbase banner sit-on-CTA, picker tiles, token rows, wallet modal proportions. The last visual pass touched some of these; **the PO rejected the result**. Start from the live page, not from that session’s “done” list.
