You are the frontend / Figma session for the NOVA flow-feel page.

Repo: this folder. Sources: `source/`. The SDK is headless. You own pixels only.

## Files you may edit

- `source/src/style.css`
- `source/src/page.html` (markup, classes, hidden — not new money logic)
- merchant styles in `source/src/merchant.css` only if the wallet/deposit **merchant** modals need it

## Files you must not edit

- `source/src/app.js`
- `source/src/real/swapped.js`
- expected values in `source/eval/figma-spec.json` (re-extract from Figma if a frame changed; selector-only fixes are ok)

If a bug needs JS, stop and tell the PO. The other session owns JS.

## Figma (live file, Swapped account)

File `GI3r50KHCyw8HTGrUV1Drh` (Swapped Connect Widget). Palette is **Stake navy**, not the dark-purple frames. Judge geometry / type / structure. Colour on widget screens is the v15 retheme.

- Web3: node `19:927` (and 6411 frames already in `eval/reference/figma/`)
- Exchange Pay: `3006:1823` — select-crypto overlay is `3138:28812`
- OAuth: `3006:2320`
- Merchant wallet: `6389:112208` (500×683)

## After every visual change, run this yourself

```bash
cd source
npm run check:figma-spec
npm run eval:grok
```

Fix only printed FAILs + `eval/grok-report.json`. Never ask the PO to run these. Never edit spec expected numbers to pass.

## Bugs to fix (PO 2026-08-18)

4. Select-supported-token rows are squished. Match Figma token row 352×60, 12px pad, 8px icon gap. Grok already failed **missing/broken coin icons** on this screen — paint a round icon well even if the SDK image is late (placeholder circle, not a broken `img`).
8. Picker tile logos: the mark must **fill** the 24×24 well. No inner border / padded letterbox. Grok passed this screen — still fix it.
9. Index labels (“Installed”, “Recent” if we show them) need the Figma colour treatment (badge fill + text). Do not invent a Recent row the session does not have; colour the badges we do show.
10. No flash of `0`, `—`, or `0s` before data. Skeleton / hide until the value exists. Do not fake numbers.
11. Exchange Pay “Cancel order” is **not** in Figma `3008:575`. Hide that control. Back may still abandon (SDK session owns the close call if it is not already wired).
12. Select-crypto overlay (`#wl-xpay-select` / Figma `3138:28812`): top of the sheet has the wrong cut / radius. Sheet is 400 wide, 28px radius, overlay sits on the amount card like the wallet token drawer. Pull the live node if needed.
15. If JS already sets the correct wallet icon and it still looks like Phantom, fix the CSS/asset well. Do not hardcode Phantom in CSS.
Plus: **Wallet modal `#wl-wallet` is 29px too short** (build 500×654 vs Figma 500×683). Stretch to the frame height. Spec missed this — add a `figma-spec` **selector** for height if you re-extract; do not invent the expected number.

## Do not do

- Motion / transitions (#14). Parked until we have the widget repo.
- Two-sign bridge/swap screens. Out of this pass.
- Kraken OAuth. No SDK module.

## Verify

Rebuild (`node build.mjs`). Re-run the two gates. Copy `source/index.html` → repo-root `index.html` if you commit a visual.
