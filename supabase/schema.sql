-- ============================================================
-- Jimenez al fuego — schema de Supabase (Postgres)
-- ============================================================
-- Cómo usarlo:
--   1. Crear un proyecto nuevo en https://supabase.com
--   2. Ir a "SQL Editor" > "New query"
--   3. Pegar este archivo completo y ejecutarlo (Run) UNA sola vez
--      (contiene datos semilla: categorías y productos reales del
--      negocio, y las 3 filas de configuración iniciales)
--   4. Ir a "Project Settings" > "API" y copiar Project URL + anon public key
--      para pegarlas en index.html (ver bloque CONFIG SUPABASE cerca del
--      principio del <body>, buscá SUPABASE_URL / SUPABASE_ANON_KEY)
--   5. Crear el primer usuario admin real: "Authentication" > "Users" >
--      "Add user" > email + password (ver SETUP.md para el detalle)
-- ============================================================

create extension if not exists "pgcrypto";

-- ---------- CATEGORIAS ----------
create table if not exists categorias (
  id uuid primary key default gen_random_uuid(),
  nombre text not null,
  slug text not null unique,
  orden integer not null default 0,
  activa boolean not null default true,
  created_at timestamptz not null default now()
);

-- ---------- PRODUCTOS ----------
create table if not exists productos (
  id uuid primary key default gen_random_uuid(),
  categoria_id uuid references categorias(id) on delete set null,
  nombre text not null,
  descripcion text not null default '',
  descripcion_larga text not null default '',
  precio numeric(10,2) not null default 0,
  imagen_url text not null default '',
  incluye jsonb not null default '[]'::jsonb,
  badge text not null default '',
  activo boolean not null default true,
  orden integer not null default 0,
  created_at timestamptz not null default now()
);
create index if not exists idx_productos_categoria on productos(categoria_id);

-- ---------- MESAS ----------
-- "numero" es texto (no autonumérico puro) porque el dueño debe poder
-- escribirlo manualmente y nombrarlas distinto (ej. "01", "VIP-1", "Terraza 3").
create table if not exists mesas (
  id uuid primary key default gen_random_uuid(),
  numero text not null unique,
  estado text not null default 'libre' check (estado in ('libre','ocupada','reservada')),
  qr_token uuid not null default gen_random_uuid(),
  created_at timestamptz not null default now()
);

-- ---------- PEDIDOS ----------
create table if not exists pedidos (
  id uuid primary key default gen_random_uuid(),
  mesa_id uuid references mesas(id) on delete set null,
  estado text not null default 'nuevo' check (estado in ('nuevo','preparando','listo','entregado','cancelado')),
  subtotal numeric(10,2) not null default 0,
  total numeric(10,2) not null default 0,
  created_at timestamptz not null default now()
);
create index if not exists idx_pedidos_estado on pedidos(estado);
create index if not exists idx_pedidos_created on pedidos(created_at desc);

-- ---------- PEDIDO_ITEMS ----------
-- "producto_nombre"/"precio_unitario" quedan como snapshot del momento del
-- pedido, así un pedido viejo no cambia si después editás el producto.
create table if not exists pedido_items (
  id uuid primary key default gen_random_uuid(),
  pedido_id uuid not null references pedidos(id) on delete cascade,
  producto_id uuid references productos(id) on delete set null,
  producto_nombre text not null,
  cantidad integer not null default 1 check (cantidad > 0),
  precio_unitario numeric(10,2) not null default 0
);
create index if not exists idx_pedido_items_pedido on pedido_items(pedido_id);

-- ---------- INVENTARIO ----------
create table if not exists inventario (
  id uuid primary key default gen_random_uuid(),
  producto_id uuid references productos(id) on delete set null,
  insumo text not null,
  stock_actual numeric(10,2) not null default 0,
  stock_minimo numeric(10,2) not null default 0,
  unidad text not null default 'unidad',
  created_at timestamptz not null default now()
);

-- ---------- PROMOCIONES ----------
create table if not exists promociones (
  id uuid primary key default gen_random_uuid(),
  titulo text not null,
  descripcion text not null default '',
  descuento numeric(10,2) not null default 0,
  activa boolean not null default true,
  fecha_inicio date,
  fecha_fin date,
  created_at timestamptz not null default now()
);

-- ---------- CONFIGURACION (key-value) ----------
create table if not exists configuracion (
  clave text primary key,
  valor text not null default ''
);

insert into configuracion (clave, valor) values
  ('whatsapp_numero', '59175074933'),
  ('horario', '7 PM – 12 AM'),
  ('instagram_url', 'https://www.instagram.com/jimenez.al.fuego'),
  ('tiktok_url', 'https://www.tiktok.com/@jimenez_al_fuego')
on conflict (clave) do nothing;

-- ---------- DATOS REALES DEL NEGOCIO (semilla, una sola vez) ----------
insert into categorias (nombre, slug, orden, activa) values
  ('Espetinhos','espetinhos',1,true),
  ('Guarniciones','guarniciones',2,true),
  ('Bebidas','bebidas',3,true),
  ('Promociones','promociones',4,true),
  ('Extras','extras',5,true)
on conflict (slug) do nothing;

-- imagen_url queda vacío a propósito: el frontend usa como respaldo la foto
-- original embebida en el HTML mientras no subas una foto nueva desde el panel.
insert into productos (categoria_id, nombre, descripcion, descripcion_larga, precio, badge, incluye, activo, orden)
select id,
  'Espetinho de pollo con tocino',
  'Brocheta de pollo jugoso envuelto en tocino, asada al carbón.',
  'Brocheta de pollo jugoso envuelto en tocino, asada al carbón al punto perfecto.',
  25, 'MÁS PEDIDO',
  '[{"label":"Arroz"},{"label":"Yuca"},{"label":"Vinagreta"},{"label":"Farofa"}]'::jsonb,
  true, 1
from categorias where slug = 'espetinhos'
and not exists (select 1 from productos where nombre = 'Espetinho de pollo con tocino');

insert into productos (categoria_id, nombre, descripcion, descripcion_larga, precio, badge, incluye, activo, orden)
select id,
  'Espetinho de jiba',
  'Brocheta de carne 100% res, marinada y asada estilo brasileño.',
  'Brocheta de carne 100% res, marinada y asada al carbón estilo brasileño.',
  19, '',
  '[{"label":"Arroz"},{"label":"Yuca"},{"label":"Vinagreta"},{"label":"Farofa"}]'::jsonb,
  true, 2
from categorias where slug = 'espetinhos'
and not exists (select 1 from productos where nombre = 'Espetinho de jiba');

insert into productos (categoria_id, nombre, descripcion, descripcion_larga, precio, badge, incluye, activo, orden)
select id,
  'Guarnición de chorizo',
  'Chorizo a la parrilla.',
  'Chorizo a la parrilla, con el toque ahumado característico de las brasas.',
  8, '',
  '[]'::jsonb,
  true, 1
from categorias where slug = 'guarniciones'
and not exists (select 1 from productos where nombre = 'Guarnición de chorizo');

-- 20 mesas sugeridas por defecto (numeradas '01'..'20'); el dueño puede
-- agregar más o renombrarlas desde el panel sin ningún límite técnico.
insert into mesas (numero)
select lpad(n::text, 2, '0') from generate_series(1,20) as n
on conflict (numero) do nothing;

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================
alter table categorias    enable row level security;
alter table productos     enable row level security;
alter table mesas         enable row level security;
alter table pedidos       enable row level security;
alter table pedido_items  enable row level security;
alter table inventario    enable row level security;
alter table promociones   enable row level security;
alter table configuracion enable row level security;

-- ---------- categorias: lectura pública solo activas, CRUD admin ----------
create policy "public_select_categorias_activas" on categorias
  for select to anon, authenticated using (activa = true);
create policy "admin_select_categorias" on categorias
  for select to authenticated using (true);
create policy "admin_write_categorias" on categorias
  for insert to authenticated with check (true);
create policy "admin_update_categorias" on categorias
  for update to authenticated using (true) with check (true);
create policy "admin_delete_categorias" on categorias
  for delete to authenticated using (true);

-- ---------- productos: lectura pública solo activos, CRUD admin ----------
create policy "public_select_productos_activos" on productos
  for select to anon, authenticated using (activo = true);
create policy "admin_select_productos" on productos
  for select to authenticated using (true);
create policy "admin_write_productos" on productos
  for insert to authenticated with check (true);
create policy "admin_update_productos" on productos
  for update to authenticated using (true) with check (true);
create policy "admin_delete_productos" on productos
  for delete to authenticated using (true);

-- ---------- configuracion: lectura pública (footer/whatsapp), CRUD admin ----------
create policy "public_select_configuracion" on configuracion
  for select to anon, authenticated using (true);
create policy "admin_write_configuracion" on configuracion
  for insert to authenticated with check (true);
create policy "admin_update_configuracion" on configuracion
  for update to authenticated using (true) with check (true);
create policy "admin_delete_configuracion" on configuracion
  for delete to authenticated using (true);

-- ---------- mesas: SIN lectura pública directa (ver función RPC abajo) ----------
create policy "admin_select_mesas" on mesas
  for select to authenticated using (true);
create policy "admin_write_mesas" on mesas
  for insert to authenticated with check (true);
create policy "admin_update_mesas" on mesas
  for update to authenticated using (true) with check (true);
create policy "admin_delete_mesas" on mesas
  for delete to authenticated using (true);

-- ---------- pedidos: cliente anónimo SOLO puede crear (checkout público);
-- leer/editar/borrar pedidos queda restringido al admin autenticado ----------
create policy "public_insert_pedidos" on pedidos
  for insert to anon, authenticated with check (estado = 'nuevo');
create policy "admin_select_pedidos" on pedidos
  for select to authenticated using (true);
create policy "admin_update_pedidos" on pedidos
  for update to authenticated using (true) with check (true);
create policy "admin_delete_pedidos" on pedidos
  for delete to authenticated using (true);

-- ---------- pedido_items: mismo criterio que pedidos ----------
create policy "public_insert_pedido_items" on pedido_items
  for insert to anon, authenticated with check (cantidad > 0 and precio_unitario >= 0);
create policy "admin_select_pedido_items" on pedido_items
  for select to authenticated using (true);
create policy "admin_update_pedido_items" on pedido_items
  for update to authenticated using (true) with check (true);
create policy "admin_delete_pedido_items" on pedido_items
  for delete to authenticated using (true);

-- ---------- inventario: 100% privado, solo admin ----------
create policy "admin_select_inventario" on inventario
  for select to authenticated using (true);
create policy "admin_write_inventario" on inventario
  for insert to authenticated with check (true);
create policy "admin_update_inventario" on inventario
  for update to authenticated using (true) with check (true);
create policy "admin_delete_inventario" on inventario
  for delete to authenticated using (true);

-- ---------- promociones: 100% privado, solo admin (el menú público de
-- "Promociones" sigue en "Próximamente" hasta que haya promos reales) ----------
create policy "admin_select_promociones" on promociones
  for select to authenticated using (true);
create policy "admin_write_promociones" on promociones
  for insert to authenticated with check (true);
create policy "admin_update_promociones" on promociones
  for update to authenticated using (true) with check (true);
create policy "admin_delete_promociones" on promociones
  for delete to authenticated using (true);

-- ============================================================
-- FUNCIÓN RPC: resolver mesa_id sin exponer la tabla mesas completa
-- ============================================================
-- El QR de una mesa abre el menú con ?mesa=01. El cliente (anónimo) necesita
-- poder averiguar el mesa_id real para asociarlo al pedido, sin que la tabla
-- mesas (estados, tokens de todas las mesas) quede legible públicamente.
create or replace function public.mesa_id_por_numero(p_numero text)
returns uuid
language sql
security definer
set search_path = public
stable
as $$
  select id from mesas where numero = p_numero limit 1;
$$;

grant execute on function public.mesa_id_por_numero(text) to anon, authenticated;

-- ============================================================
-- STORAGE: bucket público de fotos de productos
-- ============================================================
insert into storage.buckets (id, name, public)
values ('productos', 'productos', true)
on conflict (id) do nothing;

create policy "public_read_productos_bucket" on storage.objects
  for select to anon, authenticated using (bucket_id = 'productos');
create policy "admin_upload_productos_bucket" on storage.objects
  for insert to authenticated with check (bucket_id = 'productos');
create policy "admin_update_productos_bucket" on storage.objects
  for update to authenticated using (bucket_id = 'productos') with check (bucket_id = 'productos');
create policy "admin_delete_productos_bucket" on storage.objects
  for delete to authenticated using (bucket_id = 'productos');
