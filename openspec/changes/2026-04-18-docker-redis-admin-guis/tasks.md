# Tasks: Docker Redis + Admin GUIs

## Phase 1: selectors.sh - Expandir menú Docker DB

- [ ] 1.1 Actualizar `select_docker_db()` para mostrar 7 opciones en lugar de 4
  - Agregar opción 3: Redis
  - Agregar opción 4: PostgreSQL + Redis
  - Agregar opción 5: MongoDB + Redis
  - Agregar opción 6: Todas
  - Cambiar "No incluir" a opción 7
  - Archivos: `lib/selectors.sh` (~líneas 261-324)

- [ ] 1.2 Actualizar `confirm_setup()` para mostrar nuevos DOCKER_DB_TYPE
  - Agregar casos para: redis, postgres-redis, mongodb-redis, all
  - Mostrar Redis en el resumen
  - Archivos: `lib/selectors.sh` (~líneas 350-370)

## Phase 2: setup.sh - Agregar Redis

- [ ] 2.1 Crear servicio Redis en `setup_docker_db()`
  - Imagen: `redis:7.2-alpine`
  - Puerto: `6379:6379`
  - Volumen: `redis_data:/data`
  - Command: `redis-server --appendonly yes`
  - Healthcheck: `redis-cli ping`
  - Archivos: `lib/setup.sh`

- [ ] 2.2 Agregar volumen `redis_data` a volumes section
  - Archivos: `lib/setup.sh`

- [ ] 2.3 Actualizar condiciones para incluir Redis
  - Cambiar `|| [ "$DOCKER_DB_TYPE" = "both" ]` por grupo expandido
  - Pattern: `|| [ "$DOCKER_DB_TYPE" = "redis" ] || [ "$DOCKER_DB_TYPE" = "postgres-redis" ] || ...`

## Phase 3: setup.sh - Agregar Admin GUIs

- [ ] 3.1 Crear servicio Adminer (PostgreSQL admin)
  - Imagen: `adminer:latest`
  - Puerto: `8080:8080`
  - depends_on: postgres
  - Healthcheck: wget a http://localhost:8080
  - Archivos: `lib/setup.sh`

- [ ] 3.2 Crear servicio MongoDB Express
  - Imagen: `mongo-express:latest`
  - Puerto: `8081:8081`
  - Environment: ME_CONFIG_MONGODB_URL, ME_CONFIG_BASICAUTH_USERNAME/PASSWORD
  - depends_on: mongodb
  - Archivos: `lib/setup.sh`

- [ ] 3.3 Crear servicio Redis Commander
  - Imagen: `rediscommander/redis-commander:latest`
  - Puerto: `8082:8081`
  - Environment: REDIS_HOSTS, REDIS_HOST, REDIS_PORT
  - depends_on: redis
  - Archivos: `lib/setup.sh`

- [ ] 3.4 Actualizar `scripts/db-start.sh` con Admin URLs
  - Agregar Adminer URL: http://localhost:8080
  - Agregar MongoDB Express URL: http://localhost:8081 + credenciales
  - Agregar Redis Commander URL: http://localhost:8082
  - Archivos: `lib/setup.sh`

## Phase 4: init-project.sh - Connection Strings

- [ ] 4.1 Actualizar auto-start connection strings
  - Agregar Redis URL cuando corresponda
  - Agregar Admin URLs cuando corresponda
  - Archivos: `init-project.sh` (~líneas 125-145)

## Phase 5: Documentación

- [ ] 5.1 Actualizar README.md
  - Nueva tabla de opciones Docker (7 opciones)
  - Nueva tabla de Admin GUIs
  - Connection strings de Redis
  -Puertos de Admin GUIs

## Phase 6: Verificación

- [ ] 6.1 Syntax check en todos los archivos modificados
  ```bash
  bash -n init-project/lib/selectors.sh
  bash -n init-project/lib/setup.sh
  bash -n init-project/init-project.sh
  ```

- [ ] 6.2 Test interactivo (simular selección)
  - Opción 1: PostgreSQL → 1 container
  - Opción 3: Redis → 2 containers (redis + redis-commander)
  - Opción 6: Todas → 6 containers

## Commit Strategy

| Phase | Commit Message |
|-------|----------------|
| 1 | `feat(docker): expand Docker DB options to 7 choices including Redis` |
| 2-3 | `feat(docker): add Redis container with persistence` |
| 3 | `feat(docker): add Admin GUIs (Adminer, MongoDB Express, Redis Commander)` |
| 4 | `feat(docker): update connection strings and Admin URLs in auto-start` |
| 5 | `docs: update README with Redis and Admin GUIs documentation` |

## Dependencies

```
selectors.sh (1.1, 1.2)
    │
    ▼
setup.sh (2.1-2.3, 3.1-3.4)
    │
    ▼
init-project.sh (4.1)
    │
    ▼
README.md (5.1)
    │
    ▼
Verification (6.1, 6.2)
```

## Time Estimate

- Phase 1: 10 min
- Phase 2: 15 min
- Phase 3: 20 min
- Phase 4: 5 min
- Phase 5: 5 min
- Phase 6: 15 min

**Total: ~70 minutos**

## Notes

- Los admin GUIs requieren que la base de datos esté healthy antes de iniciar
- `depends_on` en Docker Compose v2 espera a que el contenedor exista, no a que esté healthy
- Para production-like, considerar `healthcheck` + `condition: service_healthy` (requiere docker-compose v2.1+)
