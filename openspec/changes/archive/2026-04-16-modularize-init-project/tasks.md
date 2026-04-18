# Tareas: Modularizar init-project.sh

## Fase 1: Infraestructura

- [ ] 1.1 Crear estructura de directorio: `mkdir -p init-project/lib`
- [ ] 1.2 Backup del script monolítico original: `git add init-project.sh && git commit -m "chore: backup monolithic init-project.sh before modular refactor"`

## Fase 2: Extracción de Módulos (Orden de Dependencias)

- [ ] 2.1 Crear `init-project/lib/core.sh` — extraer constantes de color, `log`/`log_info`/`log_success`/`log_warn`/`log_error`, `print_banner`, `run_with_timeout` (~100 líneas, 8 funciones)
- [ ] 2.2 Crear `init-project/lib/validators.sh` — extraer `check_dependencies`, `check_docker` (~80 líneas, 2 funciones; depende de core.sh)
- [ ] 2.3 Crear `init-project/lib/selectors.sh` — extraer todas las funciones `select_*` y `confirm_setup` (~350 líneas, 9 funciones; depende de core.sh, validators.sh)
- [ ] 2.4 Crear `init-project/lib/builders.sh` — extraer todas las funciones `create_*` (~600 líneas, 5 funciones; depende de core.sh, validators.sh)
- [ ] 2.5 Crear `init-project/lib/setup.sh` — extraer todas las funciones `setup_*` y `enrich_gitignore` (~750 líneas, 16 funciones; depende de core.sh)

## Fase 3: Creación del Punto de Entrada

- [ ] 3.1 Crear `init-project/init-project.sh` (~150 líneas): declarar variables globales, función `slugify()`, loop de sourcing `for lib in "$(dirname "${BASH_SOURCE[0]}")/lib/"*.sh`, `cleanup()` con idempotencia, `trap 'cleanup $? EXIT INT TERM'`, orquestación `main()`, `main "$@"`
- [ ] 3.2 Eliminar script monolítico original `init-project.sh` (ahora reemplazado por directorio)

## Fase 4: Verificación

- [ ] 4.1 Check de sintaxis punto de entrada: `bash -n init-project/init-project.sh` → exit 0
- [ ] 4.2 Check de sintaxis todos los módulos: `bash -n init-project/lib/*.sh` → todos exit 0
- [ ] 4.3 Verificar 44 funciones disponibles: `bash -c 'source init-project/init-project.sh; compgen -A function | wc -l'` → >= 44
- [ ] 4.4 Verificar orden de sourcing (5 source calls): `bash -x init-project/init-project.sh -c 'type log; type check_dependencies; type select_project_name' 2>&1 | grep -c 'source'` → 5
- [ ] 4.5 Verificar variables globales en punto de entrada: `grep -E '^(RED|GREEN|SELECTED_PKG_MANAGER|PROJECT_TYPE)' init-project/init-project.sh`
- [ ] 4.6 Verificar cleanup trap: `grep "trap 'cleanup" init-project/init-project.sh`
- [ ] 4.7 Verificar módulos en directorio correcto: `ls init-project/lib/` → 5 archivos .sh
- [ ] 4.8 Test compatibilidad curl: `curl -fsSL "file://$(pwd)/init-project/init-project.sh" | bash -c 'type main'`

## Estrategia de Commits (Un Módulo Por Commit)

| Tarea | Archivo | Mensaje de Commit |
|--------|---------|------------------|
| 1.2 | - | `chore: backup monolithic init-project.sh before modular refactor` |
| 2.1 | lib/core.sh | `feat(init-project): extract core module (logging, colors, timeout)` |
| 2.2 | lib/validators.sh | `feat(init-project): extract validators module (deps, docker checks)` |
| 2.3 | lib/selectors.sh | `feat(init-project): extract selectors module (interactive prompts)` |
| 2.4 | lib/builders.sh | `feat(init-project): extract builders module (project scaffolding)` |
| 2.5 | lib/setup.sh | `feat(init-project): extract setup module (post-scaffold config)` |
| 3.1 | init-project.sh | `feat(init-project): create modular entry point (~150 lines)` |
| 3.2 | init-project.sh | `chore(init-project): remove monolithic script (replaced by modular)` |

## Dependencias

```
core.sh (sin deps)
validators.sh → core.sh
selectors.sh → core.sh + validators.sh
builders.sh → core.sh + validators.sh
setup.sh → core.sh
init-project.sh → todos los módulos
```

La implementación debe proceder en orden: 1 → 2.1 → 2.2 → 2.3 → 2.4 → 2.5 → 3.1 → 3.2 → 4.*
