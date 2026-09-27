-- Apply in the Supabase SQL Editor. CREATE IF NOT EXISTS avoids duplicating tables.
create table if not exists public.profiles (
    id uuid primary key references auth.users(id) on delete cascade,
    name text not null default '',
    created_at timestamptz not null default now()
);

create table if not exists public.listings (
    id uuid primary key default gen_random_uuid(),
    seller_id uuid not null references public.profiles(id) on delete cascade,
    title text not null,
    description text not null default '',
    category text not null,
    condition text not null,
    price numeric(12, 2) not null check (price >= 0),
    currency text not null default 'INR',
    image_url text,
    status text not null default 'available'
        check (status in ('available', 'reserved', 'sold', 'removed')),
    created_at timestamptz not null default now()
);

create table if not exists public.components (
    id uuid primary key default gen_random_uuid(),
    listing_id uuid not null references public.listings(id) on delete cascade,
    component_name text not null,
    brand text,
    model text,
    condition text not null,
    compatibility text,
    created_at timestamptz not null default now()
);

create index if not exists listings_status_created_at_idx
    on public.listings (status, created_at desc);
create index if not exists listings_seller_id_idx on public.listings (seller_id);
create index if not exists listings_category_idx on public.listings (category);
create index if not exists components_listing_id_idx on public.components (listing_id);
create index if not exists components_component_name_idx on public.components (component_name);

alter table public.profiles enable row level security;
alter table public.listings enable row level security;
alter table public.components enable row level security;

-- RLS policies are permissive-combined, so replace prior policies on these tables.
do $$
declare
    existing_policy record;
begin
    for existing_policy in
        select p.polname, c.relname
        from pg_policy p
        join pg_class c on c.oid = p.polrelid
        join pg_namespace n on n.oid = c.relnamespace
        where n.nspname = 'public'
          and c.relname in ('profiles', 'listings', 'components')
    loop
        execute format(
            'drop policy %I on public.%I',
            existing_policy.polname,
            existing_policy.relname
        );
    end loop;
end;
$$;

create policy "Authenticated users can read profiles"
    on public.profiles for select to authenticated using (true);
create policy "Users can create their own profile"
    on public.profiles for insert to authenticated with check (id = (select auth.uid()));
create policy "Users can update their own profile"
    on public.profiles for update to authenticated
    using (id = (select auth.uid())) with check (id = (select auth.uid()));

create policy "Authenticated users can read available listings"
    on public.listings for select to authenticated
    using (status = 'available' or seller_id = (select auth.uid()));
create policy "Users can create their own listings"
    on public.listings for insert to authenticated
    with check (seller_id = (select auth.uid()));
create policy "Users can update their own listings"
    on public.listings for update to authenticated
    using (seller_id = (select auth.uid()))
    with check (seller_id = (select auth.uid()));
create policy "Users can delete their own listings"
    on public.listings for delete to authenticated
    using (seller_id = (select auth.uid()));

create policy "Users can read available listing components"
    on public.components for select to authenticated
    using (exists (
        select 1 from public.listings l
        where l.id = listing_id
          and (l.status = 'available' or l.seller_id = (select auth.uid()))
    ));
create policy "Owners can create listing components"
    on public.components for insert to authenticated
    with check (exists (
        select 1 from public.listings l
        where l.id = listing_id and l.seller_id = (select auth.uid())
    ));
create policy "Owners can update listing components"
    on public.components for update to authenticated
    using (exists (
        select 1 from public.listings l
        where l.id = listing_id and l.seller_id = (select auth.uid())
    ))
    with check (exists (
        select 1 from public.listings l
        where l.id = listing_id and l.seller_id = (select auth.uid())
    ));
create policy "Owners can delete listing components"
    on public.components for delete to authenticated
    using (exists (
        select 1 from public.listings l
        where l.id = listing_id and l.seller_id = (select auth.uid())
    ));

create or replace function public.create_profile_for_auth_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
    insert into public.profiles (id, name)
    values (new.id, coalesce(new.raw_user_meta_data ->> 'name', ''))
    on conflict (id) do nothing;
    return new;
end;
$$;

drop trigger if exists create_profile_after_signup on auth.users;
create trigger create_profile_after_signup
    after insert on auth.users
    for each row execute function public.create_profile_for_auth_user();