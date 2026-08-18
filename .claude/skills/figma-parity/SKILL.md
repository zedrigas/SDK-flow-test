---
name: figma-parity
description: Grade the NOVA flow-feel page against Figma after any widget/merchant visual change. Run the machine spec gate, then the Grok visual eval. Use when changing style.css, page.html sheets, matching a Figma frame, or the user says "parity", "match Figma", or "eval:grok".
---

# Figma parity (flow-feel)

Claude does not guess pixels. Two gates, in this order.

Work from `sdk-flow-feel/source/` (sibling of the tests repo if you started there).

## 1. Machine spec (must pass)

```bash
cd source
npm run check:figma-spec
```

This measures real CSS / boxes against `eval/figma-spec.json` (extracted from Figma). A FAIL names the selector, the property, the actual value, and the wanted value.

**Never edit an expected value in `figma-spec.json` to make this pass.** Re-extract that screen from Figma if the frame changed. Selector-only fixes are allowed.

## 2. Grok visual eval

```bash
npm run eval:grok
# or one screen:
node eval/parity-capture.mjs --screens=amount
node eval/grok-grade.mjs --screens=amount
```

Needs `XAI_API_KEY` in `../tests/.env` or the environment. Exit 2 = no key. That is not a pass.

The judge compares each build shot to `eval/reference/figma/<screen>.png`. It is forbidden to re-report padding, radius, font-size, or width that `figma-spec` already owns.

Read `eval/grok-report.json`. Each fail is one change:

```json
{ "element": "...", "property": "...", "expected": "...", "actual": "...", "fix": "one CSS or markup line" }
```

Apply the `fix`. Do not invent extra restyles.

## 3. Rebuild and re-run

```bash
node build.mjs
npm run check:figma-spec
npm run eval:grok
```

Copy `source/index.html` → repo-root `index.html` before you commit a visual change.

## Bans

- No hardcoded sample money to match a Figma placeholder.
- No `app.js` SDK/money edits to win a visual gate.
- Widget screens (6411): colour differences vs the dark frames are the Stake retheme — not a fail.
- Merchant screens (`m-wallet`, `m-deposit`): colour is in scope.

## Optional

`npm run eval:parity` is the old Claude-screenshot loop. Do not use it as the first gate. `check:figma-spec` + `eval:grok` are the ones that keep you honest.
