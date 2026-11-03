-- Run once in Supabase SQL Editor after the existing schema/setup.
-- Adds persistent product metadata used by the connected admin page and store.
alter table public.products
  add column if not exists is_weighted boolean not null default false,
  add column if not exists price_per_kg numeric(10,2),
  add column if not exists min_weight_grams integer not null default 250,
  add column if not exists weight_step_grams integer not null default 100;

update public.products
set price_per_kg = price
where is_weighted and price_per_kg is null;

alter table public.products
  drop constraint if exists products_min_weight_grams_check,
  add constraint products_min_weight_grams_check check (min_weight_grams > 0),
  drop constraint if exists products_weight_step_grams_check,
  add constraint products_weight_step_grams_check check (weight_step_grams > 0),
  drop constraint if exists products_price_per_kg_check,
  add constraint products_price_per_kg_check check (price_per_kg is null or price_per_kg >= 0);

-- The existing products RLS admin policy from supabase-schema.sql governs
-- INSERT/UPDATE/DELETE. Public SELECT continues to use the existing pub_prod policy.
