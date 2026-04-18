# Delta for init-project.sh Modular Refactor

## ADDED Requirements

### Requirement: Modular File Structure

The system MUST organize `init-project.sh` into a modular directory structure under `init-project/` with the following layout:

```
init-project/
├── init-project.sh          # Entry point (~150 lines)
└── lib/
    ├── core.sh              # Constants, colors, logging, banner, cleanup, timeout
    ├── validators.sh         # Dependency and Docker checks
    ├── selectors.sh         # Interactive selection functions
    ├── builders.sh          # Project creation functions
    └── setup.sh             # Post-creation setup functions
```

#### Scenario: Directory Structure Creation

- GIVEN a fresh clone of the repository
- WHEN `ls -la init-project/` is executed
- THEN the directory contains `init-project.sh` and `lib/` subdirectory
- AND `lib/` contains exactly 5 `.sh` files: `core.sh`, `validators.sh`, `selectors.sh`, `builders.sh`, `setup.sh`

#### Scenario: Module Files Exist with Correct Exports

- GIVEN the modular structure exists
- WHEN each module file is inspected
- THEN each contains only functions belonging to its category
- AND no function appears in more than one module

---

### Requirement: Entry Point Module Contracts

The entry point `init-project.sh` MUST:

1. **Global Variables** (lines 10-37 of original):
   - Declare color constants: `RED`, `GREEN`, `YELLOW`, `CYAN`, `MAGENTA`, `WHITE`, `BOLD`, `DIM`, `NC`
   - Declare state variables: `SELECTED_PKG_MANAGER`, `PROJECT_TYPE`, `BACKEND_TYPE`, `ARCHITECTURE`, `DOCKER_DB_TYPE`, `DOCKER_AVAILABLE`
   - Declare tracking variables: `ORIGINAL_DIR`, `PROJECT_CREATED`, `CLEANUP_DONE`

2. **Utility Function**:
   - Define `slugify()` with signature: `slugify(input: string) -> string`

3. **Orchestration Function**:
   - Define `main()` that orchestrates the workflow by calling module functions in sequence

4. **Sourcing Mechanism**:
   - Source all modules via: `for lib in "$(dirname "${BASH_SOURCE[0]}")/lib/*.sh"; do source "$lib"; done`

5. **Error Handling**:
   - Set `set -e` at entry point
   - Set trap for `cleanup $? EXIT INT TERM`

#### Scenario: Entry Point Syntax Validation

- GIVEN the refactored entry point
- WHEN `bash -n init-project/init-project.sh` is executed
- THEN the command exits with status 0 (no syntax errors)

#### Scenario: Module Sourcing Order

- GIVEN all module files exist
- WHEN `bash -n init-project.sh` passes
- THEN `source lib/*.sh` successfully loads all modules
- AND all 44 original functions are available in the shell

---

### Requirement: Module: core.sh

**File**: `init-project/lib/core.sh`

**Functions** (MUST export):

| Function | Signature | Description |
|----------|-----------|-------------|
| `log` | `log <message>` | Print message with ANSI color interpretation |
| `log_info` | `log_info <message>` | Print INFO-level message in cyan |
| `log_success` | `log_success <message>` | Print success message in green |
| `log_warn` | `log_warn <message>` | Print warning message in yellow |
| `log_error` | `log_error <message>` | Print error message in red to stderr |
| `print_banner` | `print_banner` | Display SAI Project Initializer ASCII banner |
| `cleanup` | `cleanup [exit_code]` | Cleanup handler with idempotency check; undoes partial project creation on error |
| `run_with_timeout` | `run_with_timeout <seconds> <cmd...>` | Execute command with timeout (Linux timeout, macOS gtimeout, or perl fallback) |

**Variables** (MUST define):
- All color constants (RED, GREEN, YELLOW, CYAN, MAGENTA, WHITE, BOLD, DIM, NC)

**Dependencies**: None (self-contained)

**Behavior**: Functions output to stdout except `log_error` which outputs to stderr.

#### Scenario: core.sh Syntax Validation

- GIVEN `init-project/lib/core.sh`
- WHEN `bash -n init-project/lib/core.sh` is executed
- THEN exit status is 0

#### Scenario: log_error Outputs to stderr

- GIVEN core.sh is sourced
- WHEN `log_error "test error"` is executed
- THEN the output appears on file descriptor 2

#### Scenario: cleanup Idempotency

- GIVEN `cleanup` has been called once
- WHEN `cleanup` is called again
- THEN it returns immediately without re-executing cleanup logic
- AND `CLEANUP_DONE` remains 1

---

### Requirement: Module: validators.sh

**File**: `init-project/lib/validators.sh`

**Functions** (MUST export):

| Function | Signature | Description |
|----------|-----------|-------------|
| `check_dependencies` | `check_dependencies` | Verify required commands exist based on `SELECTED_PKG_MANAGER` and `BACKEND_TYPE`; exits on missing |
| `check_docker` | `check_docker` | Check if Docker is installed and daemon running; set `DOCKER_AVAILABLE` global |

**Global Variables** (MUST read):
- `SELECTED_PKG_MANAGER` - used to determine which commands to check
- `BACKEND_TYPE` - checked for golang to verify `go` command

**Global Variables** (MUST set):
- `DOCKER_AVAILABLE` - set to 1 or 0 based on Docker availability

**Dependencies**: Requires `core.sh` for logging functions

#### Scenario: validators.sh Syntax Validation

- GIVEN `init-project/lib/validators.sh`
- WHEN `bash -n init-project/lib/validators.sh` is executed
- THEN exit status is 0

#### Scenario: check_dependencies Missing Command

- GIVEN `check_dependencies` is called with a non-existent command
- WHEN a required command is missing (e.g., `bun` not installed when selected)
- THEN `log_error` is called with "Faltan dependencias: <missing>"
- AND script exits with code 1

#### Scenario: check_docker Docker Available

- GIVEN Docker is installed and daemon is running
- WHEN `check_docker` is called
- THEN `DOCKER_AVAILABLE` is set to 1
- AND `log_success "Docker disponible"` is called

#### Scenario: check_docker Docker Unavailable

- GIVEN Docker is not installed or daemon is not running
- WHEN `check_docker` is called
- THEN `DOCKER_AVAILABLE` is set to 0
- AND `log_warn` is called with appropriate message

---

### Requirement: Module: selectors.sh

**File**: `init-project/lib/selectors.sh`

**Functions** (MUST export):

| Function | Signature | Description |
|----------|-----------|-------------|
| `select_project_name` | `select_project_name` | Prompt for project name; validate format (lowercase, starts with letter, no spaces); set `PROJECT_NAME` |
| `select_package_manager` | `select_package_manager` | Prompt for package manager choice (bun/pnpm/npm); set `SELECTED_PKG_MANAGER` |
| `select_project_type` | `select_project_type` | Prompt for project type (frontend-next/frontend-vite/backend/monorepo); set `PROJECT_TYPE` |
| `select_backend_type` | `select_backend_type` | Prompt for backend framework (nestjs/golang); set `BACKEND_TYPE` |
| `select_architecture` | `select_architecture` | Prompt for architecture (modular/hexagonal); set `ARCHITECTURE` |
| `select_agent` | `select_agent` | Prompt for AI agent (opencode/claude/cursor/gemini/all); set `TARGET_AGENT` |
| `select_graphify` | `select_graphify` | Prompt for Graphify enable/disable; set `USE_GRAPHIFY` |
| `select_docker_db` | `select_docker_db` | Prompt for Docker database option; set `DOCKER_DB_TYPE` based on `DOCKER_AVAILABLE` |
| `confirm_setup` | `confirm_setup` | Display summary and prompt for confirmation; exit on rejection |

**Global Variables** (MUST set):
- `PROJECT_NAME` - sanitized project name
- `SELECTED_PKG_MANAGER` - bun/pnpm/npm
- `PROJECT_TYPE` - frontend-next/frontend-vite/backend/monorepo
- `BACKEND_TYPE` - nestjs/golang
- `ARCHITECTURE` - modular/hexagonal
- `TARGET_AGENT` - opencode/claude/cursor/gemini/all
- `USE_GRAPHIFY` - yes/no
- `DOCKER_DB_TYPE` - postgres/mongodb/redis/postgres-redis/mongodb-redis/all/both/none

**Global Variables** (MUST read):
- `PROJECT_TYPE` - to determine if backend/monorepo for `select_backend_type`
- `DOCKER_AVAILABLE` - to conditionally show Docker options

**Dependencies**: Requires `core.sh` for logging, `validators.sh` for `check_docker`

#### Scenario: selectors.sh Syntax Validation

- GIVEN `init-project/lib/selectors.sh`
- WHEN `bash -n init-project/lib/selectors.sh` is executed
- THEN exit status is 0

#### Scenario: select_project_name Validation

- GIVEN user enters "My Project" (invalid)
- WHEN `select_project_name` is called
- THEN `log_error` reports validation failure
- AND user is reprompted

#### Scenario: select_project_name Success

- GIVEN user enters valid name "mi-proyecto"
- WHEN `select_project_name` is called
- THEN `PROJECT_NAME` is set to "mi-proyecto"
- AND name is converted to lowercase

#### Scenario: select_docker_db Without Docker

- GIVEN `DOCKER_AVAILABLE` is 0
- WHEN `select_docker_db` is called
- THEN only option "No incluir Docker" is shown
- AND `DOCKER_DB_TYPE` is set to "none"

#### Scenario: select_docker_db Shows 7 Options

- GIVEN Docker is available
- WHEN `select_docker_db` is called
- THEN user sees 7 options:
  1) PostgreSQL
  2) MongoDB
  3) Redis
  4) PostgreSQL + Redis
  5) MongoDB + Redis
  6) Todas
  7) No incluir Docker

#### Scenario: select_docker_db Returns Correct DOCKER_DB_TYPE

- GIVEN user selects each option
- WHEN `select_docker_db` processes selection
- THEN DOCKER_DB_TYPE is set correctly:
  - Option 1 → "postgres"
  - Option 2 → "mongodb"
  - Option 3 → "redis"
  - Option 4 → "postgres-redis"
  - Option 5 → "mongodb-redis"
  - Option 6 → "all"
  - Option 7 → "none"

---

### Requirement: Module: builders.sh

**File**: `init-project/lib/builders.sh`

**Functions** (MUST export):

| Function | Signature | Description |
|----------|-----------|-------------|
| `create_frontend_next` | `create_frontend_next` | Create Next.js project with TypeScript, Tailwind, Prisma, App Router |
| `create_frontend_vite` | `create_frontend_vite` | Create React + Vite project with TypeScript and Tailwind |
| `create_backend_nestjs` | `create_backend_nestjs` | Create NestJS backend project |
| `create_backend_golang` | `create_backend_golang` | Create Go + Gin backend project |
| `create_monorepo` | `create_monorepo` | Create monorepo with Next.js frontend and configurable backend |

**Global Variables** (MUST read):
- `PROJECT_NAME`, `SELECTED_PKG_MANAGER`, `BACKEND_TYPE`, `PROJECT_TYPE`

**Global Variables** (MUST set):
- `PROJECT_CREATED` - set to 1 after successful `mkdir`

**Dependencies**: Requires `core.sh` for logging and `run_with_timeout`, `validators.sh` for `check_dependencies`

**Behavior Notes**:
- Each function creates directory, initializes git, scaffolds project, installs dependencies
- Uses `run_with_timeout` for long-running commands (300s for scaffolding, 120s for installs)
- Sets `PROJECT_CREATED=1` BEFORE changing into project directory
- On failure, relies on `cleanup` trap to remove partial directory

#### Scenario: builders.sh Syntax Validation

- GIVEN `init-project/lib/builders.sh`
- WHEN `bash -n init-project/lib/builders.sh` is executed
- THEN exit status is 0

#### Scenario: create_frontend_next Creates Directory

- GIVEN valid `PROJECT_NAME` and `SELECTED_PKG_MANAGER`
- WHEN `create_frontend_next` is called
- THEN directory `PROJECT_NAME/` is created
- AND `PROJECT_CREATED` is set to 1

#### Scenario: create_backend_golang Project Structure

- GIVEN valid `PROJECT_NAME`
- WHEN `create_backend_golang` is called
- THEN `cmd/server/main.go` exists
- AND `go.mod` contains correct module name

---

### Requirement: Module: setup.sh

**File**: `init-project/lib/setup.sh`

**Functions** (MUST export):

| Function | Signature | Description |
|----------|-----------|-------------|
| `setup_github_actions` | `setup_github_actions` | Create `.github/workflows/release.yml` |
| `setup_env_template` | `setup_env_template` | Create `.env.example` template |
| `setup_vscode` | `setup_vscode` | Create `.vscode/settings.json` |
| `setup_agents_md` | `setup_agents_md` | Create `AGENTS.md` with architecture-specific rules |
| `setup_agent_rules` | `setup_agent_rules` | Copy AGENTS.md to CLAUDE.md, GEMINI.md, .cursorrules based on `TARGET_AGENT` |
| `setup_skills` | `setup_skills` | Create `.agent/skills/` directory structure |
| `setup_husky` | `setup_husky` | Initialize Husky with commit-msg and pre-push hooks |
| `setup_scripts` | `setup_scripts` | Add test, db:seed, db:reset, release scripts to package.json |
| `setup_vitest` | `setup_vitest` | Create `vitest.config.ts` in Strict TDD Mode |
| `setup_versioning` | `setup_versioning` | Configure standard-version, create CHANGELOG.md, VERSION, initial git commit and tag |
| `setup_git_workflow` | `setup_git_workflow` | Create `git-c` automation script |
| `setup_git_initial` | `setup_git_initial` | Configure git user.email/name if not set, stage all files |
| `setup_graphify` | `setup_graphify` | Install graphifyy if `USE_GRAPHIFY=yes` |
| `setup_gga` | `setup_gga` | Configure Gentleman Guardian Angel if installed |
| `setup_docker_db` | `setup_docker_db` | Create docker-compose.yml and helper scripts if Docker selected |

**Global Variables** (MUST read):
- `SELECTED_PKG_MANAGER`, `PROJECT_TYPE`, `BACKEND_TYPE`, `ARCHITECTURE`
- `TARGET_AGENT`, `USE_GRAPHIFY`, `DOCKER_DB_TYPE`

**Dependencies**: Requires `core.sh` for logging

#### Scenario: setup.sh Syntax Validation

- GIVEN `init-project/lib/setup.sh`
- WHEN `bash -n init-project/lib/setup.sh` is executed
- THEN exit status is 0

#### Scenario: setup_agents_md Hexagonal Architecture

- GIVEN `ARCHITECTURE` is "hexagonal"
- WHEN `setup_agents_md` is called
- THEN AGENTS.md contains "HEXAGONAL ARCHITECTURE" section

#### Scenario: setup_agents_md Modular Architecture

- GIVEN `ARCHITECTURE` is "modular"
- WHEN `setup_agents_md` is called
- THEN AGENTS.md contains "MODULAR VERTICAL SLICING" section

#### Scenario: setup_docker_db Skip When None

- GIVEN `DOCKER_DB_TYPE` is "none"
- WHEN `setup_docker_db` is called
- THEN function returns immediately without creating files

#### Scenario: setup_docker_db Generates Redis Service

- GIVEN `DOCKER_DB_TYPE` includes "redis" (redis/postgres-redis/mongodb-redis/all)
- WHEN `setup_docker_db` is called
- THEN `docker-compose.yml` contains service `redis` with:
  - image: `redis:7.2-alpine`
  - ports: `6379:6379`
  - volumes: `redis_data:/data`
  - command: `redis-server --appendonly yes`
  - healthcheck: `redis-cli ping`

#### Scenario: setup_docker_db Generates Admin GUIs

- GIVEN `DOCKER_DB_TYPE` includes database
- WHEN `setup_docker_db` is called
- THEN `docker-compose.yml` contains corresponding admin GUI:

| DOCKER_DB_TYPE | Admin Service | Image | Port |
|----------------|---------------|-------|------|
| postgres/postgres-redis/all/both | adminer | adminer:latest | 8080 |
| mongodb/mongodb-redis/all/both | mongo-express | mongo-express:latest | 8081 |
| redis/postgres-redis/mongodb-redis/all | redis-commander | rediscommander/redis-commander:latest | 8082 |

#### Scenario: Admin GUIs Depend on Database

- GIVEN admin GUI service is configured
- WHEN docker-compose starts containers
- THEN admin GUI waits for database via `depends_on`
- AND database must be healthy before admin GUI starts

#### Scenario: setup_docker_db Creates Volume redis_data

- GIVEN `DOCKER_DB_TYPE` includes redis
- WHEN `setup_docker_db` is called
- THEN `docker-compose.yml` contains volume `redis_data`

---

### Requirement: Sourcing Order and Dependencies

The source order MUST be:

1. `core.sh` (no dependencies)
2. `validators.sh` (depends on core.sh)
3. `selectors.sh` (depends on core.sh, validators.sh)
4. `builders.sh` (depends on core.sh, validators.sh)
5. `setup.sh` (depends on core.sh)

The entry point MUST source modules in this order to ensure functions are available before dependent modules load.

#### Scenario: Sourcing Order Verification

- GIVEN the entry point sources modules
- WHEN `bash -x init-project/init-project.sh -c 'type log; type check_dependencies; type select_project_name'` is executed
- THEN all functions are found without errors

---

### Requirement: Backward Compatibility

The refactor MUST maintain 100% backward compatibility for `curl -fsSL URL | bash` installation.

#### Scenario: curl Installation Works

- GIVEN a remote URL pointing to `init-project/init-project.sh`
- WHEN `curl -fsSL <URL> | bash` is executed
- THEN the script runs identically to before the refactor
- AND all 44 functions are available

#### Scenario: Direct Execution Works

- GIVEN the user runs `bash init-project/init-project.sh`
- WHEN the script executes
- THEN it behaves identically to the original monolithic script

---

### Requirement: Function Signature Preservation

All 44 original functions MUST maintain their exact signatures after refactoring.

#### Scenario: All Functions Preserved

- GIVEN all modules are sourced
- WHEN `compgen -A function | grep -E '^(log|check_|select_|create_|setup_|print_|run_with_timeout|slugify|cleanup)'` is executed
- THEN exactly 44 functions are listed

---

## MODIFIED Requirements

### Requirement: Entry Point Shrinking

**Previously**: `init-project.sh` contained 2836 lines with all functions inline.

**Now**: `init-project/init-project.sh` MUST contain approximately 150 lines, delegating all function definitions to modules.

(Reason: Improve maintainability and enable per-module testing)

---

## REMOVED Requirements

None. This is a pure refactor with no functional changes.

---

## File Inventory

| File Path | Lines (est.) | Functions | Purpose |
|-----------|--------------|-----------|---------|
| `init-project/init-project.sh` | ~200 | 3 (main, slugify, source loop) | Entry point |
| `init-project/lib/core.sh` | ~100 | 8 | Logging, colors, cleanup, timeout |
| `init-project/lib/validators.sh` | ~80 | 2 | Dependency and Docker checks |
| `init-project/lib/selectors.sh` | ~420 | 9 | Interactive project configuration |
| `init-project/lib/builders.sh` | ~600 | 5 | Project scaffolding |
| `init-project/lib/setup.sh` | ~1800 | 16 | Post-scaffold configuration (Docker + Admin GUIs) |

---

## Acceptance Criteria

| ID | Criterion | Verification Command |
|----|-----------|---------------------|
| AC1 | Entry point passes syntax check | `bash -n init-project/init-project.sh` |
| AC2 | All modules pass syntax check | `bash -n init-project/lib/*.sh` (all exit 0) |
| AC3 | All 44 functions exist | `bash -c 'source init-project/init-project.sh; compgen -A function \| wc -l'` >= 44 |
| AC4 | curl installation works | `curl -fsSL file://$(pwd)/init-project/init-project.sh \| bash -c 'type main'` |
| AC5 | No behavior changes | Diff of function outputs before/after refactor |
| AC6 | Sourcing order correct | `bash -x init-project/init-project.sh -c 'type log' 2>&1 \| grep -c 'source'` |
| AC7 | Global variables preserved | `grep -E '^(RED\|GREEN\|SELECTED_PKG_MANAGER\|PROJECT_TYPE)' init-project/init-project.sh` |
| AC8 | cleanup trap set | `grep "trap 'cleanup" init-project/init-project.sh` |
| AC9 | Modules in correct directory | `ls init-project/lib/` shows 5 .sh files |
| AC10 | Entry point sources modules | `grep "source.*lib/" init-project/init-project.sh` |
| AC11 | Docker DB shows 7 options | Interactivo: `select_docker_db` muestra opciones 1-7 |
| AC12 | Redis service in compose | `docker compose config` incluye servicio redis |
| AC13 | Adminer service for postgres | `docker compose config` incluye adminer (8080) |
| AC14 | MongoDB Express for mongodb | `docker compose config` incluye mongo-express (8081) |
| AC15 | Redis Commander for redis | `docker compose config` incluye redis-commander (8082) |
| AC16 | Healthchecks configured | `docker compose config` muestra healthcheck en cada servicio |
| AC17 | redis_data volume exists | `docker compose config` incluye volumen redis_data |

---

## Module Contract Summary

```
┌─────────────────────────────────────────────────────────────────┐
│                      init-project.sh                            │
│  (entry point: sources lib/*.sh, sets globals, calls main)        │
└─────────────────────────────────────────────────────────────────┘
        │
        ├─► core.sh        (log*, print_banner, cleanup, run_with_timeout)
        │
        ├─► validators.sh  (check_dependencies, check_docker)
        │
        ├─► selectors.sh   (select_*, confirm_setup)
        │
        ├─► builders.sh     (create_frontend_*, create_backend_*, create_monorepo)
        │
        └─► setup.sh       (setup_* functions)
```

## Rollback Verification

- [ ] `rm -rf init-project/lib/` restores original monolithic structure
- [ ] `git checkout HEAD -- init-project.sh` restores original 2836-line file
