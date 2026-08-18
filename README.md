# NOVA Flow Feel — real `@swapped/connect-sdk` host

A merchant site (fictional **NOVA** / Stake look) that uses
`@swapped/connect-sdk` for every payment. The SDK is headless: this page
renders the Stake-styled sheets and the SDK owns connect, balances, quotes,
and send.

Paste a Swapped session in the `{ }` drawer. Staging is the default: the
production wallet gateway is still broken upstream.

Journey: **Wallet → Deposit → method picker → amount → confirm → wallet sign**.

Wallets, Exchange Pay, and Coinbase are wired. Methods the SDK cannot start
are hidden.

## Build & verify

The deployed `index.html` is self-contained. Sources live in `source/`:

    cd source
    npm install
    node build.mjs
    npm run check
    npm run check:ui
    npm run check:figma
    npm run check:figma-spec
    npm run eval:grok          # Grok visual judge (needs XAI_API_KEY); skip-list is figma-spec
    npm run check:sdk
    node verify.mjs

The build reads public values from the QA repo `.env` when present and
refuses to emit secrets.

`serve.command` — double-click to serve on the local network (no-store headers).
