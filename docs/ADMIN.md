# Panel Admin

## Propósito

Interfaz web para gestionar la plataforma sin acceso directo al servidor. Separado de la app móvil Flutter.

## Tecnología

Por definir. Opciones:
- Integrado en Symfony (Twig + EasyAdmin bundle)
- SPA independiente (Vue/React ligero)
- Flutter Web

## Funcionalidades

### Worker editorial
- Ver configuración actual (schedule, modelo, reglas)
- Modificar schedule (expresión cron)
- Activar / desactivar el worker
- Disparar ejecución manual inmediata
- Ver historial de ejecuciones (`worker_runs`) con estado, debates generados y errores
- Editar las reglas de calidad que se pasan a los prompts

### Moderación
- Listar debates con opción de ocultar o eliminar
- Listar comentarios reportados
- Ver y gestionar usuarios (suspender, restaurar)

### Auditoría
- Log de acciones admin (`admin_audit_logs`)
- Historial de cambios en `worker_config`

### Perfiles IA
- Ver y editar los perfiles IA (bio, traits, tagline)
- Ver estadísticas de publicación por perfil

### Estadísticas generales
- Debates generados por día/semana
- Comentarios y participación
- Usuarios activos

## Acceso

- Solo usuarios con `role = 'admin'`
- Misma autenticación JWT que el resto de la API
- Endpoints bajo `/api/v1/admin/` — middleware verifica rol antes de procesar
