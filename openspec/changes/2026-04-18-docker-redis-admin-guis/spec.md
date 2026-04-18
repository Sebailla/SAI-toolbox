# Delta para Docker Redis + Admin GUIs

## REQUISITOS AGREGADOS

### Requisito: Opciones Extendidas de Docker DB

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

#### Escenario: Seleccionar Solo PostgreSQL

- DADO Docker está disponible
- CUANDO usuario selecciona opción 1
- ENTONCES `DOCKER_DB_TYPE` es "postgres"
- Y `docker-compose.yml` incluye solo postgres

#### Escenario: Seleccionar Solo Redis

- DADO Docker está disponible
- CUANDO usuario selecciona opción 3
- ENTONCES `DOCKER_DB_TYPE` es "redis"
- Y `docker-compose.yml` incluye solo redis

#### Escenario: Seleccionar PostgreSQL + Redis

- DADO Docker está disponible
- CUANDO usuario selecciona opción 4
- ENTONCES `DOCKER_DB_TYPE` es "postgres-redis"
- Y `docker-compose.yml` incluye postgres y redis

#### Escenario: Seleccionar Todas las Bases de Datos

- DADO Docker está disponible
- CUANDO usuario selecciona opción 6
- ENTONCES `DOCKER_DB_TYPE` es "all"
- Y `docker-compose.yml` incluye postgres, mongodb y redis

#### Escenario: Docker No Disponible

- DADO Docker NO está disponible
- CUANDO `select_docker_db()` es llamada
- ENTONCES solo se muestra opción "No incluir Docker"
- Y `DOCKER_DB_TYPE` es "none"

---

### Requisito: Configuración del Contenedor Redis

El contenedor Redis DEBE:

1. Usar imagen `redis:7.2-alpine`
2. Exponer puerto `6379`
3. Usar volumen `redis_data` con `redis-server --appendonly yes`
4. Tener healthcheck con `redis-cli ping`

#### Escenario: Estructura del Contenedor Redis

- DADO `DOCKER_DB_TYPE` incluye redis
- CUANDO `setup_docker_db()` genera docker-compose.yml
- ENTONCES el servicio `redis` tiene imagen `redis:7.2-alpine`
- Y puerto `6379:6379`
- Y volumen `redis_data:/data`

#### Escenario: Healthcheck de Redis

- DADO Redis container se inicia
- CUANDO healthcheck se ejecuta
- ENTONCES verifica con `redis-cli ping`
- Y interval 10s, timeout 5s, retries 5

---

### Requisito: Admin GUIs para Cada Base de Datos

El sistema DEBE generar Admin GUIs para cada base de datos seleccionada:

| Admin | Puerto | Base de datos | Imagen |
|-------|--------|---------------|--------|
| Adminer | 8080 | PostgreSQL | adminer:latest |
| MongoDB Express | 8081 | MongoDB | mongo-express:latest |
| Redis Commander | 8082 | Redis | rediscommander/redis-commander:latest |

#### Escenario: Adminer para PostgreSQL

- DADO `DOCKER_DB_TYPE` es "postgres" o incluye postgres
- CUANDO `setup_docker_db()` genera docker-compose.yml
- ENTONCES servicio `adminer` existe con imagen `adminer:latest`
- Y puertos `8080:8080`
- Y depends_on postgres
- Y healthcheck con wget a http://localhost:8080

#### Escenario: MongoDB Express para MongoDB

- DADO `DOCKER_DB_TYPE` es "mongodb" o incluye mongodb
- CUANDO `setup_docker_db()` genera docker-compose.yml
- ENTONCES servicio `mongo-express` existe con imagen `mongo-express:latest`
- Y ME_CONFIG_MONGODB_URL configurado
- Y ME_CONFIG_BASICAUTH_USERNAME y PASSWORD configurados
- Y puertos `8081:8081`

#### Escenario: Redis Commander para Redis

- DADO `DOCKER_DB_TYPE` incluye redis
- CUANDO `setup_docker_db()` genera docker-compose.yml
- ENTONCES servicio `redis-commander` existe con imagen `rediscommander/redis-commander:latest`
- Y REDIS_HOSTS="local:sai_redis:6379"
- Y puertos `8082:8081`

#### Escenario: Admin GUI Depende de Base de Datos

- DADO Admin GUI se configura
- CUANDO contenedor inicia
- ENTONCES espera base de datos via depends_on
- Y base de datos debe estar healthy antes que admin GUI

---

### Requisito: Connection String de Redis

El connection string de Redis DEBE ser:

```
redis://default:redis123@localhost:6379
```

#### Escenario: Connection String de Redis en .env

- DADO `DOCKER_DB_TYPE` incluye redis
- CUANDO `setup_docker_db()` genera archivos
- ENTONCES `.env` contiene `REDIS_URL=redis://default:redis123@localhost:6379`

---

### Requisito: Scripts Actualizados con URLs de Admin

Los scripts de ayuda DEBEN mostrar las URLs de Admin GUIs al iniciar.

#### Escenario: db-start.sh Muestra URLs de Admin

- DADO contenedores se inician exitosamente
- CUANDO `db-start.sh` ejecuta
- ENTONCES muestra:
  ```
  Adminer (PostgreSQL): http://localhost:8080
  MongoDB Express: http://localhost:8081 (User: saiusers / Pass: saipass)
  Redis Commander: http://localhost:8082
  ```

#### Escenario: Connection Strings en Auto-start de init-project.sh

- DADO Docker está corriendo y se eligió Docker DB
- CUANDO `init-project.sh` hace auto-start de contenedores
- ENTONCES muestra connection strings y admin URLs según selección

---

## REQUISITOS MODIFICADOS

### Requisito: Valores de DOCKER_DB_TYPE

**Anteriormente**:
```
DOCKER_DB_TYPE = postgres | mongodb | both | none
```

**Ahora**:
```
DOCKER_DB_TYPE = postgres | mongodb | redis | postgres-redis | mongodb-redis | all | both | none
```

#### Escenario: Compatibilidad hacia Atrás con 'both'

- DADO `DOCKER_DB_TYPE` es "both" (legado)
- CUANDO `setup_docker_db()` procesa
- ENTONCES genera postgres y mongodb (sin redis, sin admin guis para redis)
- Y muestra "both" en confirm_setup()

---

## REQUISITOS ELIMINADOS

Ninguno.

---

## Inventario de Archivos

| Archivo | Líneas | Cambio |
|---------|--------|--------|
| `lib/selectors.sh` | ~380 | +60 líneas, menú expandido |
| `lib/setup.sh` | ~1750 | +180 líneas, Redis + Admin GUIs |
| `init-project.sh` | ~200 | +20 líneas, connection strings |
| `README.md` | ~450 | +30 líneas, documentación |

---

## Criterios de Aceptación

| ID | Criterio | Verificación |
|----|----------|-------------|
| AC1 | `select_docker_db` muestra 7 opciones | Interactivo: 7 opciones visibles |
| AC2 | Contenedor Redis en docker-compose | `docker compose config` incluye servicio redis |
| AC3 | Contenedor Adminer existe para postgres | `docker compose config` incluye adminer |
| AC4 | Contenedor MongoDB Express existe para mongodb | `docker compose config` incluye mongo-express |
| AC5 | Contenedor Redis Commander existe para redis | `docker compose config` incluye redis-commander |
| AC6 | Healthchecks en todos los contenedores | `docker compose config` muestra healthcheck |
| AC7 | Connection string de Redis en .env | `grep redis .env` encuentra URL |
| AC8 | URLs de Admin en db-start.sh | `./scripts/db-start.sh` muestra http://localhost:8080, 8081, 8082 |
| AC9 | URLs de Admin en auto-start | Mensaje final muestra todas las URLs |
| AC10 | README.md actualizado | Nueva tabla de Admin GUIs presente |

---

## Escenarios de Test

### Escenario: Selección Full Stack

- DADO Docker corriendo
- CUANDO usuario selecciona opción 6 (Todas)
- ENTONCES `docker compose up -d` levanta 6 contenedores:
  - postgres (5432)
  - mongodb (27017)
  - redis (6379)
  - adminer (8080)
  - mongo-express (8081)
  - redis-commander (8082)

### Escenario: Selección Solo Redis

- DADO Docker corriendo
- CUANDO usuario selecciona opción 3 (Redis)
- ENTONCES `docker compose up -d` levanta 2 contenedores:
  - redis (6379)
  - redis-commander (8082)
