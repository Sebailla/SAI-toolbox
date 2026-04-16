# Tasks: Modularize init-project.sh

## Phase 1: Infrastructure

- [ ] 1.1 Create directory structure: `mkdir -p init-project/lib`
- [ ] 1.2 Backup original monolithic script: `git add init-project.sh && git commit -m "chore: backup monolithic init-project.sh before modular refactor"`

## Phase 2: Module Extraction (Dependency Order)

- [ ] 2.1 Create `init-project/lib/core.sh` — extract color constants, `log`/`log_info`/`log_success`/`log_warn`/`log_error`, `print_banner`, `run_with_timeout` (~100 lines, 8 functions)
- [ ] 2.2 Create `init-project/lib/validators.sh` — extract `check_dependencies`, `check_docker` (~80 lines, 2 functions; depends on core.sh)
- [ ] 2.3 Create `init-project/lib/selectors.sh` — extract all `select_*` functions and `confirm_setup` (~350 lines, 9 functions; depends on core.sh, validators.sh)
- [ ] 2.4 Create `init-project/lib/builders.sh` — extract all `create_*` functions (~600 lines, 5 functions; depends on core.sh, validators.sh)
- [ ] 2.5 Create `init-project/lib/setup.sh` — extract all `setup_*` and `enrich_gitignore` functions (~750 lines, 16 functions; depends on core.sh)

## Phase 3: Entry Point Creation

- [ ] 3.1 Create `init-project/init-project.sh` (~150 lines): declare global variables, `slugify()` function, source loop `for lib in "$(dirname "${BASH_SOURCE[0]}")/lib/"*.sh`, `cleanup()` with idempotency, `trap 'cleanup $? EXIT INT TERM'`, `main()` orchestration, `main "$@"`
- [ ] 3.2 Delete original monolithic `init-project.sh` (now replaced by directory)

## Phase 4: Verification

- [ ] 4.1 Syntax check entry point: `bash -n init-project/init-project.sh` → exit 0
- [ ] 4.2 Syntax check all modules: `bash -n init-project/lib/*.sh` → all exit 0
- [ ] 4.3 Verify 44 functions available: `bash -c 'source init-project/init-project.sh; compgen -A function | wc -l'` → >= 44
- [ ] 4.4 Verify sourcing order (5 source calls): `bash -x init-project/init-project.sh -c 'type log; type check_dependencies; type select_project_name' 2>&1 | grep -c 'source'` → 5
- [ ] 4.5 Verify global variables in entry point: `grep -E '^(RED|GREEN|SELECTED_PKG_MANAGER|PROJECT_TYPE)' init-project/init-project.sh`
- [ ] 4.6 Verify cleanup trap: `grep "trap 'cleanup" init-project/init-project.sh`
- [ ] 4.7 Verify modules in correct directory: `ls init-project/lib/` → 5 .sh files
- [ ] 4.8 Test curl compatibility: `curl -fsSL "file://$(pwd)/init-project/init-project.sh" | bash -c 'type main'`

## Commit Strategy (One Module Per Commit)

| Task | File | Commit Message |
|------|------|----------------|
| 1.2 | - | `chore: backup monolithic init-project.sh before modular refactor` |
| 2.1 | lib/core.sh | `feat(init-project): extract core module (logging, colors, timeout)` |
| 2.2 | lib/validators.sh | `feat(init-project): extract validators module (deps, docker checks)` |
| 2.3 | lib/selectors.sh | `feat(init-project): extract selectors module (interactive prompts)` |
| 2.4 | lib/builders.sh | `feat(init-project): extract builders module (project scaffolding)` |
| 2.5 | lib/setup.sh | `feat(init-project): extract setup module (post-scaffold config)` |
| 3.1 | init-project.sh | `feat(init-project): create modular entry point (~150 lines)` |
| 3.2 | init-project.sh | `chore(init-project): remove monolithic script (replaced by modular)` |

## Dependencies

```
core.sh (no deps)
validators.sh → core.sh
selectors.sh → core.sh + validators.sh
builders.sh → core.sh + validators.sh
setup.sh → core.sh
init-project.sh → all modules
```

Implementation must proceed in order: 1 → 2.1 → 2.2 → 2.3 → 2.4 → 2.5 → 3.1 → 3.2 → 4.*
