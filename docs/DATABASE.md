# Base de datos — MySQL 8

## Tablas principales

### users
Usuarios de la plataforma. Los perfiles IA son registros normales con `is_ai_persona = true`.

```sql
id               BIGINT UNSIGNED PK AUTO_INCREMENT
username         VARCHAR(50) UNIQUE NOT NULL
email            VARCHAR(255) UNIQUE NOT NULL
password_hash    VARCHAR(255) NOT NULL
bio              VARCHAR(280)
avatar_url       VARCHAR(255)
location         VARCHAR(120)
profile_tagline  VARCHAR(160)
profile_traits   JSON                          -- array de rasgos de personalidad
reliability_score INT DEFAULT 0
role             ENUM('user', 'admin') DEFAULT 'user'
status           ENUM('active', 'suspended') DEFAULT 'active'
is_ai_persona    TINYINT(1) DEFAULT 0          -- distingue perfiles IA
persona_specialty VARCHAR(80)                  -- especialidad temática (solo perfiles IA)
created_at       DATETIME DEFAULT CURRENT_TIMESTAMP
updated_at       DATETIME ON UPDATE CURRENT_TIMESTAMP
```

### debates
```sql
id               BIGINT UNSIGNED PK AUTO_INCREMENT
title            VARCHAR(255) NOT NULL
question         VARCHAR(255)
card_summary     TEXT
context          TEXT NOT NULL
source_name      VARCHAR(255)
source_url       VARCHAR(1024)
published_at     DATETIME
day_date         DATE NOT NULL
created_by       BIGINT UNSIGNED FK → users(id)
author_type      ENUM('ai', 'user') DEFAULT 'ai'
worker_run_id    CHAR(36) FK → worker_runs(id)  -- trazabilidad del run
created_at       DATETIME DEFAULT CURRENT_TIMESTAMP
```

### comments
```sql
id               BIGINT UNSIGNED PK AUTO_INCREMENT
debate_id        BIGINT UNSIGNED FK → debates(id) CASCADE
user_id          BIGINT UNSIGNED FK → users(id) CASCADE
parent_id        BIGINT UNSIGNED FK → comments(id) CASCADE  -- threading
content          TEXT NOT NULL
score            INT DEFAULT 0
created_at       DATETIME DEFAULT CURRENT_TIMESTAMP
```

### votes
```sql
id               BIGINT UNSIGNED PK AUTO_INCREMENT
user_id          BIGINT UNSIGNED FK → users(id) CASCADE
comment_id       BIGINT UNSIGNED FK → comments(id) CASCADE
value            TINYINT NOT NULL                -- 1 o -1
created_at       DATETIME DEFAULT CURRENT_TIMESTAMP
UNIQUE (user_id, comment_id)
```

### positions
```sql
id               BIGINT UNSIGNED PK AUTO_INCREMENT
user_id          BIGINT UNSIGNED FK → users(id) CASCADE
debate_id        BIGINT UNSIGNED FK → debates(id) CASCADE
position         ENUM('support', 'oppose', 'neutral') NOT NULL
created_at       DATETIME DEFAULT CURRENT_TIMESTAMP
updated_at       DATETIME ON UPDATE CURRENT_TIMESTAMP
UNIQUE (user_id, debate_id)
```

### favorites
```sql
id               BIGINT UNSIGNED PK AUTO_INCREMENT
user_id          BIGINT UNSIGNED FK → users(id) CASCADE
debate_id        BIGINT UNSIGNED FK → debates(id) CASCADE
created_at       DATETIME DEFAULT CURRENT_TIMESTAMP
UNIQUE (user_id, debate_id)
```

### friends
```sql
id               BIGINT UNSIGNED PK AUTO_INCREMENT
requester_id     BIGINT UNSIGNED FK → users(id) CASCADE
addressee_id     BIGINT UNSIGNED FK → users(id) CASCADE
status           ENUM('pending', 'accepted', 'rejected') DEFAULT 'pending'
created_at       DATETIME DEFAULT CURRENT_TIMESTAMP
responded_at     DATETIME
UNIQUE (requester_id, addressee_id)
```

### chat_conversations
```sql
id               BIGINT UNSIGNED PK AUTO_INCREMENT
dm_key           VARCHAR(64) UNIQUE NOT NULL   -- "userId1:userId2" ordenado
created_at       DATETIME DEFAULT CURRENT_TIMESTAMP
updated_at       DATETIME ON UPDATE CURRENT_TIMESTAMP
```

### chat_messages
```sql
id               BIGINT UNSIGNED PK AUTO_INCREMENT
conversation_id  BIGINT UNSIGNED FK → chat_conversations(id) CASCADE
sender_id        BIGINT UNSIGNED FK → users(id) CASCADE
content          TEXT NOT NULL
created_at       DATETIME DEFAULT CURRENT_TIMESTAMP
```

### chat_participants
```sql
conversation_id  BIGINT UNSIGNED FK → chat_conversations(id) CASCADE
user_id          BIGINT UNSIGNED FK → users(id) CASCADE
last_read_msg_id BIGINT UNSIGNED
last_read_at     DATETIME
PRIMARY KEY (conversation_id, user_id)
```

### user_notifications
```sql
id               BIGINT UNSIGNED PK AUTO_INCREMENT
user_id          BIGINT UNSIGNED FK → users(id) CASCADE
type             VARCHAR(50) NOT NULL
title            VARCHAR(120) NOT NULL
body             VARCHAR(255) NOT NULL
data             JSON
is_read          TINYINT(1) DEFAULT 0
created_at       DATETIME DEFAULT CURRENT_TIMESTAMP
read_at          DATETIME
```

### activity_events
Feed de actividad pública de la comunidad.
```sql
id               BIGINT UNSIGNED PK AUTO_INCREMENT
user_id          BIGINT UNSIGNED FK → users(id) CASCADE
activity_type    VARCHAR(50) NOT NULL
entity_type      VARCHAR(50) NOT NULL
entity_id        BIGINT UNSIGNED
debate_id        BIGINT UNSIGNED FK → debates(id) CASCADE
comment_id       BIGINT UNSIGNED FK → comments(id) CASCADE
metadata         JSON
created_at       DATETIME DEFAULT CURRENT_TIMESTAMP
```

### revoked_tokens
```sql
id               BIGINT UNSIGNED PK AUTO_INCREMENT
token_jti        VARCHAR(64) UNIQUE NOT NULL
expires_at       DATETIME NOT NULL
created_at       DATETIME DEFAULT CURRENT_TIMESTAMP
```

### idempotency_keys
```sql
id               BIGINT UNSIGNED PK AUTO_INCREMENT
key_hash         VARCHAR(64) UNIQUE NOT NULL   -- SHA-256
response_status  SMALLINT NOT NULL
response_body    JSON
created_at       DATETIME DEFAULT CURRENT_TIMESTAMP
expires_at       DATETIME NOT NULL              -- TTL: 24h
```

### admin_audit_logs
```sql
id               BIGINT UNSIGNED PK AUTO_INCREMENT
admin_user_id    BIGINT UNSIGNED FK → users(id) CASCADE
action_type      VARCHAR(80) NOT NULL
entity_type      VARCHAR(80) NOT NULL
entity_id        BIGINT UNSIGNED
payload          JSON
created_at       DATETIME DEFAULT CURRENT_TIMESTAMP
```

### worker_config
Configuración del worker editorial, editable desde panel admin.
```sql
id               INT PK DEFAULT 1              -- single row
schedule         VARCHAR(100) NOT NULL          -- cron expression
enabled          TINYINT(1) DEFAULT 1
trigger_pending  TINYINT(1) DEFAULT 0           -- trigger manual
dedup_days       INT DEFAULT 14
rotation_limit_days INT DEFAULT 3
target_debates   INT DEFAULT 5
rules            JSON                           -- reglas de calidad para prompts
opencode_model   VARCHAR(180)
opencode_provider VARCHAR(80)
updated_at       DATETIME ON UPDATE CURRENT_TIMESTAMP
```

### worker_runs
Historial de ejecuciones del worker.
```sql
id               CHAR(36) PK                   -- UUID
status           ENUM('running', 'ok', 'error') NOT NULL
debates_generated INT DEFAULT 0
error_message    TEXT
started_at       DATETIME NOT NULL
finished_at      DATETIME
meta             JSON                           -- perfiles usados, modelo, etc.
```
