# SPEC: breakdown view (reference — largely shipped v20.12/v20.17)

> Extracted 2026-08-19 from a read-only drop of the hosted widget source. REFERENCE ONLY — re-implement from these facts. Never open the source-drop repos. No code was copied.

## Widget row set, in order

1. Amount (the SEND side) — swap flows only.
2. Amount / "Receive" — the destination amount.
3. Network — the CHAIN's mark + capitalized chain name (e.g. Solana icon + "Solana"). When send-chain ≠ receive-chain (bridge): two chain marks + an arrow. [TransactionSummaryInfoBase.tsx:300-318]
4. Fee rows — labels "Network fee", "Withdrawal fee", "Swap fee"; values in FIAT; `~` prefix when the fee is an estimate. 
5. Transaction type ("Swap") — swap flows only.
6. Deposit address + a copy affordance.
7. Transaction ID — only when a hash exists.

## Chain-mark policy for THIS page

Never the token's icon; never a baked default. Prefer SDK art: `WalletTransferSupportedCurrency.blockchainImage` (present in installed 0.0.5, reachable via the plan's bridge/currency data). Absent that: the lettered `bd-net-badge` disc. Never hotlink CoinMarketCap (the widget does; we deliberately do not). Shipped v20.12 (breakdown) + v20.17 (details sheet) — re-verify before touching.

## Deliberate divergences (do not "fix")

- Fee-row hiding when the quote carries no networkFee is a PO decision (2026-08-18).
- The Deposit-address row is a LATER candidate — not yet in scope.
- `#sum-breakdown` geometry is figma-spec-pinned with the fee row visible.

## Copy notes

The breakdown entry point on the confirm sheet reads "Click to see breakdown" (desktop) / "Tap to see breakdown" (mobile) in the widget.
