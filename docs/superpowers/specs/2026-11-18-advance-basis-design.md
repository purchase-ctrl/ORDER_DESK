# Advance basis (with / without GST) and advance summary per PI

Approved by the user in conversation on 2026-11-18.

## Intent and why
The user wants the Product list card on the client dashboard to show, for each PI / PO, how much advance was due, how much was received and how much has been adjusted in invoices. The app must also work out whether the customer's advance was calculated on the value with GST or without GST, and calculate everything on that basis. Today the app always works without GST, so an advance paid on the GST-inclusive value shows as "excess" and invoices adjust the wrong amount.

## Goals
- Required advance, received, adjusted in invoices and left, per PI / PO, on the product card.
- Basis (with / without GST) found automatically per PI / PO; can be set by hand.
- Invoice adjustment follows the basis, so net receivable is right.

## Non-goals
- No change to payments, dispatch or the ledger layout.
- No new storage; the basis is one field on the advance entry.

## Approaches considered
1. Product-level setting only: simple, but one product can have POs on different bases. Rejected.
2. Auto-detect per PI / PO with a manual override on the advance entry (chosen).
3. Always ask on every advance entry: slows data entry. Rejected.

## Design (the user's decisions, plus my calls marked "call")
- Basis per PI / PO: advance entry gets "Advance basis: Auto / Without GST / With GST", default Auto. Stored as `basis` on the advance row (`''`, `'ex'`, `'gst'`). If several rows of a PO disagree, the first non-Auto one wins (call).
- Auto: compare total received for the PO with `poQty x advUnit` (without GST) and `x 1.18` (with GST). The one within 2% of the received amount is the basis. Before any advance is received, or if neither matches, use Without GST, as today.
- Required advance = `poQty x advUnit x (1 + GST if basis is gst)`.
- Invoice adjustment: without GST, as today (`min(q x advUnit, nonGst, available)`, taken off the invoice total). With GST: `min(q x advUnit x 1.18, total, available)`. Net = total - adjustment.
- Old invoices are recalculated with the same rule (the user agreed). Outstanding totals may change.
- Product card: under each PI a line "Due / Received / Adjusted in invoices / Left" and a chip "With GST" or "Without GST". More than three PIs: the rest sit behind "+n more" (call).

## Left to the builder
- Exact wording and layout of the card rows; dark mode and mobile as for the other cards.
- The 2% tolerance sits in one constant.
