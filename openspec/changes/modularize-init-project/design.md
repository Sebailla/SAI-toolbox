# Design: Modularize init-project.sh

## Technical Approach

Transform the monolithic 2836-line `init-project.sh` into a modular directory structure under `init-project/` with clear separation of concerns. The entry point (`init-project.sh`) will source modules via a glob loop, declare globals, and delegate all function definitions to module files. This enables per-module testing and improved maintainability while preserving 100% backward compatibility.

## Architecture Decisions

### Decision: Sourcing Mechanism — Loop vs Explicit

**Choice**: Use `for lib in "$(dirname "${BASH_SOURCE[0]}")/lib/*.sh"; do source "$lib"; done`

**Alternatives considered**:
- Explicit `source lib/core.sh; source lib/validators.sh; ...` — explicit ordering but requires manual maintenance
- Dynamic `find` with sorting — more complex, less portable

**Rationale**: The spec mandates this exact syntax. The loop approach is concise and automatically picks up new modules, while the spec's exact ordering constraint ensures dependencies resolve correctly regardless of alphabetical sort.

### Decision: Variable Scope Strategy

**Choice**: 
- **Global (declared in entry point)**: Color constants, state variables (`SELECTED_PKG_MANAGER`, `PROJECT_TYPE`, `BACKEND_TYPE`, `ARCHITECTURE`, `DOCKER_DB_TYPE`, `DOCKER_AVAILABLE`, `ORIGINAL_DIR`, `PROJECT_CREATED`, `CLEANUP_DONE`)
- **Global (set by modules)**: All `select_*` and `check_*` functions set their respective variables directly in global scope
- **Local (within functions)**: Loop variables, temporary strings, command outputs use `local`

**Alternatives considered**:
- Pass all values via return/exit codes — bash limitation makes this cumbersome
- Export to environment — risk of pollution

**Rationale**: Bash doesn't support passing by reference or closures. Global variables are the standard pattern in bash scripts. Modules set module-specific globals; entry point owns shared state.

### Decision: Error Propagation

**Choice**: `set -e` at entry point with trap `cleanup $? EXIT INT TERM`

**Alternatives considered**:
- Per-module error handling — inconsistent, verbose
- No `set -e` — silent failures become bugs

**Rationale**: Spec mandates this exact pattern. `set -e` causes any command failure to exit immediately. The trap catches EXIT (normal or error), INT (Ctrl+C), TERM (kill). `cleanup` uses `CLEANUP_DONE` flag for idempotency.

## File Structure

```
init-project/
├── init-project.sh     (~150 lines, entry point)
└── lib/
    ├── core.sh         (~100 lines, 8 functions)
    ├── validators.sh   (~80 lines, 2 functions)
    ├── selectors.sh    (~350 lines, 9 functions)
    ├── builders.sh     (~600 lines, 5 functions)
    └── setup.sh        (~750 lines, 16 functions)
```

## Module Dependencies

```
init-project.sh (entry point)
  └─ sources lib/*.sh in order: core → validators → selectors → builders → setup

core.sh (no deps)
  └─ log, log_info, log_success, log_warn, log_error, print_banner, cleanup, run_with_timeout

validators.sh (depends on core)
  └─ check_dependencies, check_docker

selectors.sh (depends on core, validators)
  └─ select_project_name, select_package_manager, select_project_type, select_backend_type, 
     select_architecture, select_agent, select_graphify, select_docker_db, confirm_setup

builders.sh (depends on core, validators)
  └─ create_frontend_next, create_frontend_vite, create_backend_nestjs, 
     create_backend_golang, create_monorepo

setup.sh (depends on core)
  └─ setup_github_actions, setup_env_template, setup_vscode, setup_agents_md,
     setup_agent_rules, setup_skills, setup_husky, setup_scripts, setup_vitest,
     enrich_gitignore, setup_git_workflow, setup_git_initial, setup_graphify,
     setup_gga, setup_docker_db
```

## Implementation Approach

### Step 1: Create directory structure

```bash
mkdir -p init-project/lib
```

### Step 2: Create core.sh (lines 10-98, 509-545 from original)

Extract: color constants, `log` family functions, `print_banner`, `run_with_timeout`. Core has no dependencies.

### Step 3: Create validators.sh (lines 434-503 from original)

Extract: `check_dependencies`, `check_docker`. Depends on core.sh logging.

### Step 4: Create selectors.sh (lines 101-428 from original)

Extract: all `select_*` functions and `confirm_setup`. Depends on validators for `check_docker` called in `select_docker_db`.

### Step 5: Create builders.sh (lines 551-1121 from original)

Extract: all `create_*` functions. Depends on core for logging and `run_with_timeout`, validators for `check_dependencies` (called inside builders via `set -e` on dependency check).

### Step 6: Create setup.sh (lines 1127-2360 from original)

Extract: all `setup_*` and `enrich_gitignore`. Depends only on core.

### Step 7: Create entry point (~150 lines)

```bash
#!/usr/bin/env bash

set -e

# === COLORS ===
RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[0;33m'
CYAN=$'\033[0;36m'
MAGENTA=$'\033[0;35m'
WHITE=$'\033[0;37m'
BOLD=$'\033[1m'
DIM=$'\033[2m'
NC=$'\033[0m'

# === STATE VARIABLES ===
SELECTED_PKG_MANAGER=""
PROJECT_TYPE=""
BACKEND_TYPE=""
ARCHITECTURE=""
DOCKER_DB_TYPE="none"
DOCKER_AVAILABLE=0

# === TRACKING ===
ORIGINAL_DIR=$(pwd)
PROJECT_CREATED=0
CLEANUP_DONE=0

# === CLEANUP TRAP ===
cleanup() {
    local exit_code=${1:-0}
    if [ "$CLEANUP_DONE" -eq 1 ]; then
        return
    fi
    CLEANUP_DONE=1
    # ... (moved from core.sh)
}

trap 'cleanup $? EXIT INT TERM'

# === SLUGIFY ===
slugify() {
    local input="$1"
    echo "$input" | sed -E 's/[^a-zA-Z0-9]+/-/g' | tr '[:upper:]' '[:lower:]'
}

# === SOURCE MODULES ===
for lib in "$(dirname "${BASH_SOURCE[0]}")/lib/"*.sh; do
    source "$lib"
done

# === MAIN ===
main() {
    # ... (orchestrates all module functions)
}

main "$@"
```

## Error Handling Strategy

1. **Entry point**: `set -e` causes immediate exit on any command failure
2. **Cleanup trap**: `trap 'cleanup $? EXIT INT TERM'` ensures partial projects are removed on error
3. **Module-level**: Functions `log_error` write to stderr; callers use `exit 1` for failures
4. **Idempotency**: `cleanup` uses `CLEANUP_DONE` flag to prevent double execution
5. **Timeout handling**: `run_with_timeout` falls back through `timeout` → `gtimeout` → `perl` → direct execution

## Rollback Plan

### Git-based rollback (if refactor breaks):

```bash
# Option 1: Restore monolithic script
git checkout HEAD -- init-project.sh
rm -rf init-project/

# Option 2: Rollback to modular (keep structure, fix modules)
git checkout HEAD -- init-project/
```

### Pre-refactor backup (recommended before implementing):

```bash
git add init-project.sh
git commit -m "chore: backup monolithic before modular refactor"
git tag backup/monolithic-pre-refactor
```

## Sourcing Order Verification

After implementation, verify with:
```bash
bash -x init-project/init-project.sh -c 'type log; type check_dependencies; type select_project_name' 2>&1 | grep -c 'source'
```

Expected: 5 `source` invocations (one per module).

## Backward Compatibility Verification

```bash
# Test curl-based install still works
curl -fsSL "file://$(pwd)/init-project/init-project.sh" | bash -c 'type main'

# Verify all 44 functions exist
bash -c 'source init-project/init-project.sh; compgen -A function | wc -l'
# Expected: >= 44
```

## Open Questions

None — spec provides complete requirements. Implementation can proceed directly.