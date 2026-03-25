# Login Fish Clicks (Backend + Godot)

Este documento reemplaza las guias separadas de JWT/Godot para el login.

## Estado actual

- Login: implementado en `POST /auth/login`.
- Registro: implementado en `POST /auth/register`.
- JWT: implementado y validado por filtro (`Authorization: Bearer <token>`).
- Logout: no existe endpoint dedicado en backend.
  - El backend usa sesiones stateless con JWT.
  - El logout actual se hace en cliente borrando el token guardado.

## Variables de entorno necesarias

```bash
SPRING_DATASOURCE_URL=jdbc:postgresql://<host>:5432/<db>?sslmode=require
SPRING_DATASOURCE_USERNAME=<usuario>
SPRING_DATASOURCE_PASSWORD=<password>
JWT_SECRET=<secreto-largo>
```

## Endpoint de login

- Metodo: `POST`
- URL: `/auth/login`
- Publico: si (permitAll en seguridad)
- Content-Type: `application/json`

### Request JSON

Puedes enviar `nickname` o `email` como identificador:

```json
{
  "nickname": "pepe",
  "password": "mi_password"
}
```

O:

```json
{
  "email": "pepe@fishclicks.com",
  "password": "mi_password"
}
```

### Response OK (200)

```json
{
  "token": "<jwt>",
  "userId": "<uuid>"
}
```

## Endpoint de registro

- Metodo: `POST`
- URL: `/auth/register`
- Publico: si (permitAll en seguridad)
- Content-Type: `application/json`

### Request JSON

```json
{
  "email": "pepe@fishclicks.com",
  "nickname": "pepe",
  "password": "mi_password"
}
```

### Response OK (200)

Devuelve el usuario recien creado autenticado (token + userId):

```json
{
  "token": "<jwt>",
  "userId": "<uuid>"
}
```

## Importante sobre contrasenas

Actualmente el backend compara texto plano contra `contrasena.password_hash`.

- Si en BD guardas hash real (bcrypt/argon), asi no va a validar.
- Para produccion, hay que migrar a `PasswordEncoder` (bcrypt) y comparar hash.

## Esquema de BD esperado por login

- Tabla `cuenta`: `uid (uuid)`, `email`, `nickname`, `foto`, `created_at`, `updated_at`
- Tabla `contrasena`: `id`, `cuenta_uid (uuid)`, `password_hash`, `is_active`, `created_at`
- Relacion: `contrasena.cuenta_uid -> cuenta.uid`

## Uso desde Godot

1. Capturar campos de UI: correo/nickname y contrasena.
2. Para entrar, hacer POST a `http://<host-backend>:8080/auth/login` con JSON.
3. Para crear cuenta, hacer POST a `http://<host-backend>:8080/auth/register` con JSON.
4. Si responde 200, guardar `token` y `userId`.
5. En llamadas protegidas, enviar header:

```http
Authorization: Bearer <token>
```

6. Para logout en cliente:
   - borrar token en memoria/disco,
   - volver a pantalla de login.

## Prueba rapida con curl

```bash
curl -X POST http://localhost:8080/auth/login \
  -H "Content-Type: application/json" \
  -d '{"nickname":"pepe","password":"mi_password"}'
```

Registro:

```bash
curl -X POST http://localhost:8080/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"pepe@fishclicks.com","nickname":"pepe","password":"mi_password"}'
```

## Errores comunes

- `Usuario no encontrado`: el `nickname`/`email` no existe en `cuenta`.
- `Usuario sin contrasena activa`: no hay fila en `contrasena` con `is_active=true`.
- `Contrasena incorrecta`: no coincide con `password_hash` actual.
- Error de schema al arrancar: revisar nombres exactos de tablas/columnas.

