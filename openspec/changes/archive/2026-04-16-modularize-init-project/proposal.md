# Propuesta: Modularizar init-project.sh

## Intención

Refactorizar `init-project.sh` (2836 líneas, 44 funciones) a una estructura modular para mejorar mantenibilidad, habilitar testing por módulo, y facilitar extensibilidad sin modificar lógica core.

## Alcance

### Incluido
- Crear estructura de directorio `init-project/lib/`
- Extraer funciones a 5 módulos lógicos por categoría
- Asegurar que `init-project.sh` haga source de todos los módulos al inicio
- Mantener 100% compatibilidad hacia atrás para `curl -fsSL URL | bash`
- Preservar las 44 firmas de funciones y outputs

### Excluido
- Cambios de comportamiento o nuevas features
- Mejoras de compliance con Shellcheck
- Setup de infraestructura de testing

## Enfoque

### Estructura Objetivo
```
init-project/
├── init-project.sh          # Punto de entrada (~150 líneas) - source módulos, llama main()
└── lib/
    ├── core.sh              # Constantes, colores, funciones log, banner, cleanup, timeout
    ├── validators.sh        # check_dependencies, check_docker, detect_type, confirm_setup
    ├── selectors.sh         # Todas las funciones interactivas select_*() (8 funciones)
    ├── builders.sh          # Todas las funciones create_*() (5 funciones)
    └── setup.sh             # Todas las funciones setup_*() (16 funciones)
```

### Mapeo de Funciones

| Módulo | Funciones |
|--------|-----------|
| `core.sh` | log, log_info, log_success, log_warn, log_error, print_banner, cleanup, run_with_timeout |
| `validators.sh` | check_dependencies, check_docker, detect_type, confirm_setup |
| `selectors.sh` | select_project_name, select_package_manager, select_project_type, select_backend_type, select_architecture, select_agent, select_graphify, select_docker_db |
| `builders.sh` | create_frontend_next, create_frontend_vite, create_backend_nestjs, create_backend_golang, create_monorepo |
| `setup.sh` | setup_github_actions, setup_env_template, setup_vscode, setup_agents_md, setup_agent_rules, setup_skills, setup_husky, setup_scripts, setup_vitest, setup_versioning, enrich_gitignore, setup_git_workflow, setup_git_initial, setup_graphify, setup_gga, setup_docker_db |

### Responsabilidades del Punto de Entrada
`init-project.sh` contendrá:
- Declaraciones de variables globales (SELECTED_PKG_MANAGER, PROJECT_TYPE, etc.)
- Función utilitaria `slugify()`
- Función `config()`
- Función de orquestación `main()`
- Loop `source lib/*.sh` al inicio
- `set -e` y setup de trap

## Áreas Afectadas

| Área | Impacto | Descripción |
|------|---------|-------------|
| `init-project.sh` | Modificado | Reduce de 2836 a ~150 líneas |
| `init-project/lib/core.sh` | Nuevo | Constantes, logging, cleanup, banner |
| `init-project/lib/validators.sh` | Nuevo | Verificación de dependencias y docker |
| `init-project/lib/selectors.sh` | Nuevo | Todos los selectores interactivos |
| `init-project/lib/builders.sh` | Nuevo | Todos los creators de proyectos |
| `init-project/lib/setup.sh` | Nuevo | Todas las funciones de setup |

## Riesgos

| Riesgo | Probabilidad | Mitigación |
|--------|-------------|------------|
| Problemas de path cuando se hace source | Baja | Usar `$(dirname "${BASH_SOURCE[0]}")` para paths relativos |
| Rotura de scope de variables globales | Baja | Declarar globals en entry point, usar `export` donde sea necesario |
| Compatibilidad hacia atrás `curl -fsSL` | Baja | Mantener entry point como archivo único, verificar con `bash -n` |

## Plan de Rollback

1. Eliminar directorio `init-project/lib/`
2. Restaurar `init-project.sh` original desde git history
3. Revert simple con `git checkout`

## Dependencias

- Ninguna (refactorización pura en bash)

## Criterios de Éxito

- [ ] `bash -n init-project.sh` pasa
- [ ] `bash -n init-project/lib/*.sh` todos pasan
- [ ] `curl -fsSL local-path/init-project.sh | bash` funciona
- [ ] Las 44 funciones originales existen con firmas idénticas
- [ ] Sin cambios de comportamiento en ninguna función
