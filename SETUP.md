# Jimenez al fuego — Estado del backend y qué falta

## Ya está hecho y probado

- Proyecto Supabase: **Jiménez Al Fuego** (org "Jiménez Al Fuego", ref `fgxdffeujbmhpqwdfeyr`).
- Esquema completo corrido en producción: tablas `categorias`, `productos`, `mesas`, `pedidos`,
  `pedido_items`, `inventario`, `promociones`, `configuracion` (ver `supabase/schema.sql`).
- RLS activado y probado en todas las tablas (lectura pública solo de lo que debe ser público,
  todo lo demás solo para el admin logueado).
- Función `mesa_id_por_numero()` probada — resuelve el UUID de una mesa por su número sin exponer
  la tabla `mesas` completa.
- Bucket de Storage `productos` creado y probado (lectura pública, escritura solo admin).
- `index.html` ya tiene pegadas las credenciales reales (`SUPABASE_URL` / `SUPABASE_ANON_KEY`,
  cerca del principio del `<body>`, buscá "CONFIG SUPABASE"). Es la **publishable key**, pública
  por diseño — está bien que esté en el HTML.
- Probado en vivo: el menú del cliente carga los 3 productos reales directo desde Supabase
  (no el array hardcodeado), sin errores de consola, sin overflow horizontal.

## Lo único que falta: confirmar el usuario admin

Todavía no hay un usuario de Supabase Auth confirmado para entrar al panel. Pasó esto:

1. Se creó `mizaelbarja628@gmail.com` por error (después me pediste no usarlo — quedó creado
   pero **sin confirmar**, así que no sirve para loguearse; podés borrarlo desde el dashboard
   cuando quieras: Authentication → Users).
2. Se intentó crear `jimenezalfuego@gmail.com` (el correo de la cuenta de Supabase), pero
   Supabase bloqueó el envío del email de confirmación por **límite de emails por hora**
   (límite del plan gratis, no es un error del proyecto).

### Cómo terminarlo (elegí una opción)

**Opción A — la más rápida, sin esperar nada:**
En el dashboard de Supabase → **Authentication → Users → Add user**, cargá:
- Email: `jimenezalfuego@gmail.com` (o el que prefieras)
- Password: la que quieras (mínimo 6 caracteres)
- Marcá **"Auto Confirm User"**

Como es una acción de admin desde el dashboard, no manda email y no depende del límite. Quedás
pudiendo loguearte al toque.

**Opción B — esperar el límite de email:**
El límite de Supabase suele resetear en más o menos una hora. Después de esperar, cualquiera de
estos dos sirve:
- Volver a intentar "Add user" con Auto Confirm (opción A) — sigue siendo lo más simple.
- O pedirme que reintente el registro público (`/auth/v1/signup`) y confirmar haciendo clic en
  el link que llegue a esa casilla.

Una vez que tengas el usuario confirmado, entrás al panel (candado abajo a la derecha en la
página de Contacto, o `openAdminAccess()` en la consola) con ese correo y contraseña.

**Desde el panel, en Configuración**, podés cambiar el correo/contraseña del admin cuando
quieras (`supabase.auth.updateUser()`), así que el que uses ahora es solo para arrancar.

## Deploy (Netlify/Vercel)

Quedó para después, como acordamos. Cuando quieras hacerlo: conectá el repo de GitHub a Netlify
o Vercel (free tier), con `index.html` como raíz del sitio — cada `git push` publica solo.

## Notas de seguridad

- La `anon`/publishable key en `index.html` es pública por diseño (protegida por RLS). Nunca
  pegues ahí la `service_role`/secret key.
- RLS probado: un usuario no logueado puede leer categorías/productos activos y configuración,
  puede **crear** pedidos (para el checkout del cliente), pero no puede leer/editar pedidos,
  mesas, inventario ni promociones.
