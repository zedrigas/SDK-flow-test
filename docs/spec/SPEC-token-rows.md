# SPEC: token drawer rows (widget parity)

> Extracted 2026-08-19 from a read-only drop of the hosted widget source. REFERENCE ONLY — re-implement from these facts. Never open the source-drop repos (connect-FE-main, connect-SDK-main, connect-SDK-playground-main). No code was copied. Source citations are for audit, not for reading.

## Row anatomy (behavior contract)

- One row per token/chain pair. NO chain text anywhere on the row — the network reads from a badge only. [TokenBalanceItem.tsx:133; dead chain-text component confirmed unused]
- Coin icon 28px. Network badge: small disc pinned to the coin's BOTTOM-RIGHT (absolute; right ≈ -2px, bottom 0), ~15px, on EVERY row that has a network. Badge img alt = `"{network} icon"` (e.g. "solana icon"). [TokenImage.module.scss:13-18; NetworkLogo.tsx:46]
- Right column, top line: **USD value, bold** (e.g. `$48.62`). Bottom line: muted compact token amount + symbol (e.g. `48.62 USDT`, `1.01M BONK`). [reverseBalanceOrder; TokenBalanceItem.tsx:157]
- While the rate is still loading: show a small loading indicator in the fiat slot; if no rate exists, show nothing (empty string) — never `$0.00`. [TokenBalanceItem.tsx:245-247]

## Number formatting

- Compact from **10,000 up**: format `0.00a`, uppercase suffix, strip trailing zeros before the suffix. Examples: 100000 → `100K`; 100520 → `100.52K`; 1230000 → `1.23M`. [formatNumbers.ts:156-171]
- Below 10,000: round HALF-UP to the per-token display decimals:
  | Tokens | decimals |
  |---|---|
  | USDT, USDC, DAI | 2 |
  | BTC, ETH, WBTC | 6 |
  | SHIB, PEPE, BabyDoge, BONK, PUMP | 0 |
  | everything else | 3 |
  [crypto.constants.ts:113-131]
- In this page, produce the compact string via `R.swapped.formatCompactTokenAmount` (already exported by the wrapper) and apply the decimals table for the sub-10k case.

## Sort order (comparator, top to bottom)

1. usable/enabled rows first;
2. if BOTH rows lack an exchange rate → raw balance descending;
3. `!balanceTooLow` before `balanceTooLow`;
4. USD value descending (rate × balance).
[TokenExchangeList.tsx:41-71]

## Disabled rows

Stay VISIBLE, non-tappable, with a short reason on the row ("Not enough balance", "Not supported"). Never filter them out.

## Gate constraints (this repo)

- figma-spec pins `.tok-row` h=60 / w=352 / pad 12 / radius 12, `.amt` 14px, `.fiat` 12px on CLASS selectors. Swap the DATA between `.amt` (top → fiat) and `.fiat` (bottom → compact amount), never restyle the classes. `.tok-net` is unpinned.
- The Figma tokens PNG shows token-amount-on-top; USD-on-top is a PO-sanctioned widget-parity delta (2026-08-19) — record it in the judge notes (figma-refs), like the picker back-chevron precedent. Never edit figma-spec.json.
- The Refresh repaint path writes the same two spans — change it in lockstep with the row template or one Refresh press reverts the fix.

## Art policy

Never hotlink CoinMarketCap or CloudFront (the widget does; this page deliberately does not — it would mask the missing-network-art SDK gap we asked dev to fix). Badge content = the existing lettered `netBadge()` disc; if SDK art is wanted later, `WalletTransferSupportedCurrency.blockchainImage` is the only SDK source.
