-- Jalankan di SQL Editor project Supabase.
-- Buat bucket "photo-previews" sebagai PUBLIC untuk gambar pratinjau ber-watermark.
-- Buat bucket "photo-originals" sebagai PRIVATE untuk file asli berbayar.

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  role text not null default 'user' check (role in ('user','admin')),
  created_at timestamptz not null default now()
);

create table if not exists public.photos (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text,
  price_rupiah integer not null check (price_rupiah >= 0),
  preview_url text not null,
  preview_path text not null,
  original_path text,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;
alter table public.photos enable row level security;

create or replace function public.is_shankara_admin()
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin'
  );
$$;

create policy "profiles read own or admin"
on public.profiles for select
using (id = auth.uid() or public.is_shankara_admin());

create policy "photos visible when active"
on public.photos for select
using (is_active = true or public.is_shankara_admin());

create policy "admin insert photos"
on public.photos for insert
with check (public.is_shankara_admin());

create policy "admin update photos"
on public.photos for update
using (public.is_shankara_admin())
with check (public.is_shankara_admin());

create policy "admin delete photos"
on public.photos for delete
using (public.is_shankara_admin());

-- PENTING:
-- Setelah akun pemilik didaftarkan melalui aplikasi, jalankan perintah berikut
-- dengan UUID akun pemilik yang benar dari Authentication > Users.
-- Jangan pernah menjadikan role admin dari aplikasi publik.
-- update public.profiles set role = 'admin' where id = 'UUID-AKUN-PEMILIK';

-- Trigger otomatis membuat profil user baru.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, role)
  values (new.id, 'user')
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();
