-- CineVerse Cloud
-- Cole este SQL no SQL Editor do seu projeto Supabase.
-- Depois crie um bucket PUBLIC chamado: cineverse-videos

create table if not exists public.cineverse_state (
  id bigint primary key,
  state jsonb not null,
  updated_at timestamptz not null default now()
);

alter table public.cineverse_state enable row level security;

-- Leitura pública para que qualquer visitante veja o catálogo.
drop policy if exists "CineVerse public read" on public.cineverse_state;
create policy "CineVerse public read"
on public.cineverse_state
for select
to anon, authenticated
using (true);

-- Escrita pública: necessária para o HTML estático conseguir sincronizar.
-- IMPORTANTE: o login Admin do HTML é uma proteção de interface, não uma
-- autenticação de servidor. Para segurança real, use uma Edge Function/Auth.
drop policy if exists "CineVerse public insert" on public.cineverse_state;
create policy "CineVerse public insert"
on public.cineverse_state
for insert
to anon, authenticated
with check (true);

drop policy if exists "CineVerse public update" on public.cineverse_state;
create policy "CineVerse public update"
on public.cineverse_state
for update
to anon, authenticated
using (true)
with check (true);

-- Storage: o bucket precisa existir e ser público.
insert into storage.buckets (id, name, public)
values ('cineverse-videos', 'cineverse-videos', true)
on conflict (id) do update set public = true;

-- Permite que o HTML envie vídeos para o bucket.
drop policy if exists "CineVerse video insert" on storage.objects;
create policy "CineVerse video insert"
on storage.objects
for insert
to anon, authenticated
with check (bucket_id = 'cineverse-videos');

-- Permite atualizar/repetir uploads com o mesmo objeto.
drop policy if exists "CineVerse video update" on storage.objects;
create policy "CineVerse video update"
on storage.objects
for update
to anon, authenticated
using (bucket_id = 'cineverse-videos')
with check (bucket_id = 'cineverse-videos');

-- Leitura pelo Storage API. O bucket público também permite a URL pública.
drop policy if exists "CineVerse video select" on storage.objects;
create policy "CineVerse video select"
on storage.objects
for select
to anon, authenticated
using (bucket_id = 'cineverse-videos');
