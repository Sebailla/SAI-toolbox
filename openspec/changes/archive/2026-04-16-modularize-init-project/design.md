# Diseño: Modularizar init-project.sh

## Enfoque Técnico

Transformar el script monolítico de 2836 líneas `init-project.sh` en una estructura de directorio modular bajo `init-project/` con clara separación de responsabilidades. El punto de entrada (`init-project.sh`) hará source de módulos via un loop glob, declarará globals, y delegará todas las definiciones de funciones a archivos de módulo. Esto habilita testing por módulo y mejor mantenibilidad mientras preserva 100% compatibilidad hacia atrás.

## Decisiones de Arquitectura

### Decisión: Mecanismo de Sourcing — Loop vs Explícito

**Elección**: Usar `for lib in "$(dirname "${BASH_SOURCE[0]}")/lib/*.sh"; do source "$lib"; done`

**Alternativas consideradas**:
- `source lib/core.sh; source lib/validators.sh; ...` — orden explícito pero requiere mantenimiento manual
- `find` dinámico con sorting — más complejo, menos portable

**Justificación**: El spec mandates esta sintaxis exacta. El enfoque de loop es conciso y automáticamente picking up nuevos módulos, mientras que la restricción de orden exacto del spec asegura que las dependencias se resuelvan correctamente sin importar el orden alfabético.

### Decisión: Estrategia de Scope de Variables

**Elección**:
- **Global (declaradas en entry point)**: Constantes de color, variables de estado (`SELECTED_PKG_MANAGER`, `PROJECT_TYPE`, `BACKEND_TYPE`, `ARCHITECTURE`, `DOCKER_DB_TYPE`, `DOCKER_AVAILABLE`, `ORIGINAL_DIR`, `PROJECT_CREATED`, `CLEANUP_DONE`)
- **Global (setadas por módulos)**: Todas las funciones `select_*` y `check_*` setean sus variables respectivas directamente en scope global
- **Local (dentro de funciones)**: Variables de loop, strings temporales, outputs de comandos usan `local`

**Alternativas consideradas**:
- Pasar todos los valores via return/exit codes — limitación de bash hace esto engorroso
- Exportar a environment — riesgo de contaminación

**Justificación**: Bash no soporta pasar por referencia o closures. Variables globales son el patrón estándar en scripts bash. Módulos setean globals específicos del módulo; entry point posee estado compartido.

### Decisión: Propagación de Errores

**Elección**: `set -e` en entry point con trap `cleanup $? EXIT INT TERM`

**Alternativas consideradas**:
- Manejo de errores por módulo — inconsistente, verboso
- Sin `set -e` — fallas silenciosas se vuelven bugs

**Justificación**: Spec mandates este patrón exacto. `set -e` causa que cualquier falla de comando salga inmediatamente. El trap catches EXIT (normal o error), INT (Ctrl+C), TERM (kill). `cleanup` usa flag `CLEANUP_DONE` para idempotencia.

## Estructura de Archivos

```
init-project/
├── init-project.sh     (~150 líneas, punto de entrada)
└── lib/
    ├── core.sh         (~100 líneas, 8 funciones)
    ├── validators.sh   (~80 líneas, 2 funciones)
    ├── selectors.sh    (~350 líneas, 9 funciones)
    ├── builders.sh     (~600 líneas, 5 funciones)
    └── setup.sh       (~750 líneas, 16 funciones)
```

## Dependencias de Módulos

```
init-project.sh (punto de entrada)
  └─ hace source lib/*.sh en orden: core → validators → selectors → builders → setup

core.sh (sin deps)
  └─ log, log_info, log_success, log_warn, log_error, print_banner, cleanup, run_with_timeout

validators.sh (depende de core)
  └─ check_dependencies, check_docker

selectors.sh (depende de core, validators)
  └─ select_project_name, select_package_manager, select_project_type, select_backend_type, 
     select_architecture, select_agent, select_graphify, select_docker_db, confirm_setup

builders.sh (depende de core, validators)
  └─ create_frontend_next, create_frontend_vite, create_backend_nestjs, 
     create_backend_golang, create_monorepo

setup.sh (depende de core)
  └─ setup_github_actions, setup_env_template, setup_vscode, setup_agents_md,
     setup_agent_rules, setup_skills, setup_husky, setup_scripts, setup_vitest,
     enrich_gitignore, setup_git_workflow, setup_git_initial, setup_graphify,
     setup_gga, setup_docker_db
```

## Enfoque de Implementación

### Paso 1: Crear estructura de directorio

```bash
mkdir -p init-project/lib
```

### Paso 2: Crear core.sh (líneas 10-98, 509-545 del original)

Extraer: constantes de color, funciones familia `log`, `print_banner`, `run_with_timeout`. Core no tiene dependencias.

### Paso 3: Crear validators.sh (líneas 434-503 del original)

Extraer: `check_dependencies`, `check_docker`. Depende de core.sh para logging.

### Paso 4: Crear selectors.sh (líneas 101-428 del original)

Extraer: todas las funciones `select_*` y `confirm_setup`. Depende de validators para `check_docker` llamado en `select_docker_db`.

### Paso 5: Crear builders.sh (líneas 551-1121 del original)

Extraer: todas las funciones `create_*`. Depende de core para logging y `run_with_timeout`, validators para `check_dependencies` (llamado dentro de builders via `set -e` en dependency check).

### Paso 6: Crear setup.sh (líneas 1127-2360 del original)

Extraer: todas las funciones `setup_*` y `enrich_gitignore`. Solo depende de core.

### Paso 7: Crear punto de entrada (~150 líneas)

```bash
#!/usr/bin/env bash

set -e

# === COLORES ===
RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[0;33m'
CYAN=$'\033[0;36m'
MAGENTA=$'\033[0;35m'
WHITE=$'\033[0;37m'
BOLD=$'\033[1m'
DIM=$'\033[2m'
NC=$'\033[0m'

# === VARIABLES DE ESTADO ===
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

# === TRAP DE CLEANUP ===
cleanup() {
    local exit_code=${1:-0}
    if [ "$CLEANUP_DONE" -eq 1 ]; then
        return
    fi
    CLEANUP_DONE=1
    # ... (movido de core.sh)
}

trap 'cleanup $? EXIT INT TERM'

# === SLUGIFY ===
slugify() {
    local input="$1"
    echo "$input" | sed -E 's/[^a-zA-Z0-9]+/-/g' | tr '[:upper:]' '[:lower:]'
}

# === SOURCE DE MÓDULOS ===
for lib in "$(dirname "${BASH_SOURCE[0]}")/lib/"*.sh; do
    source "$lib"
done

# === MAIN ===
main() {
    # ... (orquesta todas las funciones de módulos)
}

main "$@"
```

## Estrategia de Manejo de Errores

1. **Entry point**: `set -e` causa salida inmediata en cualquier falla de comando
2. **Cleanup trap**: `trap 'cleanup $? EXIT INT TERM'` asegura que proyectos parciales sean removidos en error
3. **Nivel módulo**: Funciones `log_error` escriben a stderr; llamadores usan `exit 1` para fallas
4. **Idempotencia**: `cleanup` usa flag `CLEANUP_DONE` para prevenir doble ejecución
5. **Manejo de timeout**: `run_with_timeout` cae a través de `timeout` → `gtimeout` → `perl` → ejecución directa

## Plan de Rollback

### Rollback basado en Git (si refactor rompe):

```bash
# Opción 1: Restaurar script monolítico
git checkout HEAD -- init-project.sh
rm -rf init-project/

# Opción 2: Rollback a modular (mantener estructura, fix módulos)
git checkout HEAD -- init-project/
```

### Backup pre-refactor (recomendado antes de implementar):

```bash
git add init-project.sh
git commit -m "chore: backup monolithic before modular refactor"
git tag backup/monolithic-pre-refactor
```

## Verificación de Orden de Sourcing

Después de implementar, verificar con:
```bash
bash -x init-project/init-project.sh -c 'type log; type check_dependencies; type select_project_name' 2>&1 | grep -c 'source'
```

Esperado: 5 invocaciones de `source` (una por módulo).

## Verificación de Compatibilidad hacia Atrás

```bash
# Test instalación via curl todavía funciona
curl -fsSL "file://$(pwd)/init-project/init-project.sh" | bash -c 'type main'

# Verificar que las 44 funciones existen
bash -c 'source init-project/init-project.sh; compgen -A function | wc -l'
# Esperado: >= 44
```

## Preguntas Abiertas

Ninguna — el spec proporciona requisitos completos. La implementación puede proceder directamente.
