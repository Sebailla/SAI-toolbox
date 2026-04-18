# Diseño: Docker Redis + Admin GUIs

## Enfoque Técnico

Extender el sistema Docker DB existente para agregar Redis como base de datos y visualizadores web (Admin GUIs) para todas las bases de datos. La implementación reutiliza patrones existentes del código de PostgreSQL y MongoDB.

## Decisiones de Arquitectura

### Decisión: Enum DOCKER_DB_TYPE vs Flags

**Elección**: Enum expandido con valores predefinidos

```
DOCKER_DB_TYPE = postgres | mongodb | redis | postgres-redis | mongodb-redis | all | both | none
```

**Alternativas consideradas**:
- Flags booleanos: `DOCKER_POSTGRES=1 DOCKER_REDIS=1` — más flexible pero más variables
- Array: `DOCKER_SERVICES=(postgres redis)` — máxima flexibilidad, máxima complejidad

**Justificación**: El enum predefinido es simple de entender y mantener. Las combinaciones comunes (postgres-redis, all) evitan selección repetitiva. Comparación de strings bash es trivial vs parsing de arrays.

### Decisión: Admin GUIs como Servicios Independientes

**Elección**: Cada Admin GUI es un servicio separado en docker-compose

**Alternativas consideradas**:
- Contenedor único con todos los admins — conflicto de puertos, acoplamiento
- Scripts externos que ejecutan Adminer local — requiere Adminer instalado

**Justificación**: Servicios independientes permiten:
- Auto-start selectivo según bases de datos elegidas
- Healthchecks individuales
- Escalado independiente
- Limpieza fácil con `docker compose down`

### Decisión: Imágenes Oficiales para Admin GUIs

| Admin | Imagen | Justificación |
|-------|--------|--------------|
| PostgreSQL | `adminer:latest` | Ligero, single PHP file, soporta PostgreSQL |
| MongoDB | `mongo-express:latest` | Web admin oficial para MongoDB |
| Redis | `rediscommander/redis-commander:latest` | Mejor opción open source para Redis |

**Justificación**: Imágenes oficiales/maintained evitan custom Dockerfiles. Adminer es stateless, Mongo Express y Redis Commander tienen configuración mínima.

### Decisión: Puertos Consecutivos para Admin GUIs

**Elección**: 8080, 8081, 8082

| Puerto | Servicio | Base de datos |
|--------|----------|--------------|
| 5432 | postgres | PostgreSQL |
| 27017 | mongodb | MongoDB |
| 6379 | redis | Redis |
| 8080 | adminer | PostgreSQL admin |
| 8081 | mongo-express | MongoDB admin |
| 8082 | redis-commander | Redis admin |

**Justificación**: Puertos 808x son convención para admin interfaces (8080 = first web admin). Secuencial facilita memorización.

## Cambios de Archivos

### lib/selectors.sh

```bash
# Menú expandido (líneas 261-324)
# 7 opciones en lugar de 4
# Case statement con 8 valores

case "$DB_CHOICE" in
    1) DOCKER_DB_TYPE="postgres" ;;
    2) DOCKER_DB_TYPE="mongodb" ;;
    3) DOCKER_DB_TYPE="redis" ;;
    4) DOCKER_DB_TYPE="postgres-redis" ;;
    5) DOCKER_DB_TYPE="mongodb-redis" ;;
    6) DOCKER_DB_TYPE="all" ;;
    7) DOCKER_DB_TYPE="none" ;;
esac
```

### lib/setup.sh

```bash
# setup_docker_db() genera servicios según DOCKER_DB_TYPE

# Redis (nuevo)
if [ "$DOCKER_DB_TYPE" = "redis" ] || [ "$DOCKER_DB_TYPE" = "postgres-redis" ] || 
   [ "$DOCKER_DB_TYPE" = "mongodb-redis" ] || [ "$DOCKER_DB_TYPE" = "all" ]; then
    # genera servicio redis...
fi

# Adminer (nuevo)
if [ "$DOCKER_DB_TYPE" = "postgres" ] || [ "$DOCKER_DB_TYPE" = "postgres-redis" ] || 
   [ "$DOCKER_DB_TYPE" = "all" ] || [ "$DOCKER_DB_TYPE" = "both" ]; then
    # genera servicio adminer...
fi

# MongoDB Express (nuevo)
if [ "$DOCKER_DB_TYPE" = "mongodb" ] || [ "$DOCKER_DB_TYPE" = "mongodb-redis" ] || 
   [ "$DOCKER_DB_TYPE" = "all" ] || [ "$DOCKER_DB_TYPE" = "both" ]; then
    # genera servicio mongo-express...
fi

# Redis Commander (nuevo)
if [ "$DOCKER_DB_TYPE" = "redis" ] || [ "$DOCKER_DB_TYPE" = "postgres-redis" ] || 
   [ "$DOCKER_DB_TYPE" = "mongodb-redis" ] || [ "$DOCKER_DB_TYPE" = "all" ]; then
    # genera servicio redis-commander...
fi
```

## Estructura Docker Compose

```yaml
services:
  postgres:
    image: postgres:16-alpine
    ports:
      - "5432:5432"
    # ... config ...

  mongodb:
    image: mongo:7.0
    ports:
      - "27017:27017"
    # ... config ...

  redis:                          # NUEVO
    image: redis:7.2-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    command: redis-server --appendonly yes
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]

  adminer:                        # NUEVO
    image: adminer:latest
    ports:
      - "8080:8080"
    depends_on:
      - postgres

  mongo-express:                  # NUEVO
    image: mongo-express:latest
    ports:
      - "8081:8081"
    environment:
      ME_CONFIG_MONGODB_URL: "mongodb://saiuser:saipass@mongodb:27017/sai"
    depends_on:
      - mongodb

  redis-commander:                # NUEVO
    image: rediscommander/redis-commander:latest
    ports:
      - "8082:8081"
    environment:
      REDIS_HOSTS: "local:sai_redis:6379"
    depends_on:
      - redis

volumes:
  postgres_data:
  mongodb_data:
  mongodb_config:
  redis_data:                    # NUEVO
```

## Variables de Entorno

```env
# Docker PostgreSQL
DATABASE_URL="postgresql://saiuser:saipass@localhost:5432/saidb"

# Docker MongoDB
# MONGODB_URL="mongodb://saiuser:saipass@localhost:27017/sai"

# Docker Redis
REDIS_URL="redis://default:redis123@localhost:6379"
```

## Diagrama de Secuencia: Auto-Start

```
User runs init-project.sh
         │
         ▼
select_docker_db() → shows 7 options
         │
         ▼
User selects "Todas"
         │
         ▼
DOCKER_DB_TYPE="all"
         │
         ▼
setup_docker_db() → generates docker-compose.yml with 6 services
         │
         ▼
docker compose up -d
         │
         ├──► postgres (healthy)
         ├──► mongodb (healthy)
         ├──► redis (healthy)
         ├──► adminer (depends_on postgres)
         ├──► mongo-express (depends_on mongodb)
         └──► redis-commander (depends_on redis)
         │
         ▼
db-start.sh shows:
  - Connection strings
  - Admin URLs (8080, 8081, 8082)
```

## Compatibilidad hacia Atrás

### Soporte Legacy 'both'

```bash
# anterior: both = postgres + mongodb
# ahora: both sigue funcionando igual

if [ "$DOCKER_DB_TYPE" = "both" ]; then
    # genera postgres + mongodb (SIN redis, SIN admin guis de redis)
fi
```

### Patrón de Lógica Condicional

```bash
# PostgreSQL
if [ "$DOCKER_DB_TYPE" = "postgres" ] || 
   [ "$DOCKER_DB_TYPE" = "postgres-redis" ] || 
   [ "$DOCKER_DB_TYPE" = "all" ] || 
   [ "$DOCKER_DB_TYPE" = "both" ]; then
    # genera postgres
fi
```

Este patrón permite agregar nuevas combinaciones sin modificar lógica existente.

## Manejo de Errores

1. **Docker unavailable**: Solo mostrar opción "No incluir Docker"
2. **Port conflict**: Docker compose falla con error claro
3. **Image pull failure**: Docker intenta pull, error visible
4. **Healthcheck failure**: `docker compose ps` muestra estado unhealthy

## Plan de Rollback

```bash
# Opción 1: Revert commits
git revert HEAD~1  # Admin GUIs
git revert HEAD~2  # Redis

# Opción 2: Restaurar archivos específicos
git checkout HEAD~2 -- init-project/lib/selectors.sh
git checkout HEAD~2 -- init-project/lib/setup.sh
git checkout HEAD~2 -- README.md
```

## Comandos de Verificación

```bash
# Ver servicios generados
docker compose config --services

# Esperar que todos estén healthy
docker compose ps

# Ver puertos en uso
docker compose ps --format "{{.Name}}: {{.Ports}}"

# Test Admin GUIs
curl -s -o /dev/null -w "%{http_code}" http://localhost:8080  # Adminer
curl -s -o /dev/null -w "%{http_code}" http://localhost:8081  # Mongo Express
curl -s -o /dev/null -w "%{http_code}" http://localhost:8082  # Redis Commander
```
