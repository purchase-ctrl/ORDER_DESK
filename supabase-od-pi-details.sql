-- ============================================================
-- Order Desk: let every Order Desk login read the PI details it needs
-- (items with rate / quantity / advance %, notes / payment terms, reference PO, cancelled date).
-- Run ONCE in Supabase (SQL Editor -> New query -> paste -> Run). Safe to re-run.
-- Why: the pis table only shows a login the PIs it created itself, so the
-- admin's Order Desk login could not see other people's PIs.
-- ============================================================
drop function if exists public.od_pi_details();
create function public.od_pi_details()
returns table (
  pi_number text,
  company text,
  buyer_name text,
  buyer_gst text,
  pi_date date,
  created_at timestamptz,
  notes text,
  payment_terms text,
  ref_po text,
  cancelled_at timestamptz,
  items jsonb
)
language sql
security definer
set search_path = public
as $$
  select pi_number, company, buyer_name, buyer_gst, pi_date, created_at, notes, payment_terms, ref_po, cancelled_at, items
  from public.pis
  order by created_at asc;
$$;
revoke all on function public.od_pi_details() from public;
grant execute on function public.od_pi_details() to authenticated;
