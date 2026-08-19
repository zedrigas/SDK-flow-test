# SPEC: token-art fallback discs

> Extracted 2026-08-19 from a read-only drop of the hosted widget source. REFERENCE ONLY — re-implement from these facts. Never open the source-drop repos. No code was copied.

## The widget's own fallback (the designed reference)

- A filled circle carrying the TICKER TEXT, up to 5 characters, uppercased (e.g. "EURC", "CBETH" → "CBETH"). Not a single letter.
- Fill: the merchant primary color; text small (two sizes: smaller when 5 chars or the disc is small). [TokenImage.tsx:42-61]
- Fires when: the art URL is invalid, the image errors, or no art exists. Below ~18px the widget renders nothing instead.
- Reality check: the widget bundles art for only 15 exchange symbols — most exchange tokens show this disc in production. Discs are the NORM there, not a failure state.

## This page's adaptation (Stake navy theme)

- Keep the existing disc palette (`--wg-panel` well, body text color) — the widget's merchant-primary fill does not port to widget-skin sheets.
- Content: ticker text up to 5 chars (replaces the current single letter), weight 700, sized to fit the 28px disc (smaller font at 4–5 chars).
- Coinbase surfaces ALWAYS disc: `CoinbaseBalance` carries no logo field in SDK 0.0.5/0.0.6 — never invent icons or balances.
- The nobalance sheet's discs shipped v20.14 as single letters — upgrading to ticker text is the remaining delta; re-verify the built page before editing.

## Related

Network badges are a separate system (SPEC-token-rows). The SDK's only art fields: `WalletBalance.logo/.thumbnail` (tokens, wallet flow), `WalletTransferSupportedCurrency.image/.blockchainImage` (token + network, via plan data).
