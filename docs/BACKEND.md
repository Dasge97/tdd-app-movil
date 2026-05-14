# Backend — Symfony 7

## Stack

- **PHP 8.x** con atributos nativos
- **Symfony 7**
- **Doctrine ORM** con mapeo via atributos PHP 8
- **DBAL** para queries crudas donde ORM añade complejidad innecesaria
- **MySQL 8**

## Arquitectura en capas

```
HTTP Request
    │
    ▼
Controller          ← coordina, no tiene lógica
    │
    ▼
Service             ← toda la lógica de negocio vive aquí
    │
    ▼
Repository          ← única puerta a la base de datos
    │
    ▼
Doctrine / DBAL     ← acceso real a MySQL
```

### Reglas estrictas por capa

**Controller**
- Recibe el request, extrae parámetros, llama al Service, devuelve la respuesta
- Sin lógica de negocio
- Sin acceso a Repository directamente
- Sin SQL

**Service**
- Contiene toda la lógica de negocio
- Puede llamar a varios Repositories
- Lanza excepciones de dominio (no HttpException)
- No conoce la capa HTTP (no maneja Request ni Response)

**Repository**
- Única puerta a la BD
- Sin lógica de negocio
- Métodos descriptivos: `findActiveByUserId()`, `countCommentsByDebate()`, etc.
- Usa Doctrine para operaciones simples, DBAL para queries complejas

**Entidades Doctrine**
- Mapeo de datos puro
- Sin lógica de negocio
- Sin dependencias externas

## Autenticación

- JWT propio sin bundle externo
- Access token: vida corta (15 minutos)
- Refresh token: vida larga (30 días) con rotación en cada uso
- Revocación via tabla `revoked_tokens` (jti + expires_at)
- Header: `Authorization: Bearer <token>`

## Idempotencia

Aplicada en operaciones donde un retry de red generaría duplicados:

| Endpoint | Idempotencia |
|---|---|
| `POST /debates` | Sí — SHA-256(body + userId + endpoint) |
| `POST /comments` | Sí |
| `POST /chat/messages` | Sí |
| `POST /favorites` | No — UPSERT nativo |
| `POST /positions` | No — UPSERT nativo |
| `POST /votes` | No — UPSERT nativo |
| `POST /friends` | No — UNIQUE constraint |

**Implementación**: tabla `idempotency_keys` con hash, response cacheada y TTL. Si llega un request con hash existente y reciente, se devuelve la response cacheada sin reejecutar.

El cliente (Flutter) genera un UUID por operación y lo envía en header `Idempotency-Key`. El servidor hace SHA-256 del UUID + userId para construir la clave interna.

## Shadow ban

Sistema automático de moderación de comunidad. Sin intervención manual salvo override de admin.

### Trigger (las tres condiciones deben cumplirse)
1. `reliability_score ≤ -10`
2. Al menos 5 comentarios en los últimos 30 días
3. ≥ 40% de esos comentarios con score negativo

### Mecánica del reliability_score
- Upvote recibido en un comentario → `+1` al score del autor
- Downvote recibido → `-1` al score del autor
- Floor: `-50` (siempre hay camino de vuelta)
- Se evalúa en cada operación de voto via el `VoteService`

### Comportamiento del ban
- Campo `is_shadow_banned = true` en tabla `users`
- El usuario ve sus propios comentarios con normalidad (no sabe que está baneado)
- Para el resto: `GET /debates/{id}/comments` filtra comentarios de usuarios baneados
- Excepción: las respuestas a sus comentarios sí aparecen (preserva integridad de hilos)
- Sin notificación al usuario

### Levantamiento automático
- Job programado (revisión cada 7 días via Symfony Scheduler o comando cron)
- Si el promedio de score de los últimos 7 días ≥ 0 → `reliability_score += 5`
- Si con ese boost `reliability_score > -10` → `is_shadow_banned = false`
- Admin puede levantar manualmente desde el panel

## Manejo de errores

Un solo `EventSubscriber` (`KernelExceptionSubscriber`) captura todas las excepciones y devuelve siempre JSON:

```json
{
  "error": "Descripción del error",
  "code": "DEBATE_NOT_FOUND"
}
```

Las excepciones de dominio (lanzadas en Services) se mapean a códigos HTTP en el subscriber. El resto devuelve 500.

## WebSocket — Ratchet

Chat DM y notificaciones en tiempo real se implementan con **Ratchet**, que corre como un comando de consola de Symfony:

```bash
php bin/console app:websocket-server
```

Proceso separado pero con acceso completo al DI container, servicios y repositorios de Symfony. Sin ReactPHP ni Swoole.

- **Chat**: conexión bidireccional para mensajes DM
- **Notificaciones**: se entregan por el mismo canal WebSocket cuando el usuario tiene conexión activa. Si no, el cliente las lee via REST al abrir la app.
- Puerto: configurable via variable de entorno (por defecto 8080)

En docker-compose: `backend` (HTTP, puerto 3000) + `backend-ws` (Ratchet, puerto 8080), mismo código, distinto comando.

## Panel admin

Twig + Bootstrap 5, servido por el propio backend Symfony. Sin EasyAdmin ni framework JS. Controllers admin protegidos por middleware de rol `admin`.

Funcionalidades: worker config, historial de runs, auditoría, moderación de contenido, gestión de usuarios, perfiles IA.

## Endpoints principales

### Auth
- `POST /api/v1/auth/register`
- `POST /api/v1/auth/login`
- `POST /api/v1/auth/refresh`
- `POST /api/v1/auth/logout`

### Debates
- `GET /api/v1/debates/today`
- `GET /api/v1/debates/trending`
- `GET /api/v1/debates/{id}`
- `GET /api/v1/debates/search`
- `POST /api/v1/debates` (propuesta de usuario)

### Participación
- `POST /api/v1/debates/{id}/positions`
- `GET /api/v1/debates/{id}/positions`
- `POST /api/v1/debates/{id}/comments`
- `GET /api/v1/debates/{id}/comments`
- `POST /api/v1/comments/{id}/vote`

### Social
- `GET /api/v1/users/{username}`
- `PUT /api/v1/users/me`
- `GET /api/v1/users/me/favorites`
- `POST /api/v1/favorites/{debateId}`
- `DELETE /api/v1/favorites/{debateId}`
- `GET /api/v1/friends`
- `POST /api/v1/friends/{userId}`
- `PUT /api/v1/friends/{userId}/accept`
- `DELETE /api/v1/friends/{userId}`

### Chat
- `GET /api/v1/chat/conversations`
- `GET /api/v1/chat/conversations/{id}/messages`
- `POST /api/v1/chat/conversations/{id}/messages`
- WebSocket: `ws://host/ws/chat`

### Notificaciones
- `GET /api/v1/notifications`
- `PUT /api/v1/notifications/{id}/read`
- `PUT /api/v1/notifications/read-all`

### Perfiles IA
- `GET /api/v1/personas` — lista de perfiles IA
- `GET /api/v1/personas/{username}/debates` — debates de un perfil

### Admin
- `GET /api/v1/admin/worker/config`
- `PUT /api/v1/admin/worker/config`
- `POST /api/v1/admin/worker/trigger`
- `GET /api/v1/admin/worker/runs` — historial de ejecuciones
- `GET /api/v1/admin/audit-log`
- `GET /api/v1/admin/users`
- `PUT /api/v1/admin/users/{id}/status`

### Worker (uso interno)
- `POST /api/v1/worker/publish` — el worker publica los 5 debates del día
