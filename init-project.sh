#!/usr/bin/env bash

# ============================================================================
# SAI Project Initializer - Entry Point
# Modular architecture: sources lib/*.sh modules
# ============================================================================

set -e

# Determine script directory (portable - works with bash, zsh, etc.)
# When sourced via curl|bash, BASH_SOURCE may not be reliable, so we detect our location
# by finding the directory containing this entry point script
if [ -n "${BASH_SOURCE[0]}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
    # Fallback: derive from the script path itself (works for curl|bash)
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
fi

# Resolve module directory - modules are in init-project/lib/ relative to this script
# For downloaded version (script at root): modules in ./init-project/lib/
# For development (script in project root): modules in ./init-project/lib/
SCRIPT_DIR="$(cd "$SCRIPT_DIR" && pwd)"
MODULE_DIR="$SCRIPT_DIR/init-project/lib"

# Source all modules in dependency order
# Each module provides a specific set of functions
if [ ! -d "$MODULE_DIR" ]; then
    echo "Error: Module directory not found: $MODULE_DIR" >&2
    exit 1
fi

for lib in "$MODULE_DIR"/*.sh; do
    if [ -f "$lib" ]; then
        source "$lib"
    fi
done

# ============================================================================
# Main Entry Point
# ============================================================================

main() {
    print_banner
    check_dependencies
    select_project_name
    select_package_manager
    select_project_type

    # Si es backend o monorepo, pedir tipo de backend
    if [ "$PROJECT_TYPE" = "backend" ] || [ "$PROJECT_TYPE" = "monorepo" ]; then
        select_backend_type
    fi

    # Si es frontend o monorepo, pedir arquitectura
    if [ "$PROJECT_TYPE" = "frontend-next" ] || [ "$PROJECT_TYPE" = "frontend-vite" ] || [ "$PROJECT_TYPE" = "monorepo" ]; then
        select_architecture
    fi

    select_agent
    select_graphify
    check_docker
    select_docker_db
    confirm_setup

    echo ""
    log_info "Creando proyecto con las opciones seleccionadas..."
    echo ""

    # Dispatcher según tipo de proyecto
    case "$PROJECT_TYPE" in
        frontend-next)
            create_frontend_next
            ;;
        frontend-vite)
            create_frontend_vite
            ;;
        backend)
            if [ "$BACKEND_TYPE" = "nestjs" ]; then
                create_backend_nestjs
            else
                create_backend_golang
            fi
            ;;
        monorepo)
            create_monorepo
            ;;
    esac

    setup_github_actions
    setup_env_template
    setup_vscode
    setup_agents_md
    setup_agent_rules
    setup_skills

    # Solo para frontend y monorepo
    if [ "$PROJECT_TYPE" = "frontend-next" ] || [ "$PROJECT_TYPE" = "frontend-vite" ] || [ "$PROJECT_TYPE" = "monorepo" ]; then
        setup_scripts
        setup_vitest
    fi

    enrich_gitignore
    setup_git_initial
    setup_versioning
    setup_git_workflow
    setup_husky
    setup_graphify
    setup_gga
    setup_docker_db

    # Auto-iniciar contenedores Docker si se eligió Docker DB
    if [ "$DOCKER_DB_TYPE" != "none" ]; then
        echo ""
        log "${CYAN}▸${NC} Verificando contenedores Docker..."

        # Verificar que Docker esté corriendo
        if docker info &>/dev/null; then
            log_info "Iniciando contenedores Docker..."
            if cd "$PROJECT_NAME" && docker compose up -d 2>/dev/null; then
                echo ""
                log_success "Contenedores Docker iniciados"
                echo ""
                log "${CYAN}Connection strings:${NC}"
                if [ "$DOCKER_DB_TYPE" = "postgres" ] || [ "$DOCKER_DB_TYPE" = "both" ]; then
                    echo "  ${GREEN}PostgreSQL:${NC}  postgresql://saiuser:saipass@localhost:5432/saidb"
                fi
                if [ "$DOCKER_DB_TYPE" = "mongodb" ] || [ "$DOCKER_DB_TYPE" = "both" ]; then
                    echo "  ${CYAN}MongoDB:${NC}     mongodb://saiuser:saipass@localhost:27017/sai"
                fi
                echo ""
            else
                log_warn "No se pudieron iniciar los contenedores Docker."
                echo "  Ejecutá ${CYAN}cd $PROJECT_NAME && docker compose up -d${NC} para iniciarlos después."
                echo ""
            fi
            cd "$ORIGINAL_DIR"
        else
            log_warn "Docker no está corriendo. Los contenedores no se iniciaron."
            echo "  Ejecutá ${CYAN}cd $PROJECT_NAME && docker compose up -d${NC} cuando Docker esté disponible."
            echo ""
        fi
    fi

    echo ""
    log_success "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_success "  PROYECTO DESPLEGADO: $PROJECT_NAME"
    log_success "  Tipo: $PROJECT_TYPE"
    if [ "$PROJECT_TYPE" = "backend" ] || [ "$PROJECT_TYPE" = "monorepo" ]; then
        log_success "  Backend: $BACKEND_TYPE"
    fi
    if [ "$PROJECT_TYPE" = "frontend-next" ] || [ "$PROJECT_TYPE" = "frontend-vite" ] || [ "$PROJECT_TYPE" = "monorepo" ]; then
        log_success "  Arquitectura: $ARCHITECTURE"
    fi
    if [ "$DOCKER_DB_TYPE" != "none" ]; then
        log_success "  Docker DB: $DOCKER_DB_TYPE (iniciado)"
    fi
    log_success "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    log_info "Próximos pasos:"
    echo "  cd $PROJECT_NAME"

    case "$SELECTED_PKG_MANAGER" in
        bun)   echo "  bun install" ;;
        pnpm)  echo "  pnpm install" ;;
        npm)   echo "  npm install" ;;
    esac

    echo "  git checkout develop"

    case "$SELECTED_PKG_MANAGER" in
        bun)   echo "  bun dev" ;;
        pnpm)  echo "  pnpm dev" ;;
        npm)   echo "  npm run dev" ;;
    esac

    echo ""
    echo "  ${DIM}Para crear un commit automático:${NC}"
    echo "  ${CYAN}git c \"tu mensaje del commit\"${NC}"
    echo ""

    # Desregistrar trap - todo salió bien
    trap - EXIT INT TERM
}

# Execute main function with all passed arguments
main "$@"
