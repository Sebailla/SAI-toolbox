# Delta for Docker Redis + Admin GUIs

## ADDED Requirements

### Requirement: Extended Docker DB Options

El sistema DEBE soportar las siguientes opciones de Docker Database:

```
1) PostgreSQL (SQL - ideal para Prisma)
2) MongoDB (NoSQL)
3) Redis (Time Series / Cache / Real-time)
4) PostgreSQL + Redis
5) MongoDB + Redis
6) Todas (PostgreSQL + MongoDB + Redis)
7) No incluir Docker
```

#### Scenario: Select PostgreSQL Only

- GIVEN Docker está disponible
- WHEN usuario selecciona opción 1
- THEN `DOCKER_DB_TYPE` es "postgres"
- AND `docker-compose.yml` incluye solo postgres

#### Scenario: Select Redis Only

- GIVEN Docker está disponible
- WHEN usuario selecciona opción 3
- THEN `DOCKER_DB_TYPE` es "redis"
- AND `docker-compose.yml` incluye solo redis

#### Scenario: Select PostgreSQL + Redis

- GIVEN Docker está disponible
- WHEN usuario selecciona opción 4
- THEN `DOCKER_DB_TYPE` es "postgres-redis"
- AND `docker-compose.yml` incluye postgres y redis

#### Scenario: Select All Databases

- GIVEN Docker está disponible
- WHEN usuario selecciona opción 6
- THEN `DOCKER_DB_TYPE` es "all"
- AND `docker-compose.yml` incluye postgres, mongodb y redis

#### Scenario: Docker Unavailable

- GIVEN Docker NO está disponible
- WHEN `select_docker_db()` es llamada
- THEN solo se muestra opción "No incluir Docker"
- AND `DOCKER_DB_TYPE` es "none"

---

### Requirement: Redis Container Configuration

El contenedor Redis DEBE:

1. Usar imagen `redis:7.2-alpine`
2. Exponer puerto `6379`
3. Usar volumen `redis_data` con `redis-server --appendonly yes`
4. Tener healthcheck con `redis-cli ping`

#### Scenario: Redis Container Structure

- GIVEN `DOCKER_DB_TYPE` incluye redis
- WHEN `setup_docker_db()` genera docker-compose.yml
- THEN el servicio `redis` tiene imagen `redis:7.2-alpine`
- AND puerto `6379:6379`
- AND volumen `redis_data:/data`

#### Scenario: Redis Healthcheck

- GIVEN Redis container se inicia
- WHEN healthcheck se ejecuta
- THEN verifica con `redis-cli ping`
- AND interval 10s, timeout 5s, retries 5

---

### Requirement: Admin GUIs for Each Database

El sistema DEBE generar Admin GUIs para cada base de datos seleccionada:

| Admin | Puerto | Base de datos | Imagen |
|-------|--------|---------------|--------|
| Adminer | 8080 | PostgreSQL | adminer:latest |
| MongoDB Express | 8081 | MongoDB | mongo-express:latest |
| Redis Commander | 8082 | Redis | rediscommander/redis-commander:latest |

#### Scenario: Adminer for PostgreSQL

- GIVEN `DOCKER_DB_TYPE` es "postgres" o incluye postgres
- WHEN `setup_docker_db()` genera docker-compose.yml
- THEN servicio `adminer` existe con imagen `adminer:latest`
- AND puertos `8080:8080`
- AND depends_on postgres
- AND healthcheck con wget a http://localhost:8080

#### Scenario: MongoDB Express for MongoDB

- GIVEN `DOCKER_DB_TYPE` es "mongodb" o incluye mongodb
- WHEN `setup_docker_db()` genera docker-compose.yml
- THEN servicio `mongo-express` existe con imagen `mongo-express:latest`
- AND ME_CONFIG_MONGODB_URL configurado
- AND ME_CONFIG_BASICAUTH_USERNAME y PASSWORD configurados
- AND puertos `8081:8081`

#### Scenario: Redis Commander for Redis

- GIVEN `DOCKER_DB_TYPE` incluye redis
- WHEN `setup_docker_db()` genera docker-compose.yml
- THEN servicio `redis-commander` existe con imagen `rediscommander/redis-commander:latest`
- AND REDIS_HOSTS="local:sai_redis:6379"
- AND puertos `8082:8081`

#### Scenario: Admin GUI Depends on Database

- GIVEN Admin GUI se configura
- WHEN contenedor inicia
- THEN wait for database container via depends_on
- AND database debe estar healthy antes que admin GUI

---

### Requirement: Redis Connection String

El connection string de Redis DEBE ser:

```
redis://default:redis123@localhost:6379
```

#### Scenario: Redis Connection String in .env

- GIVEN `DOCKER_DB_TYPE` incluye redis
- WHEN `setup_docker_db()` genera archivos
- THEN `.env` contiene `REDIS_URL=redis://default:redis123@localhost:6379`

---

### Requirement: Updated Scripts with Admin URLs

Los scripts de ayuda DEBEN mostrar las URLs de Admin GUIs al iniciar.

#### Scenario: db-start.sh Shows Admin URLs

- GIVEN contenedores se inician exitosamente
- WHEN `db-start.sh` ejecuta
- THEN muestra:
  ```
  Adminer (PostgreSQL): http://localhost:8080
  MongoDB Express: http://localhost:8081 (User: saiusers / Pass: saipass)
  Redis Commander: http://localhost:8082
  ```

#### Scenario: Connection Strings in init-project.sh Auto-start

- GIVEN Docker está corriendo y se eligió Docker DB
- WHEN `init-project.sh` hace auto-start de contenedores
- THEN muestra connection strings y admin URLs según selección

---

## MODIFIED Requirements

### Requirement: DOCKER_DB_TYPE Values

**Previously**:
```
DOCKER_DB_TYPE = postgres | mongodb | both | none
```

**Now**:
```
DOCKER_DB_TYPE = postgres | mongodb | redis | postgres-redis | mongodb-redis | all | both | none
```

#### Scenario: Backward Compatibility with 'both'

- GIVEN `DOCKER_DB_TYPE` es "both" (legado)
- WHEN `setup_docker_db()` procesa
- THEN genera postgres y mongodb (sin redis, sin admin guis para redis)
- AND muestra "both" en confirm_setup()

---

## REMOVED Requirements

Ninguno.

---

## File Inventory

| Archivo | Líneas | Cambio |
|---------|--------|--------|
| `lib/selectors.sh` | ~380 | +60 líneas, menú expandido |
| `lib/setup.sh` | ~1750 | +180 líneas, Redis + Admin GUIs |
| `init-project.sh` | ~200 | +20 líneas, connection strings |
| `README.md` | ~450 | +30 líneas, documentación |

---

## Acceptance Criteria

| ID | Criterion | Verification |
|----|-----------|--------------|
| AC1 | `select_docker_db` muestra 7 opciones | Interactivo: 7 opciones visibles |
| AC2 | Redis container en docker-compose | `docker compose config` incluye servicio redis |
| AC3 | Adminer container existe para postgres | `docker compose config` incluye adminer |
| AC4 | MongoDB Express container existe para mongodb | `docker compose config` incluye mongo-express |
| AC5 | Redis Commander container existe para redis | `docker compose config` incluye redis-commander |
| AC6 | Healthchecks en todos los contenedores | `docker compose config` muestra healthcheck |
| AC7 | Redis connection string en .env | `grep redis .env` encuentra URL |
| AC8 | Admin URLs en db-start.sh | `./scripts/db-start.sh` muestra http://localhost:8080, 8081, 8082 |
| AC9 | Admin URLs en auto-start | Mensaje final muestra todas las URLs |
| AC10 | README.md actualizado | Nueva tabla de Admin GUIs presente |

---

## Test Scenarios

### Scenario: Full Stack Selection

- GIVEN Docker corriendo
- WHEN usuario selecciona opción 6 (Todas)
- THEN `docker compose up -d` levanta 6 contenedores:
  - postgres (5432)
  - mongodb (27017)
  - redis (6379)
  - adminer (8080)
  - mongo-express (8081)
  - redis-commander (8082)

### Scenario: Redis Only Selection

- GIVEN Docker corriendo
- WHEN usuario selecciona opción 3 (Redis)
- THEN `docker compose up -d` levanta 2 contenedores:
  - redis (6379)
  - redis-commander (8082)
