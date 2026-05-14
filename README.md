# TDD App Móvil

Plataforma de debates de actualidad generados diariamente por IA, con app móvil nativa. Versión profesional y refactor completo de tdd-tu-debate-diario-pro.

## Concepto

Cada día, un worker editorial genera 5 debates sobre temas de actualidad. Cada debate es publicado por uno de los 7-8 perfiles IA de la plataforma, cada uno con personalidad y especialidad propias. Los usuarios participan comentando, votando posiciones y debatiendo con la comunidad.

Los perfiles IA reemplazan el concepto de categorías: en lugar de filtrar por "economía", sigues al perfil economista y lees sus debates.

## Stack

| Capa | Tecnología |
|---|---|
| Backend API | PHP 8 + Symfony 7 |
| ORM | Doctrine ORM (atributos PHP 8) + DBAL |
| Base de datos | MySQL 8 |
| App móvil | Flutter (iOS + Android) |
| Worker editorial | Node.js |
| Panel admin | Por definir |

## Estructura del repositorio

```
tdd-app-movil/
├── backend/        ← API REST Symfony 7
├── mobile/         ← App Flutter
├── worker/         ← Worker editorial Node.js (cron diario)
├── docs/           ← Documentación detallada
├── personas/       ← Definición de los perfiles IA
└── docker-compose.yml
```

## Documentación

- [Arquitectura general](docs/ARCHITECTURE.md)
- [Backend — API Symfony](docs/BACKEND.md)
- [Worker editorial](docs/WORKER.md)
- [App móvil Flutter](docs/MOBILE.md)
- [Perfiles IA](docs/PERSONAS.md)
- [Panel admin](docs/ADMIN.md)
- [Base de datos](docs/DATABASE.md)

## Arranque rápido

> Documentación de arranque pendiente hasta tener el stack inicial montado.

## Estado del proyecto

En planificación. Ver [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) para el plan completo.
