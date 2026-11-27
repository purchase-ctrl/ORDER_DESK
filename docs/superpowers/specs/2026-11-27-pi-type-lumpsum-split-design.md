# PI type pickup + lump-sum advance split (design)

## Why
Client sends one lump-sum advance covering container (Primary Packaging PI) and product (FG PI) of the same PO. User cannot tell which part is container deposit. Container money must not be adjusted against product invoices.

## Goals
- Order Desk auto-picks `pi_type` from PI Desk (new + edits), shows it as a badge on Products / Advance rows.
- "Lump-sum advance" entry: client + PO + amount -> app proposes split across that PO's PIs, user edits in a preview, then saves as normal advance records (one per PI).
- Each PI stays calculated separately (already keyed by PI number).
- Packaging-type PI advance is shown as "Container deposit" and never adjusts FG invoices (own pool).

## Non-goals
No change to existing advance-pool formula for FG; no auto-save without preview; no refund/forfeit workflow.

## Rules
- Split offered ONLY when the PO has 2+ PIs, at least one packaging-type (Primary/Secondary Packaging) and at least one other. A single FG PI: lump-sum split is not offered; the normal advance entry is used.
- Split order: packaging PI(s) required advance first, remainder to non-packaging PIs pro-rata to their required advance. Shortfall: FG gets less (shown). Excess: stays "unallocated", shown in preview.
- Preview is editable; save writes one advance per PI.

## Approaches
A) two manual entries; B) lump-sum with editable preview (chosen by user); C) fully automatic (rejected: silent wrong split risk).

## My calls (correctable)
- Container required advance = 100% of that PI's total incl. GST (what the client actually pays); FG required = app's existing "advance required".
- "PO" match uses the PI's ref PO (refPo), falling back to the PI number.
- `pi_type` carried via `od_pi_details` RPC (SQL file updated, user re-runs once in Supabase).

## Left to builder
Exact UI placement of the "Lump-sum" button, badge styling, test fixtures.
