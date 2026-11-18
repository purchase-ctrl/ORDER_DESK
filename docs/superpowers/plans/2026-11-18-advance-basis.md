# Advance basis (with / without GST) and per-PI advance summary: Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Work out, per PI / PO, whether the advance is on the value with GST or without it, calculate required advance and invoice adjustment on that basis, and show due / received / adjusted / left per PI on the dashboard Product list card.

**Architecture:** `index.html` is one file with one script. `calc()` already builds one `group` per PO and product (`g.poQty`, `g.received`, `g.adjusted`, `g.advUnit`, `g.required`). Add `g.basis` right after the advance rows are summed and before invoices are processed, make `g.required` and the invoice adjustment use it, add a field to the advance form, and render the numbers in `renderDash()`.

**Tech Stack:** Plain JavaScript in `index.html`; Playwright (`/opt/pw-browsers/chromium`) with a mocked Supabase for tests; `node` to run them.

**Spec:** `docs/superpowers/specs/2026-11-18-advance-basis-design.md`

## Global Constraints

- `GST = 0.18` (existing constant). Detection tolerance: `BASIS_TOL = 0.02` (2%), one constant.
- Basis values stored on the advance row: `basis` is `''` (Auto), `'ex'` (Without GST) or `'gst'` (With GST).
- Without GST adjustment, as today: `min(q * advUnit, nonGst, available)`. With GST: `min(q * advUnit * (1 + GST), total, available)`. `net = total - adj`.
- Required advance = `poQty * advUnit * (basis === 'gst' ? 1 + GST : 1)`.
- Old invoices are recalculated with the same rule (no stored adjustment).
- Copy: sentence case, chips "With GST" / "Without GST", card line "Due / Received / Adjusted in invoices / Left".
- No new database field or table; `basis` lives inside the advance record's `data`.

## Review Focus

- An invoice raised before any advance is received: basis must be Without GST, adjustment 0, no error.
- Received matches neither basis within 2%: Without GST, and the "Excess" or "Pending" chip stays as today.
- Two advance rows on one PO where one has `basis: 'gst'` and one is Auto: the first non-Auto row decides.
- A PO with a missing or zero rate or quantity: no division by zero, card shows 0, not NaN.
- A product with more than three PIs: three shown, the rest behind "+n more", nothing dropped from totals.
- A limited user must not see PIs of clients that are hidden for them.

---

### Task 1: Basis detection and calculation

**Files:**
- Modify: `index.html` (`calc()` around lines 850-885)
- Create: `tests/helpers/mock.js`, `tests/advance-basis.test.js`

**Interfaces:**
- Consumes: `advUnit(p)` (line ~765), `G(po, pid)` groups, `GST`.
- Produces: `const BASIS_TOL=0.02` and `function advBasis(received, poQty, unit, override)` returning `'ex'` or `'gst'`; `g.basis` on every group; `g.required` and `inv.adj` that follow it.

- [ ] **Step 1: Write the harness** `tests/helpers/mock.js` exporting `async function open({records})` that starts Chromium, routes `https://xsdcvwjithtsvhcntovp.supabase.co/**` (signup, token, `od_profiles`, `od_records` GET returns `records`, POST/PATCH return ok), passes the password lock (`#lockp` = `sunshine`), signs up `nihar_sunshineind.in` (admin) and returns `{pg, errors}`.
- [ ] **Step 2: Write the failing tests** in `tests/advance-basis.test.js`. Seed one client (name and brand set), one product `cost 65, advPct 50`, and one PO of 30,000 units at rate 65. Assertions on the Advance tab text and the Daily Invoicing "Advance adjusted" column:
  - received 975000 → required `₹9,75,000.00`, chip "Complete".
  - received 1150500 → required `₹11,50,500.00`, chip "Complete" (not "Excess").
  - no advance row, one invoice of 10,000 units → adjusted `₹0.00`.
  - received 975000, one invoice of 10,000 units → adjusted `₹3,25,000.00`.
  - received 1150500, one invoice of 10,000 units → adjusted `₹3,83,500.00`.
  - received 975000 with `basis: 'gst'` on the row → required `₹11,50,500.00`, chip "Pending".
  - poQty 0 → required `₹0.00` and no `NaN` anywhere on the page.
- [ ] **Step 3: Run** `node tests/advance-basis.test.js`. Expected: FAIL on the 11,50,500 cases.
- [ ] **Step 4: Implement** `advBasis`: if override is `'ex'` or `'gst'` return it; else with `ex = poQty*unit`, `gs = ex*(1+GST)`: return `'gst'` when `received > 0`, `ex > 0` and `|received-gs|/gs <= BASIS_TOL` and that is closer than to `ex`; otherwise `'ex'`. In `calc()`: after the advance loop sets `g.basisOverride` (first non-Auto `a.basis`), add a loop over `groups` that sets `g.basis = advBasis(g.received, g.poQty, advUnit(prod(g.pid)), g.basisOverride)`. In the invoice map, use `const k = g.basis==='gst' ? 1+GST : 1` and `adj = Math.min(q*au*k, g.basis==='gst' ? total : nonGst, avail)`. In `groups.forEach`, `g.required = g.poQty*g.advUnit*(g.basis==='gst'?1+GST:1)`.
- [ ] **Step 5: Run** the tests. Expected: all PASS, `errors` empty.
- [ ] **Step 6: Commit** `git add index.html tests && git commit -m "feat: advance basis with or without GST in calc"`.

### Task 2: Advance basis on the advance form

**Files:**
- Modify: `index.html` (`FORMS.advances` ~line 1258, `readForm` advances ~line 1431)
- Test: `tests/advance-basis.test.js`

**Interfaces:**
- Consumes: `sel(id,label,options,value)` form helper, `val(id)`.
- Produces: `basis` on saved advance rows (`''`, `'ex'`, `'gst'`).

- [ ] **Step 1: Add failing tests:** open Advance, click "Add advance received", assert a select `#a_basis` exists with options "Auto", "Without GST", "With GST" and Auto selected; choose "With GST", save, reopen the entry: `#a_basis` shows "With GST".
- [ ] **Step 2: Run** and confirm FAIL (no `#a_basis`).
- [ ] **Step 3: Implement:** add `sel('a_basis','Advance basis',[{v:'',t:'Auto (checked from the amount)'},{v:'ex',t:'Without GST'},{v:'gst',t:'With GST'}],r.basis||'')` after the `a_recv` field, and `basis:val('a_basis')` in the returned advance row.
- [ ] **Step 4: Run** the tests. Expected: PASS.
- [ ] **Step 5: Commit** `git commit -am "feat: advance basis field on the advance form"`.

### Task 3: Per-PI advance lines on the product card

**Files:**
- Modify: `index.html` (`renderDash()` product card, line ~2188; CSS next to `.pcard`)
- Test: `tests/advance-basis.test.js`

**Interfaces:**
- Consumes: `R.groups` fields `po`, `required`, `received`, `adjusted`, `pending`, `basis`, `pid`; `inr()`.
- Produces: `function pcardAdvHTML(gs)` returning the lines for one product's groups.

- [ ] **Step 1: Add failing tests:** with the 1150500 seed and one 10,000-unit invoice, the dashboard card contains the PI number, "Due ₹11,50,500.00", "Received ₹11,50,500.00", "Adjusted in invoices ₹3,83,500.00", "Left ₹7,67,000.00" and the chip "With GST". With five PIs on the product: three lines plus "+2 more", and expanding shows all five.
- [ ] **Step 2: Run** and confirm FAIL.
- [ ] **Step 3: Implement** `pcardAdvHTML(gs: group[]) -> string`: one block per group sorted by PI date, first three open, remaining inside `<details><summary>+n more</summary>`; `Left = max(0, adjusted-basis required) ...` use `g.received - g.adjusted`; basis chip uses the existing `chip()` helper. Append it inside the `.pcard` article. Style: small grid, dark mode and 390px width as the other cards.
- [ ] **Step 4: Run** the tests. Expected: PASS.
- [ ] **Step 5: Commit** `git commit -am "feat: per-PI advance summary on the product card"`.

### Task 4: Regression, push, deliver

**Files:** `index.html`, `tests/`

- [ ] **Step 1: Run** every tab as admin and as a limited user (client without a brand hidden): no page errors, no `NaN`, Ledger and Payment Status numbers equal Daily Invoicing "Net receivable" for the same invoices.
- [ ] **Step 2: Run** `node tests/advance-basis.test.js`. Expected: all PASS.
- [ ] **Step 3: Push** `git push origin remove-sheet-and-refpo`, copy `index.html` to `/mnt/user-data/outputs/` and send it.

---

Self-review done against the spec: basis detection and override (Task 1, 2), required and adjustment on basis (Task 1), recalculation of old invoices (Task 1, nothing stored), product card lines with "+n more" (Task 3), non-goals untouched.
