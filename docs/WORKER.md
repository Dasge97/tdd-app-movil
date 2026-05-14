# Worker Editorial — Node.js

## Propósito

Proceso independiente que se ejecuta una vez al día y genera los 5 debates de la plataforma usando IA via opencode. Reemplaza completamente el pipeline n8n + filesystem del proyecto de referencia.

## Stack

- **Node.js** (ESM)
- **opencode CLI** — gestiona la sesión de IA
- **mysql2** — conexión directa a BD solo para queries de contexto pre-sesión
- **node-fetch / axios** — llamadas a la API del backend para publicar

## Estructura de archivos

```
worker/
├── src/
│   ├── index.js            ← entrada: lee config, decide si ejecutar
│   ├── runner.js           ← orquesta el flujo completo
│   ├── db.js               ← conexión MySQL (solo lectura de contexto)
│   ├── personas.js         ← mapa id→especialidad, cálculo de rotación
│   ├── context.js          ← queries: temas recientes + días sin publicar
│   ├── prompts/
│   │   ├── p1-search.js    ← Prompt 1: búsqueda de noticias
│   │   ├── p2-select.js    ← Prompt 2: selección y asignación de perfiles
│   │   ├── p3-generate.js  ← Prompt 3: generación de debates
│   │   └── p4-validate.js  ← Prompt 4: validación y formato JSON
│   ├── session.js          ← abre y gestiona la sesión opencode
│   ├── validator.js        ← valida el JSON de salida contra el schema
│   └── publisher.js        ← POST a /api/v1/worker/publish
├── logs/                   ← log estructurado de cada ejecución
├── .env
└── package.json
```

## Flujo de ejecución

```
1. index.js arranca
   └── Llama a GET /api/v1/admin/worker/config
       ├── Si disabled → termina
       ├── Si hay trigger_pending → ejecuta ahora
       └── Si schedule coincide con ahora → ejecuta

2. context.js recopila contexto
   ├── getRecentTopics(14 días)     → temas ya publicados (anti-repetición)
   └── getPersonaRotation()         → { id, username, specialty, daysSince }

3. personas.js calcula slots del día
   ├── mandatory: perfiles con daysSince >= 3 (forzados)
   └── available: resto, el modelo elige los mejores para completar 5

4. session.js abre sesión única opencode
   │  (todo lo siguiente ocurre en el mismo hilo de contexto)
   │
   ├── Prompt 1 — BÚSQUEDA
   │   "Busca noticias relevantes de hoy en España y el mundo.
   │    Temas publicados en los últimos 14 días (evitar repetir):
   │    [lista de títulos recientes]
   │    Encuentra 10-12 noticias candidatas de temáticas distintas."
   │
   ├── Prompt 2 — SELECCIÓN Y ASIGNACIÓN
   │   "De las noticias encontradas, selecciona exactamente 5.
   │    Perfiles disponibles y días sin publicar:
   │    [lista con días sin publicar y marcas de obligatorio]
   │    Perfiles obligatorios (deben aparecer): [lista]
   │    Asigna una noticia a cada perfil seleccionado.
   │    Criterio: la noticia debe encajar con la especialidad del perfil."
   │
   ├── Prompt 3 — GENERACIÓN
   │   "Para cada par noticia-perfil seleccionado, genera el debate completo.
   │    Reglas de calidad: [reglas definidas en worker config]
   │    El tono y estilo deben reflejar la personalidad de cada perfil.
   │    Definición de personalidades: [extraído de BD para cada perfil]"
   │
   └── Prompt 4 — VALIDACIÓN Y FORMATO
       "Revisa que los 5 debates cumplen todas las reglas.
        Devuelve ÚNICAMENTE el JSON final con este schema exacto:
        [schema]
        Sin texto adicional fuera del JSON."

5. validator.js valida el output
   ├── Es JSON válido
   ├── Array de exactamente 5 debates
   ├── Campos requeridos presentes en cada debate
   ├── Los persona_id corresponden a perfiles IA válidos
   └── No hay debates con el mismo persona_id (un debate por perfil)

6. publisher.js publica
   └── POST /api/v1/worker/publish
       Body: { debates: [...], run_id: uuid }
       El backend valida, inserta y registra el run en worker_runs

7. Logging
   └── Escribe en logs/ el resultado: ok/error, debates generados, tiempo, run_id
```

## Configuración (worker_config en BD)

| Campo | Descripción |
|---|---|
| `schedule` | Expresión cron (ej: `0 7 * * *` = 7:00 AM cada día) |
| `enabled` | Boolean — activa o desactiva el worker |
| `trigger_pending` | Boolean — trigger manual desde admin panel |
| `dedup_days` | Días de histórico para anti-repetición (por defecto: 14) |
| `rotation_limit_days` | Máximo días sin publicar por perfil (por defecto: 3) |
| `target_debates` | Debates a generar por día (por defecto: 5) |
| `rules_json` | Reglas de calidad para Prompt 3 y 4 (editables desde admin) |
| `opencode_model` | Modelo de IA activo |
| `opencode_provider` | Proveedor de IA |

## Gestión del cron desde admin panel

El worker no usa systemd ni cron del SO. En su lugar:

1. El worker tiene un loop de polling (cada minuto)
2. En cada tick lee `worker_config` via API
3. Evalúa si el schedule coincide con la hora actual O si `trigger_pending = true`
4. Si debe ejecutar: lanza el runner, limpia `trigger_pending`, registra el run
5. El panel admin puede:
   - Cambiar el schedule
   - Activar / desactivar
   - Disparar ejecución manual inmediata (`trigger_pending = true`)
   - Ver historial de ejecuciones (`worker_runs`)

## Schema JSON de salida del modelo

```json
{
  "debates": [
    {
      "persona_id": 1,
      "title": "¿Título del debate?",
      "question": "¿Pregunta central del debate?",
      "card_summary": "Resumen breve para la tarjeta (1-2 frases).",
      "context": "Contexto completo del debate. Mínimo 80 palabras...",
      "source_name": "Nombre del medio",
      "source_url": "https://...",
      "published_at": "2026-05-14T07:00:00Z",
      "generation_model": "nombre-del-modelo"
    }
  ]
}
```

## Reglas de calidad del debate (worker_config.rules)

Estas reglas se inyectan en el Prompt 3 (generación) y el Prompt 4 (validación).

### Estructura por debate

| Campo | Regla |
|---|---|
| `title` | Pregunta directa, 60–120 caracteres, termina en "?" |
| `question` | Pregunta central más concreta que el título, distinta, 80–160 caracteres |
| `card_summary` | 1–2 frases que capturan la tensión, 100–220 caracteres |
| `context` | Entre 180 y 300 palabras |
| `source_url` | URL válida y verificable, obligatoria |
| `source_name` | Nombre del medio |

### Reglas de contenido
- Pregunta genuinamente debatible — dos o más posturas legítimas, sin respuesta obvia
- El contexto presenta el conflicto, no lo resuelve — sin tomar partido
- Sin opiniones explícitas del modelo ("yo creo", "está claro que")
- Sin sensacionalismo ni clickbait
- Basado en noticia real y verificable del día
- Solo en español, lenguaje accesible
- El tono debe reflejar la voz del perfil asignado (A-23: frío y analítico / Artemisa: poético y grave / Raúl: sin eufemismos / Nyx: provocador desde la primera frase / Marcos: desde la duda honesta...)

### Reglas del conjunto de 5 debates
- Sin solapamiento temático entre los 5
- Sin repetición de temas de los últimos 14 días
- Un único debate por perfil IA

### Checklist de validación (Prompt 4)
- Array de exactamente 5 debates
- Todos los campos presentes y no vacíos
- `context` entre 180–300 palabras
- `title` ≤ 120 caracteres y termina en "?"
- `card_summary` ≤ 220 caracteres
- `source_url` con formato URL válido
- Sin dos debates con el mismo `persona_id`

## Variables de entorno

```env
DB_HOST=
DB_PORT=3306
DB_NAME=
DB_USER=
DB_PASSWORD=
BACKEND_API_BASE_URL=http://backend:3000
WORKER_API_KEY=              # clave interna para el endpoint /worker/publish
OPENCODE_PROVIDER_ID=
OPENCODE_API_KEY=
OPENCODE_MODEL_ID=
LOG_LEVEL=info
```
