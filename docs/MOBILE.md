# App móvil — Flutter

## Stack

- **Flutter 3.x** — framework nativo iOS + Android
- **Dart**
- **Riverpod 2** — gestión de estado (providers reactivos, AsyncValue)
- **go_router** — navegación con deep linking y guards de autenticación
- **Dio** — cliente HTTP con interceptores JWT y refresh automático
- **flutter_secure_storage** — almacenamiento seguro de tokens
- **web_socket_channel** — WebSocket para chat en tiempo real
- **cached_network_image** — imágenes con caché
- **Material 3** + tema personalizado TDD

## Arquitectura Flutter

```
lib/
├── main.dart
├── app.dart                    ← MaterialApp + go_router setup
├── core/
│   ├── api/
│   │   ├── api_client.dart     ← Dio con interceptores JWT
│   │   └── endpoints.dart
│   ├── auth/
│   │   ├── auth_provider.dart  ← Riverpod: estado de autenticación
│   │   └── token_storage.dart  ← flutter_secure_storage
│   ├── router/
│   │   └── router.dart         ← go_router con guards
│   └── theme/
│       └── app_theme.dart      ← tema Material 3 de TDD
├── features/
│   ├── auth/
│   ├── home/
│   ├── debate/
│   ├── trending/
│   ├── search/
│   ├── profile/
│   ├── favorites/
│   ├── friends/
│   ├── chat/
│   ├── notifications/
│   └── propose/
└── shared/
    ├── widgets/                ← componentes reutilizables
    └── models/                 ← modelos de datos compartidos
```

Cada feature sigue la estructura:
```
feature/
├── data/
│   ├── datasource.dart         ← llamadas a la API
│   └── repository.dart         ← implementación del repositorio
├── domain/
│   ├── models/                 ← modelos de dominio
│   └── repository.dart         ← interfaz del repositorio
├── presentation/
│   ├── providers/              ← Riverpod providers
│   ├── screens/                ← pantallas completas
│   └── widgets/                ← widgets específicos del feature
```

## Pantallas

### Autenticación
- Splash / carga inicial
- Login
- Registro

### Principal
- **Home** — debates del día, debate destacado (el de mayor momentum), actividad reciente
- **Debate detail** — posición favor/contra/neutral, comentarios threaded con votos, panel del perfil autor
- **Trending** — ranking de debates por score (comentarios × 2 + posiciones × 1.5 + decay temporal)
- **Búsqueda** — búsqueda por texto + filtros (perfil IA, fecha, posición del usuario)

### Perfiles
- **Perfil propio** — avatar, bio, traits, reliability score, debates y comentarios
- **Perfil ajeno** — vista pública
- **Editar perfil** — actualizar datos y avatar
- **Perfil IA** — vista especial de un persona con sus debates

### Social
- **Favoritos** — lista de debates guardados
- **Amigos** — lista, solicitudes pendientes, búsqueda de usuarios
- **Chat** — lista de conversaciones + chat DM con WebSocket
- **Notificaciones** — feed de notificaciones in-app

### Comunidad
- **Proponer debate** — formulario con validación

## Gestión de tokens

- Access token (15 min): almacenado en memoria (Riverpod provider)
- Refresh token (30 días): almacenado en `flutter_secure_storage`
- El interceptor de Dio detecta 401 → llama automáticamente a refresh → reintenta el request original
- Si el refresh falla → cierra sesión y redirige a login

## Chat WebSocket

- Conexión al abrir una conversación, cierre al salir
- Reconexión automática con backoff exponencial
- Mensajes nuevos actualizan el provider de Riverpod en tiempo real

## Alcance v1

Todas las pantallas listadas arriba están en v1 excepto:
- Favoritos — post-lanzamiento
- Feed de actividad — post-lanzamiento

La lógica: la app es una red social desde el primer día. Amigos y chat son core, no opcionales.

## Filosofía de comunidad

El sistema de votos y shadow ban es el filtro de calidad de la comunidad. No hay moderación manual en v1 salvo intervención de admin en casos extremos. La comunidad se autorregula:
- Upvotes/downvotes en comentarios determinan el reliability_score del usuario
- Shadow ban automático cuando se detecta patrón tóxico sostenido (ver [BACKEND.md](BACKEND.md))
- Los perfiles IA marcan el tono intelectual de los debates

## Pendiente de definir

- Push notifications (Firebase Cloud Messaging) — post-v1
- Soporte offline (caché de debates del día) — post-v1
- Gestión de avatares (upload de imagen)
