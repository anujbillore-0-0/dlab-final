-- Coupons table for cart offers
create table if not exists public.coupons (
  id bigserial primary key,
  code text not null unique,
  title text not null,
  description text not null,
  discount_percentage integer not null,
  usage_count integer not null default 0,
  usage_limit integer not null,
  is_active boolean not null default true,
  starts_at timestamptz,
  expires_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint coupons_discount_range check (discount_percentage >= 1 and discount_percentage <= 100),
  constraint coupons_usage_limit_positive check (usage_limit > 0),
  constraint coupons_usage_count_non_negative check (usage_count >= 0)
);

create index if not exists idx_coupons_active_dates
  on public.coupons (is_active, starts_at, expires_at);

create or replace function public.set_coupons_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_coupons_set_updated_at on public.coupons;
create trigger trg_coupons_set_updated_at
before update on public.coupons
for each row
execute function public.set_coupons_updated_at();

-- Seed sample coupons (safe to re-run)
insert into public.coupons (
  code,
  title,
  description,
  discount_percentage,
  usage_limit,
  starts_at,
  expires_at
)
values
  ('DLAB12', 'DLAB12', '12% off your first order!', 12, 500, now(), now() + interval '90 days'),
  ('WEEKEND5', 'WEEKEND5', '5% off on weekend shopping.', 5, 300, now(), now() + interval '30 days'),
  ('SAVE20', 'SAVE20', 'Save 20% on selected products.', 20, 150, now(), now() + interval '60 days')
on conflict (code) do nothing;
