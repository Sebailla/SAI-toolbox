# Delta para Modularización de init-project.sh

## REQUISITOS AGREGADOS

### Requisito: Estructura de Archivos Modular

El sistema DEBE organizar `init-project.sh` en una estructura de directorio modular bajo `init-project/` con el siguiente layout:

```
init-project/
├── init-project.sh          # Punto de entrada (~150 líneas)
└── lib/
    ├── core.sh              # Constantes, colores, logging, banner, cleanup, timeout
    ├── validators.sh         # Verificación de dependencias y Docker
    ├── selectors.sh          # Funciones de selección interactiva
    ├── builders.sh           # Funciones de creación de proyectos
    └── setup.sh             # Configuración post-creación
```

#### Escenario: Creación de Estructura de Directorios

- DADO un clon fresco del repositorio
- CUANDO se ejecuta `ls -la init-project/`
- ENTONCES el directorio contiene `init-project.sh` y subdirectorio `lib/`
- Y `lib/` contiene exactamente 5 archivos `.sh`: `core.sh`, `validators.sh`, `selectors.sh`, `builders.sh`, `setup.sh`

#### Escenario: Archivos de Módulo Existen con Exports Correctos

- DADO que la estructura modular existe
- CUANDO se inspecciona cada archivo de módulo
- ENTONCES cada uno contiene solo funciones belonging a su categoría
- Y ninguna función aparece en más de un módulo

---

### Requisito: Contratos del Punto de Entrada

El punto de entrada `init-project.sh` DEBE:

1. **Variables Globales** (líneas 10-37 del original):
   - Declarar constantes de color: `RED`, `GREEN`, `YELLOW`, `CYAN`, `MAGENTA`, `WHITE`, `BOLD`, `DIM`, `NC`
   - Declarar variables de estado: `SELECTED_PKG_MANAGER`, `PROJECT_TYPE`, `BACKEND_TYPE`, `ARCHITECTURE`, `DOCKER_DB_TYPE`, `DOCKER_AVAILABLE`
   - Declarar variables de tracking: `ORIGINAL_DIR`, `PROJECT_CREATED`, `CLEANUP_DONE`

2. **Función Utilitaria**:
   - Definir `slugify()` con firma: `slugify(input: string) -> string`

3. **Función de Orquestación**:
   - Definir `main()` que orquesta el workflow llamando funciones de módulos en secuencia

4. **Mecanismo de Sourcing**:
   - Hacer source de todos los módulos via: `for lib in "$(dirname "${BASH_SOURCE[0]}")/lib/*.sh"; do source "$lib"; done`

5. **Manejo de Errores**:
   - Setear `set -e` en punto de entrada
   - Setear trap para `cleanup $? EXIT INT TERM`

#### Escenario: Validación de Sintaxis del Punto de Entrada

- DADO el punto de entrada refactorizado
- CUANDO se ejecuta `bash -n init-project/init-project.sh`
- ENTONCES el comando sale con status 0 (sin errores de sintaxis)

#### Escenario: Orden de Sourcing de Módulos

- DADO que todos los archivos de módulo existen
- CUANDO `bash -n init-project.sh` pasa
- ENTONCES `source lib/*.sh` carga exitosamente todos los módulos
- Y las 44 funciones originales están disponibles en el shell

---

### Requisito: Módulo: core.sh

**Archivo**: `init-project/lib/core.sh`

**Funciones** (DEBE exportar):

| Función | Firma | Descripción |
|----------|-------|-------------|
| `log` | `log <mensaje>` | Imprime mensaje con interpretación de color ANSI |
| `log_info` | `log_info <mensaje>` | Imprime mensaje de nivel INFO en cyan |
| `log_success` | `log_success <mensaje>` | Imprime mensaje de éxito en verde |
| `log_warn` | `log_warn <mensaje>` | Imprime mensaje de warning en amarillo |
| `log_error` | `log_error <mensaje>` | Imprime mensaje de error en rojo a stderr |
| `print_banner` | `print_banner` | Muestra banner ASCII del SAI Project Initializer |
| `cleanup` | `cleanup [exit_code]` | Handler de cleanup con verificación de idempotencia; deshace creación parcial de proyecto en error |
| `run_with_timeout` | `run_with_timeout <segundos> <cmd...>` | Ejecuta comando con timeout (Linux timeout, macOS gtimeout, o fallback perl) |

**Variables** (DEBE definir):
- Todas las constantes de color (RED, GREEN, YELLOW, CYAN, MAGENTA, WHITE, BOLD, DIM, NC)

**Dependencias**: Ninguna (self-contained)

**Comportamiento**: Las funciones envían output a stdout excepto `log_error` que envía a stderr.

#### Escenario: Validación de Sintaxis core.sh

- DADO `init-project/lib/core.sh`
- CUANDO se ejecuta `bash -n init-project/lib/core.sh`
- ENTONCES exit status es 0

#### Escenario: log_error Envía a stderr

- DADO que core.sh está cargado
- CUANDO se ejecuta `log_error "test error"`
- ENTONCES el output aparece en file descriptor 2

#### Escenario: Idempotencia de cleanup

- DADO que `cleanup` ha sido llamada una vez
- CUANDO `cleanup` se llama de nuevo
- ENTONCES retorna inmediatamente sin re-ejecutar lógica de cleanup
- Y `CLEANUP_DONE` permanece en 1

---

### Requisito: Módulo: validators.sh

**Archivo**: `init-project/lib/validators.sh`

**Funciones** (DEBE exportar):

| Función | Firma | Descripción |
|----------|-------|-------------|
| `check_dependencies` | `check_dependencies` | Verifica que existan comandos requeridos basados en `SELECTED_PKG_MANAGER` y `BACKEND_TYPE`; sale si falta alguno |
| `check_docker` | `check_docker` | Verifica si Docker está instalado y daemon corriendo; setea variable global `DOCKER_AVAILABLE` |

**Variables Globales** (DEBE leer):
- `SELECTED_PKG_MANAGER` - usado para determinar qué comandos verificar
- `BACKEND_TYPE` - verificado para golang para verificar comando `go`

**Variables Globales** (DEBE setear):
- `DOCKER_AVAILABLE` - seteada a 1 o 0 basado en disponibilidad de Docker

**Dependencias**: Requiere `core.sh` para funciones de logging

#### Escenario: Validación de Sintaxis validators.sh

- DADO `init-project/lib/validators.sh`
- CUANDO se ejecuta `bash -n init-project/lib/validators.sh`
- ENTONCES exit status es 0

#### Escenario: check_dependencies Comando Faltante

- DADO que `check_dependencies` se llama con un comando inexistente
- CUANDO un comando requerido falta (ej. `bun` no instalado cuando se seleccionó)
- ENTONCES `log_error` es llamado con "Faltan dependencias: <missing>"
- Y el script sale con código 1

#### Escenario: check_docker Docker Disponible

- DADO Docker está instalado y daemon corriendo
- CUANDO se llama `check_docker`
- ENTONCES `DOCKER_AVAILABLE` se setea a 1
- Y `log_success "Docker disponible"` es llamado

#### Escenario: check_docker Docker No Disponible

- DADO Docker no está instalado o daemon no está corriendo
- CUANDO se llama `check_docker`
- ENTONCES `DOCKER_AVAILABLE` se setea a 0
- Y `log_warn` es llamado con mensaje apropiado

---

### Requisito: Módulo: selectors.sh

**Archivo**: `init-project/lib/selectors.sh`

**Funciones** (DEBE exportar):

| Función | Firma | Descripción |
|----------|-------|-------------|
| `select_project_name` | `select_project_name` | Pide nombre de proyecto; valida formato (minúsculas, empieza con letra, sin espacios); setea `PROJECT_NAME` |
| `select_package_manager` | `select_package_manager` | Pide elección de package manager (bun/pnpm/npm); setea `SELECTED_PKG_MANAGER` |
| `select_project_type` | `select_project_type` | Pide tipo de proyecto (frontend-next/frontend-vite/backend/monorepo); setea `PROJECT_TYPE` |
| `select_backend_type` | `select_backend_type` | Pide framework de backend (nestjs/golang); setea `BACKEND_TYPE` |
| `select_architecture` | `select_architecture` | Pide arquitectura (modular/hexagonal/layered); setea `ARCHITECTURE` |

#### Escenario: select_architecture Muestra 3 Opciones

- DADO usuario llama `select_architecture`
- ENTONCES ve 3 opciones: Modular, Hexagonal, Layered
- Y la opción por defecto es Modular si la elección es inválida
| `select_agent` | `select_agent` | Pide agente de IA (opencode/claude/cursor/gemini/all); setea `TARGET_AGENT` |
| `select_graphify` | `select_graphify` | Pide habilitación de Graphify; setea `USE_GRAPHIFY` |
| `select_docker_db` | `select_docker_db` | Pide opción de Docker database; setea `DOCKER_DB_TYPE` basado en `DOCKER_AVAILABLE` |
| `confirm_setup` | `confirm_setup` | Muestra resumen y pide confirmación; sale en rechazo |

**Variables Globales** (DEBE setear):
- `PROJECT_NAME` - nombre de proyecto sanitizado
- `SELECTED_PKG_MANAGER` - bun/pnpm/npm
- `PROJECT_TYPE` - frontend-next/frontend-vite/backend/monorepo
- `BACKEND_TYPE` - nestjs/golang
- `ARCHITECTURE` - modular/hexagonal/layered
- `TARGET_AGENT` - opencode/claude/cursor/gemini/all
- `USE_GRAPHIFY` - yes/no
- `DOCKER_DB_TYPE` - postgres/mongodb/redis/postgres-redis/mongodb-redis/all/both/none

**Variables Globales** (DEBE leer):
- `PROJECT_TYPE` - para determinar si backend/monorepo para `select_backend_type`
- `DOCKER_AVAILABLE` - para mostrar opciones de Docker condicionalmente

**Dependencias**: Requiere `core.sh` para logging, `validators.sh` para `check_docker`

#### Escenario: Validación de Sintaxis selectors.sh

- DADO `init-project/lib/selectors.sh`
- CUANDO se ejecuta `bash -n init-project/lib/selectors.sh`
- ENTONCES exit status es 0

#### Escenario: Validación select_project_name

- DADO usuario ingresa "Mi Proyecto" (inválido)
- CUANDO se llama `select_project_name`
- ENTONCES `log_error` reporta falla de validación
- Y usuario es re-prompted

#### Escenario: select_project_name Éxito

- DADO usuario ingresa nombre válido "mi-proyecto"
- CUANDO se llama `select_project_name`
- ENTONCES `PROJECT_NAME` se setea a "mi-proyecto"
- Y el nombre se convierte a minúsculas

#### Escenario: select_docker_db Sin Docker

- DADO `DOCKER_AVAILABLE` es 0
- CUANDO se llama `select_docker_db`
- ENTONCES solo se muestra opción "No incluir Docker"
- Y `DOCKER_DB_TYPE` se setea a "none"

#### Escenario: select_docker_db Muestra 7 Opciones

- DADO Docker está disponible
- CUANDO se llama `select_docker_db`
- ENTONCES usuario ve 7 opciones:
  1) PostgreSQL
  2) MongoDB
  3) Redis
  4) PostgreSQL + Redis
  5) MongoDB + Redis
  6) Todas
  7) No incluir Docker

#### Escenario: select_docker_db Retorna DOCKER_DB_TYPE Correcto

- DADO usuario selecciona cada opción
- CUANDO `select_docker_db` procesa selección
- ENTONCES DOCKER_DB_TYPE se setea correctamente:
  - Opción 1 → "postgres"
  - Opción 2 → "mongodb"
  - Opción 3 → "redis"
  - Opción 4 → "postgres-redis"
  - Opción 5 → "mongodb-redis"
  - Opción 6 → "all"
  - Opción 7 → "none"

---

### Requisito: Módulo: builders.sh

**Archivo**: `init-project/lib/builders.sh`

**Funciones** (DEBE exportar):

| Función | Firma | Descripción |
|----------|-------|-------------|
| `create_frontend_next` | `create_frontend_next` | Crear proyecto Next.js con TypeScript, Tailwind, Prisma, App Router |
| `create_frontend_vite` | `create_frontend_vite` | Crear proyecto React + Vite con TypeScript y Tailwind |
| `create_backend_nestjs` | `create_backend_nestjs` | Crear proyecto backend NestJS |
| `create_backend_golang` | `create_backend_golang` | Crear proyecto backend Go + Gin |
| `create_monorepo` | `create_monorepo` | Crear monorepo con frontend Next.js y backend configurable |

**Variables Globales** (DEBE leer):
- `PROJECT_NAME`, `SELECTED_PKG_MANAGER`, `BACKEND_TYPE`, `PROJECT_TYPE`

**Variables Globales** (DEBE setear):
- `PROJECT_CREATED` - seteada a 1 después de `mkdir` exitoso

**Dependencias**: Requiere `core.sh` para logging y `run_with_timeout`, `validators.sh` para `check_dependencies`

**Notas de Comportamiento**:
- Cada función crea directorio, inicializa git, scaffoldea proyecto, instala dependencias
- Usa `run_with_timeout` para comandos de larga duración (300s para scaffolding, 120s para installs)
- Setea `PROJECT_CREATED=1` ANTES de cambiar al directorio del proyecto
- En falla, depende del trap `cleanup` para remover directorio parcial

#### Escenario: Validación de Sintaxis builders.sh

- DADO `init-project/lib/builders.sh`
- CUANDO se ejecuta `bash -n init-project/lib/builders.sh`
- ENTONCES exit status es 0

#### Escenario: create_frontend_next Crea Directorio

- DADO `PROJECT_NAME` y `SELECTED_PKG_MANAGER` válidos
- CUANDO se llama `create_frontend_next`
- ENTONCES directorio `PROJECT_NAME/` es creado
- Y `PROJECT_CREATED` se setea a 1

#### Escenario: Estructura de Proyecto create_backend_golang

- DADO `PROJECT_NAME` válido
- CUANDO se llama `create_backend_golang`
- ENTONCES `cmd/server/main.go` existe
- Y `go.mod` contiene el nombre de módulo correcto

---

### Requisito: Módulo: setup.sh

**Archivo**: `init-project/lib/setup.sh`

**Funciones** (DEBE exportar):

| Función | Firma | Descripción |
|----------|-------|-------------|
| `setup_github_actions` | `setup_github_actions` | Crear `.github/workflows/release.yml` |
| `setup_env_template` | `setup_env_template` | Crear template `.env.example` |
| `setup_vscode` | `setup_vscode` | Crear `.vscode/settings.json` |
| `setup_agents_md` | `setup_agents_md` | Crear `AGENTS.md` con reglas específicas de arquitectura |
| `setup_agent_rules` | `setup_agent_rules` | Copiar AGENTS.md a CLAUDE.md, GEMINI.md, .cursorrules basado en `TARGET_AGENT` |
| `setup_skills` | `setup_skills` | Crear estructura de directorio `.agent/skills/` |
| `setup_husky` | `setup_husky` | Inicializar Husky con hooks commit-msg y pre-push |
| `setup_scripts` | `setup_scripts` | Agregar scripts test, db:seed, db:reset, release a package.json |
| `setup_vitest` | `setup_vitest` | Crear `vitest.config.ts` en Strict TDD Mode |
| `setup_versioning` | `setup_versioning` | Configurar standard-version, crear CHANGELOG.md, VERSION, commit inicial y tag |
| `setup_git_workflow` | `setup_git_workflow` | Crear script de automatización `git-c` |
| `setup_git_initial` | `setup_git_initial` | Configurar git user.email/name si no está seteado, stagear todos los archivos |
| `setup_graphify` | `setup_graphify` | Instalar graphifyy si `USE_GRAPHIFY=yes` |
| `setup_gga` | `setup_gga` | Configurar Gentleman Guardian Angel si está instalado |
| `setup_docker_db` | `setup_docker_db` | Crear docker-compose.yml y scripts de ayuda si Docker seleccionado |

**Variables Globales** (DEBE leer):
- `SELECTED_PKG_MANAGER`, `PROJECT_TYPE`, `BACKEND_TYPE`, `ARCHITECTURE`
- `TARGET_AGENT`, `USE_GRAPHIFY`, `DOCKER_DB_TYPE`

**Dependencias**: Requiere `core.sh` para logging

#### Escenario: Validación de Sintaxis setup.sh

- DADO `init-project/lib/setup.sh`
- CUANDO se ejecuta `bash -n init-project/lib/setup.sh`
- ENTONCES exit status es 0

#### Escenario: setup_agents_md Arquitectura Hexagonal

- DADO `ARCHITECTURE` es "hexagonal"
- CUANDO se llama `setup_agents_md`
- ENTONCES AGENTS.md contiene sección "HEXAGONAL ARCHITECTURE"

#### Escenario: setup_agents_md Arquitectura Modular

- DADO `ARCHITECTURE` es "modular"
- CUANDO se llama `setup_agents_md`
- ENTONCES AGENTS.md contiene sección "MODULAR VERTICAL SLICING"

#### Escenario: setup_agents_md Arquitectura Layered

- DADO `ARCHITECTURE` es "layered"
- CUANDO se llama `setup_agents_md`
- ENTONCES AGENTS.md contiene sección "LAYERED ARCHITECTURE"

#### Escenario: setup_docker_db Omite Cuando es None

- DADO `DOCKER_DB_TYPE` es "none"
- CUANDO se llama `setup_docker_db`
- ENTONCES la función retorna inmediatamente sin crear archivos

#### Escenario: setup_docker_db Genera Servicio Redis

- DADO `DOCKER_DB_TYPE` incluye "redis" (redis/postgres-redis/mongodb-redis/all)
- CUANDO se llama `setup_docker_db`
- ENTONCES `docker-compose.yml` contiene servicio `redis` con:
  - imagen: `redis:7.2-alpine`
  - puertos: `6379:6379`
  - volúmenes: `redis_data:/data`
  - comando: `redis-server --appendonly yes`
  - healthcheck: `redis-cli ping`

#### Escenario: setup_docker_db Genera Admin GUIs

- DADO `DOCKER_DB_TYPE` incluye base de datos
- CUANDO se llama `setup_docker_db`
- ENTONCES `docker-compose.yml` contiene admin GUI correspondiente:

| DOCKER_DB_TYPE | Servicio Admin | Imagen | Puerto |
|----------------|-----------------|--------|--------|
| postgres/postgres-redis/all/both | adminer | adminer:latest | 8080 |
| mongodb/mongodb-redis/all/both | mongo-express | mongo-express:latest | 8081 |
| redis/postgres-redis/mongodb-redis/all | redis-commander | rediscommander/redis-commander:latest | 8082 |

#### Escenario: Admin GUIs Dependen de Base de Datos

- DADO servicio admin GUI está configurado
- CUANDO docker-compose inicia contenedores
- ENTONCES admin GUI espera base de datos via `depends_on`
- Y base de datos debe estar healthy antes que admin GUI inicie

#### Escenario: setup_docker_db Crea Volumen redis_data

- DADO `DOCKER_DB_TYPE` incluye redis
- CUANDO se llama `setup_docker_db`
- ENTONCES `docker-compose.yml` contiene volumen `redis_data`

---

### Requisito: Orden de Sourcing y Dependencias

El orden de sourcing DEBE ser:

1. `core.sh` (sin dependencias)
2. `validators.sh` (depende de core.sh)
3. `selectors.sh` (depende de core.sh, validators.sh)
4. `builders.sh` (depende de core.sh, validators.sh)
5. `setup.sh` (depende de core.sh)

El punto de entrada DEBE hacer source de módulos en este orden para asegurar que las funciones estén disponibles antes de que módulos dependientes carguen.

#### Escenario: Verificación de Orden de Sourcing

- DADO el punto de entrada hace source de módulos
- CUANDO se ejecuta `bash -x init-project/init-project.sh -c 'type log; type check_dependencies; type select_project_name'`
- ENTONCES todas las funciones se encuentran sin errores

---

### Requisito: Compatibilidad hacia Atrás

La refactorización DEBE mantener 100% compatibilidad hacia atrás para instalación `curl -fsSL URL | bash`.

#### Escenario: Instalación via curl Funciona

- DADO una URL remota apuntando a `init-project/init-project.sh`
- CUANDO se ejecuta `curl -fsSL <URL> | bash`
- ENTONCES el script corre idénticamente a antes de la refactorización
- Y las 44 funciones están disponibles

#### Escenario: Ejecución Directa Funciona

- DADO el usuario ejecuta `bash init-project/init-project.sh`
- CUANDO el script ejecuta
- ENTONCES se comporta idénticamente al script monolítico original

---

### Requisito: Preservación de Firmas de Funciones

Las 44 funciones originales DEBEN mantener sus firmas exactas después de la refactorización.

#### Escenario: Todas las Funciones Preservadas

- DADO todos los módulos están cargados
- CUANDO se ejecuta `compgen -A function | grep -E '^(log|check_|select_|create_|setup_|print_|run_with_timeout|slugify|cleanup)'`
- ENTONCES exactamente 44 funciones son listadas

---

## REQUISITOS MODIFICADOS

### Requisito: Reducción del Punto de Entrada

**Anteriormente**: `init-project.sh` contenía 2836 líneas con todas las funciones inline.

**Ahora**: `init-project/init-project.sh` DEBE contener aproximadamente 150 líneas, delegando todas las definiciones de funciones a módulos.

(Razón: Mejorar mantenibilidad y habilitar testing por módulo)

---

## REQUISITOS ELIMINADOS

Ninguno. Esta es una refactorización pura sin cambios funcionales.

---

## Inventario de Archivos

| Ruta de Archivo | Líneas (est.) | Funciones | Propósito |
|-----------------|---------------|-----------|-----------|
| `init-project/init-project.sh` | ~200 | 3 (main, slugify, source loop) | Punto de entrada |
| `init-project/lib/core.sh` | ~100 | 8 | Logging, colores, cleanup, timeout |
| `init-project/lib/validators.sh` | ~80 | 2 | Verificación de dependencias y Docker |
| `init-project/lib/selectors.sh` | ~420 | 9 | Configuración interactiva de proyecto |
| `init-project/lib/builders.sh` | ~600 | 5 | Scaffolding de proyectos |
| `init-project/lib/setup.sh` | ~1800 | 16 | Configuración post-scaffold (Docker + Admin GUIs) |

---

## Criterios de Aceptación

| ID | Criterio | Comando de Verificación |
|----|----------|------------------------|
| AC1 | Punto de entrada pasa check de sintaxis | `bash -n init-project/init-project.sh` |
| AC2 | Todos los módulos pasan check de sintaxis | `bash -n init-project/lib/*.sh` (todos exit 0) |
| AC3 | Las 44 funciones existen | `bash -c 'source init-project/init-project.sh; compgen -A function \| wc -l'` >= 44 |
| AC4 | Instalación curl funciona | `curl -fsSL file://$(pwd)/init-project/init-project.sh \| bash -c 'type main'` |
| AC5 | Sin cambios de comportamiento | Diff de outputs de funciones antes/después de refactorización |
| AC6 | Orden de sourcing correcto | `bash -x init-project/init-project.sh -c 'type log' 2>&1 \| grep -c 'source'` |
| AC7 | Variables globales preservadas | `grep -E '^(RED\|GREEN\|SELECTED_PKG_MANAGER\|PROJECT_TYPE)' init-project/init-project.sh` |
| AC8 | cleanup trap seteado | `grep "trap 'cleanup" init-project/init-project.sh` |
| AC9 | Módulos en directorio correcto | `ls init-project/lib/` muestra 5 archivos .sh |
| AC10 | Punto de entrada hace source de módulos | `grep "source.*lib/" init-project/init-project.sh` |
| AC11 | Docker DB muestra 7 opciones | Interactivo: `select_docker_db` muestra opciones 1-7 |
| AC12 | Servicio Redis en compose | `docker compose config` incluye servicio redis |
| AC13 | Servicio Adminer para postgres | `docker compose config` incluye adminer (8080) |
| AC14 | MongoDB Express para mongodb | `docker compose config` incluye mongo-express (8081) |
| AC15 | Redis Commander para redis | `docker compose config` incluye redis-commander (8082) |
| AC16 | Healthchecks configurados | `docker compose config` muestra healthcheck en cada servicio |
| AC17 | Volumen redis_data existe | `docker compose config` incluye volumen redis_data |

---

## Resumen de Contratos de Módulos

```
┌─────────────────────────────────────────────────────────────────┐
│                      init-project.sh                            │
│  (punto de entrada: source lib/*.sh, setea globals, llama main)│
└─────────────────────────────────────────────────────────────────┘
        │
        ├─► core.sh        (log*, print_banner, cleanup, run_with_timeout)
        │
        ├─► validators.sh  (check_dependencies, check_docker)
        │
        ├─► selectors.sh   (select_*, confirm_setup)
        │
        ├─► builders.sh    (create_frontend_*, create_backend_*, create_monorepo)
        │
        └─► setup.sh       (setup_* functions)
```

## Verificación de Rollback

- [ ] `rm -rf init-project/lib/` restaura estructura monolítica original
- [ ] `git checkout HEAD -- init-project.sh` restaura archivo original de 2836 líneas
