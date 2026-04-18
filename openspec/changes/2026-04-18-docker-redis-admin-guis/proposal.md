# Proposal: Docker Redis + Admin GUIs

## Intent

Agregar Redis como opción de base de datos Docker y mejorar la experiencia de desarrollo con visualizadores web (Admin GUIs) para todas las bases de datos soportadas.

## Scope

### In Scope
- Agregar Redis como opción de Docker DB en `select_docker_db()`
- Actualizar `docker-compose.yml` para incluir Redis
- Agregar Admin GUIs: Adminer (PostgreSQL), MongoDB Express, Redis Commander
- Actualizar scripts de ayuda (`db-start.sh`, `db-stop.sh`, `db-reset.sh`, `db-logs.sh`)
- Actualizar `.env` con connection strings de Redis
- Documentar en README.md

### Out of Scope
- Cambios en builders (scaffolding de proyectos)
- Integración de Redis en los templates de proyecto (solo Docker)
- Configuración de Redis para NestJS o Next.js

## Approach

### Opción 1: Extender DOCKER_DB_TYPE (Elegida)
- Modificar `select_docker_db()` para agregar 3 nuevas opciones
- Reutilizar lógica existente con condiciones `||` para combinaciones

**Pros**: Mínimo cambio, retrocompatible
**Cons**: Enum grows, 7 opciones totales

### Opción 2: Flags separados
- `DOCKER_POSTGRES=1`, `DOCKER_MONGODB=1`, `DOCKER_REDIS=1`

**Pros**: Más flexible
**Cons**: Más variables, mayor complejidad

### Opción 3: Array de servicios
- `DOCKER_SERVICES=(postgres mongodb redis)`

**Pros**: Extremadamente flexible
**Cons**: Complejidad en scripts bash

**Decisión**: Opción 1 - Enum simple con combinaciones predefinidas

## Affected Areas

| Archivo | Cambio |
|---------|--------|
| `lib/selectors.sh` | `select_docker_db()` - 7 opciones |
| `lib/setup.sh` | `setup_docker_db()` - genera Redis + Admin GUIs |
| `init-project.sh` | Connection strings en auto-start |
| `README.md` | Documentación actualizada |

## Rollback Plan

```bash
# Revertir cambios
git revert HEAD~1  # Admin GUIs
git revert HEAD~2  # Redis
```

## Status

**Proposed** - Awaiting approval to proceed with spec.
