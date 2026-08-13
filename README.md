# NOVA Flow Feel — 3 REAL wallet flows (no Swapped SDK)

A merchant site (fictional "NOVA" brand) that talks to real wallets directly —
the page itself plays the role of the future Swapped Connect SDK. Solana
mainnet, tiny amounts (hard cap **$0.25** per run), recipient fixed to the QA
throwaway wallet. The results (real app-switch counts and timings per flow)
define the SDK spec for the dev team.

- **Flow A** — Phantom's injected provider: desktop extension, or this page
  opened inside Phantom's in-app browser via `phantom.app/ul/browse/…`
  (heavy jumps: you come back to Safari by hand)
- **Flow B** — Phantom universal links (`phantom.app/ul/v1/connect` +
  `…/signTransaction`), x25519-encrypted redirect payloads, page broadcasts
  the signed tx itself (light automatic round trips; mobile only)
- **Flow C** — WalletConnect v2 session: QR on desktop, wallet links on
  mobile; sign request rides the relay. Reference wallet: Trust (Phantom's
  wallet-side WC support is undocumented — testing it is itself a finding)

Journey: **Wallet → Deposit → Phantom → choose A/B/C**. The top toolbar counts
real app switches (1 round trip = 2 jumps) and shows away-time per trip. `{ }`
opens engineer notes with the exact call at every step + an RPC override field.

## Build & verify

The deployed `index.html` is fully self-contained. Sources live in `source/`
(kept out of git — contains raw design exports + node_modules):

    cd source
    npm install
    node build.mjs           # bundles the wallet layer (esbuild) + inlines everything
    node checks/real-units.mjs  # crypto/URL/cap unit checks
    node checks/interaction-states.mjs  # the page is ALIVE: hover/focus/motion,
                             # search, carousel, keyboard (the dead-page guard —
                             # a screenshot rubric alone cannot catch inert UI)
    node verify.mjs          # hermetic Playwright pass: fake provider, mocked RPC,
                             # simulated Phantom peer for the flow-B round trip
    npm run eval             # AI eval agent: screenshots every flow step, then a
                             # headless Claude grades each against eval/rubric.md
                             # (strict JSON verdict in eval/report.json)

The build reads two PUBLIC values from the QA repo's `.env`
(`TEST_SOLANA_ADDRESS`, `REOWN_PROJECT_ID`) and refuses to emit any secret.

## Money safety

`$0.25` hard USD cap + an absolute lamports ceiling enforced **before** any
wallet sees a request; recipient hardcoded at build time; the price feed
falls back HIGH so the cap only gets stricter; every signature is approved by
a human in the wallet.

`serve.command` — double-click to serve on the local network (no-store headers).
