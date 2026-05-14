# Arquitectura general

## Visión de conjunto

```
┌──────────────────────────────────────────────────────────────────┐
│                          CLIENTES                                │
│                                                                  │
│   App Flutter (iOS/Android)         Panel Admin (Twig+Bootstrap) │
└──────────┬──────────────────────────────────────┬───────────────┘
           │ REST + JWT                            │ REST + JWT
           │ WebSocket (chat + notif.)             │
           ▼                                       ▼
┌──────────────────────────┐     ┌─────────────────────────────────┐
│  BACKEND HTTP            │     │  BACKEND WS                     │
│  Symfony 7 — puerto 3000 │     │  Ratchet — puerto 8080          │
│                          │     │  (mismo código Symfony,         │
│  Controller → Service    │     │   distinto comando de consola)  │
│  → Repository → DB       │     │                                 │
│                          │     │  Chat DM · Notificaciones       │
└────────────┬─────────────┘     └──────────────┬──────────────────┘
             │                                  │
             └──────────────┬───────────────────┘
                            │
                            ▼
                 ┌──────────────────┐
                 │    MySQL 8       │
                 └──────────────────┘
                            ▲
                            │ POST /api/v1/worker/publish
┌───────────────────────────┴──────────────────────────────────────┐
│                        WORKER — Node.js                          │
│                                                                  │
│  Cron diario configurable desde panel admin                      │
│  4 prompts en sesión única opencode                              │
│  Genera 5 debates → publica via API backend                      │
└──────────────────────────────────────────────────────────────────┘
```

## Principios de diseño

### Backend
- **Stateless**: cada request es autónomo, sin sesión en servidor
- **Capas estrictas**: Controller no contiene lógica, Service no accede a BD directamente, Repository no contiene lógica de negocio
- **Un único punto de acceso a datos**: todo pasa por los Repositories
- **Excepciones globales**: un solo EventSubscriber maneja todos los errores y normaliza las respuestas de error
- **DI total**: ningún `new` manual, todo autowired por Symfony

### API REST
- Versionada: `/api/v1/`
- Bearer token en header `Authorization`
- JWT propio sin bundle externo
- Respuestas consistentes: siempre JSON con estructura predecible
- Idempotencia en operaciones con riesgo de duplicado (ver [BACKEND.md](BACKEND.md))

### Worker
- Proceso independiente del backend
- Lee su configuración (schedule, reglas, estado) desde la BD via API backend
- Inserta via API backend, nunca directo a BD — el backend es el único validador
- Una sola sesión opencode por ejecución diaria (contexto continuo entre los 4 prompts)

## Decisiones de arquitectura

| Decisión | Elegida | Alternativa descartada | Razón |
|---|---|---|---|
| App móvil | Flutter | React Native | Control total del pixel, rendimiento superior en listas largas, UI idéntica iOS/Android |
| Backend | PHP 8 + Symfony 7 | Node.js/Express | Arquitectura de capas más formal, DI nativa, ecosistema maduro para APIs REST |
| BD | MySQL 8 | PostgreSQL | Familiaridad del equipo, suficiente para el modelo de datos |
| Worker | Node.js | PHP | Mejor integración con el ecosistema opencode (JS nativo) |
| Pipeline editorial | Worker propio + opencode | n8n | Elimina dependencia externa, control total del flujo, más simple de mantener |
| Categorías | Perfiles IA con especialidad | Tags de categoría | Más social, genera identidad, descubrimiento orgánico |
| Cron | DB-driven via admin panel | systemd / cron SO | Configurable sin acceso al servidor, auditable, triggers manuales desde web |
