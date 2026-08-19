# CLAUDE.md

Guidance for Claude Code in this repo (NOVA flow-feel — a headless `@swapped/connect-sdk` host).

## What this is

A Stake-styled merchant page. The SDK owns connect, balances, quotes, and send. We render every pixel.

Sources live in `source/` (gitignored). The tracked `index.html` is the built page.

Before a visual polish pass, read `docs/POLISH.md`. Green gates are not enough. The PO still rejects the look.

## After any visual change

Do this yourself. Do not ask the PO to run commands.

If you touch `source/src/style.css`, widget/merchant sheets in `source/src/page.html`, or anything “make it match Figma”:

```bash
cd source
npm run check:figma-spec
npm run eval:grok
```

`check:figma-spec` is required every time (no API key).

`eval:grok` needs `GROK_KEY` or `XAI_API_KEY` in the tests repo `.env`. If the key is missing, run the spec gate only and keep going. Do not stop and ask the PO for a key.

Then fix only:

- the printed `FAIL` lines from `check:figma-spec`
- `source/eval/grok-report.json` deltas (when the Grok pass ran)

Rebuild (`node build.mjs`) and re-run until green.

Load the `figma-parity` skill. Follow it.

## Bans

- Do not edit expected values in `source/eval/figma-spec.json`. Re-extract from Figma.
- Do not hardcode sample amounts, tickers, or addresses to match a Figma placeholder.
- Do not change `source/src/app.js` money / SDK logic to win a visual gate.
- Do not report Stake-navy vs Figma-dark colour as a widget-screen bug. That retheme is intended.

## Money / SDK

`source/src/real/swapped.js` is the only module that imports `@swapped/connect-sdk`. Keep it that way.
