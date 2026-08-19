# SPEC: amount-screen swap/bridge meta strip

> Extracted 2026-08-19 from read-only drops of the hosted widget + the SDK author's playground. REFERENCE ONLY — re-implement from these facts. Never open the source-drop repos. No code was copied.

## When it shows

Only when the resolved plan flow is `swap` or `bridge` AND a live quote exists. Hidden for `direct` flows, while no quote, and for stale quotes (respect this page's resolvePlan/quote run tokens — a superseded quote must never paint). [widget SwapDetails.tsx:310+, this repo's race guards]

## Content (one line, three items, dot separators)

`{time}mins · Fee ${fee} · Why swap?`

- time = the quote's estimated time, in whole minutes (e.g. "2mins").
- Fee = the quote's fee in fiat (e.g. "$0.01").
- "Why swap?" — a quiet link. Bridge flows say "Why bridge?" instead. [SwapDetails.tsx:382-439]

## The explanation (opens on tap — simple expand, no tooltip system)

- Swap: `{merchant} does not currently support {token}. We'll automatically swap your {amount} {token} to {destinationToken} using the best rate. The final amount may vary slightly due to pricing changes.`
- Bridge: `{merchant} does not currently support {token} ({network}). We'll automatically swap your {amount} {token} to {destinationToken} ({destinationNetwork}) using the best rate. The final amount may vary slightly due to pricing changes.`
[widget copy keys page.depositAmount.swapNoticeTooltip / bridgeNoticeTooltip]

## Look

Muted helper grey, small type, centered under the amount card. Never error/warning chrome — this is an explanation, not a failure. On small screens the strip wraps without pushing the CTA. The expanded text reads as helper prose.

## Placement decision of record (PO 2026-08-19: "Both")

This strip is ADDED to the amount screen AND the existing confirm-sheet `#sum-banner.info` note STAYS. The widget itself shows nothing on confirm — our confirm note is a sanctioned divergence. Do not remove it.

## Gate constraints

New element (`#amt-swapmeta`) — no figma-spec pins; existing amount-screen pins must hold. The strip is absent from the pinned Figma amount frames: record it as a PO-sanctioned addition in the judge notes.
