# SPEC: amount-screen token chip

> Extracted 2026-08-19 from a read-only drop of the hosted widget source. REFERENCE ONLY — re-implement from these facts. Never open the source-drop repos. No code was copied.

## Contract

- The chip (coin icon + figure + chevron) shows the selected token's **BALANCE**, never anything derived from the typed amount. [SelectedToken.tsx:40-51]
  - Crypto display mode: the formatted balance + symbol (compact/decimals rules from SPEC-token-rows apply).
  - Fiat display mode: balance × exchangeRate, as fiat.
- The figure is CONSTANT while the user types. Typing $1 then $4 must not change it.
- Coin icon in the chip: small (~14px), NO network badge. Chevron on the right; tapping opens the token picker. [SelectedToken.tsx:62-98]
- No rate yet → follow this page's v20.18 rule: the slot stays empty until a live rate exists; never a fake number.

## Known bug being fixed (field shots 2026-08-19)

Shots 14/15: typing $1 showed "BONK $0.99", typing $4 showed "BONK $3.99" — the chip tracked the input through a conversion round-trip. That binding is wrong.

## Gate constraints

No figma-spec pin binds the chip's TEXT; the chip's geometry pins must hold. Do not touch the clamp/snap logic (v20.5/20.6) or the v20.18 empty-until-rate rule.
