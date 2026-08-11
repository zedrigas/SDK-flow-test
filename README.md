# SDK Flow Feel — 3 mobile payment flows

Interactive iPhone prototype simulating three integration shapes for the future
Swapped Connect SDK on a merchant site (fictional "NOVA" brand, Solana + USDC,
simulation only — no wallet, no network calls).

- **Flow A** — widget inside Phantom's in-app browser (2 heavy jumps, manual return)
- **Flow B** — universal-link round-trips (4 light automatic jumps)
- **Flow C** — WalletConnect session (4 light jumps, sign request over the relay)

Open `index.html` (or the GitHub Pages URL) on a phone. Tap a flow, watch the
jump counter, open the `{ }` tab for engineer notes, `↺` resets.

## Build

The deployed `index.html` is fully self-contained (all assets inlined as data URIs).
Sources live in `source/` (kept out of git — contains raw Figma design exports):

    cd source && node build.mjs   # emits ../source/index.html — copy to repo root
    node verify.mjs               # Playwright drive-through of all 3 flows
