# Proposal: Modularize init-project.sh

## Intent

Refactor `init-project.sh` (2836 lines, 44 functions) into a modular structure to improve maintainability, enable per-module testing, and facilitate extensibility without modifying core logic.

## Scope

### In Scope
- Create `init-project/lib/` directory structure
- Extract functions into 5 logical modules by category
- Ensure `init-project.sh` sources all modules at startup
- Maintain 100% backward compatibility for `curl -fsSL URL | bash`
- Preserve all 44 function signatures and outputs

### Out of Scope
- Behavior changes or new features
- Shellcheck compliance improvements
- Testing infrastructure setup

## Approach

### Target Structure
```
init-project/
├── init-project.sh          # Entry point (~150 lines) - sources modules, calls main()
└── lib/
    ├── core.sh              # Constants, colors, log functions, banner, cleanup, timeout
    ├── validators.sh        # check_dependencies, check_docker, detect_type, confirm_setup
    ├── selectors.sh         # All select_*() interactive functions (8 functions)
    ├── builders.sh          # All create_*() functions (5 functions)
    └── setup.sh             # All setup_*() functions (16 functions)
```

### Function Mapping

| Module | Functions |
|--------|-----------|
| `core.sh` | log, log_info, log_success, log_warn, log_error, print_banner, cleanup, run_with_timeout |
| `validators.sh` | check_dependencies, check_docker, detect_type, confirm_setup |
| `selectors.sh` | select_project_name, select_package_manager, select_project_type, select_backend_type, select_architecture, select_agent, select_graphify, select_docker_db |
| `builders.sh` | create_frontend_next, create_frontend_vite, create_backend_nestjs, create_backend_golang, create_monorepo |
| `setup.sh` | setup_github_actions, setup_env_template, setup_vscode, setup_agents_md, setup_agent_rules, setup_skills, setup_husky, setup_scripts, setup_vitest, setup_versioning, enrich_gitignore, setup_git_workflow, setup_git_initial, setup_graphify, setup_gga, setup_docker_db |

### Entry Point Responsibilities
`init-project.sh` will contain:
- Global variable declarations (SELECTED_PKG_MANAGER, PROJECT_TYPE, etc.)
- `slugify()` utility function
- `config()` function
- `main()` orchestration function
- `source lib/*.sh` loop at top
- `set -e` and trap setup

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `init-project.sh` | Modified | Shrinks from 2836 to ~150 lines |
| `init-project/lib/core.sh` | New | Constants, logging, cleanup, banner |
| `init-project/lib/validators.sh` | New | Dependency and docker checks |
| `init-project/lib/selectors.sh` | New | All interactive selectors |
| `init-project/lib/builders.sh` | New | All project creators |
| `init-project/lib/setup.sh` | New | All setup functions |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Path issues when sourced | Low | Use `$(dirname "${BASH_SOURCE[0]}")` for relative paths |
| Global variable scope breakage | Low | Declare globals in entry point, use `export` where needed |
| `curl -fsSL` backward compatibility | Low | Keep entry point as single file, verify with `bash -n` |

## Rollback Plan

1. Delete `init-project/lib/` directory
2. Restore original `init-project.sh` from git history
3. Single `git checkout` revert

## Dependencies

- None (pure bash refactor)

## Success Criteria

- [ ] `bash -n init-project.sh` passes
- [ ] `bash -n init-project/lib/*.sh` all pass
- [ ] `curl -fsSL local-path/init-project.sh | bash` works
- [ ] All 44 original functions exist with identical signatures
- [ ] No behavior changes in any function
