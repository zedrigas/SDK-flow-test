# CLAUDE.md

Guidance for Claude Code in this repo (NOVA flow-feel — a headless `@swapped/connect-sdk` host).

## What this is

A Stake-styled merchant page. The SDK owns connect, balances, quotes, and send. We render every pixel.

Sources live in `source/` (gitignored). The tracked `index.html` is the built page.

## After any visual change

If you touch `source/src/style.css`, widget/merchant sheets in `source/src/page.html`, or anything “make it match Figma”:

```bash
cd source
npm run check:figma-spec
npm run eval:grok
```

Then fix only:

- the printed `FAIL` lines from `check:figma-spec`
- `source/eval/grok-report.json` deltas

Rebuild (`node build.mjs`) and re-run until both are green.

`eval:grok` needs `XAI_API_KEY` in the tests repo `.env` (or the environment). A missing key exits 2. That is not a pass.

Load the `figma-parity` skill. Follow it.

## Bans

- Do not edit expected values in `source/eval/figma-spec.json`. Re-extract from Figma.
- Do not hardcode sample amounts, tickers, or addresses to match a Figma placeholder.
- Do not change `source/src/app.js` money / SDK logic to win a visual gate.
- Do not report Stake-navy vs Figma-dark colour as a widget-screen bug. That retheme is intended.

## Money / SDK

`source/src/real/swapped.js` is the only module that imports `@swapped/connect-sdk`. Keep it that way.
