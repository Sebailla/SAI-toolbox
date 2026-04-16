#!/usr/bin/env bash

# ============================================================================
# Validators - Dependency and Docker checks
# ============================================================================

# Docker Available flag
DOCKER_AVAILABLE=0

# ============================================================================
# Check Dependencies
# ============================================================================

check_dependencies() {
    local missing=()
    
    case "$SELECTED_PKG_MANAGER" in
        bun)
            for cmd in bun git npm; do
                if ! command -v "$cmd" &>/dev/null; then
                    missing+=("$cmd")
                fi
            done
            ;;
        pnpm)
            for cmd in pnpm git npm; do
                if ! command -v "$cmd" &>/dev/null; then
                    missing+=("$cmd")
                fi
            done
            ;;
        npm)
            for cmd in npm git; do
                if ! command -v "$cmd" &>/dev/null; then
                    missing+=("$cmd")
                fi
            done
            ;;
        *)
            for cmd in bun git npm; do
                if ! command -v "$cmd" &>/dev/null; then
                    missing+=("$cmd")
                fi
            done
            ;;
    esac

    if [ "$BACKEND_TYPE" = "golang" ]; then
        if ! command -v go &>/dev/null; then
            missing+=("go")
        fi
    fi
    
    if [ ${#missing[@]} -gt 0 ]; then
        log_error "Faltan dependencias: ${missing[*]}"
        log_error "Instalalas antes de continuar."
        exit 1
    fi
}

# ============================================================================
# Check Docker
# ============================================================================

check_docker() {
    log_info "Verificando Docker..."
    
    if ! command -v docker &>/dev/null; then
        log_warn "Docker no está instalado. La opción de Docker DB no estará disponible."
        DOCKER_AVAILABLE=0
        return
    fi
    
    # Verificar que Docker daemon esté corriendo (docker info falla si no)
    if ! docker info &>/dev/null; then
        log_warn "Docker daemon no está corriendo. iniciá Docker Desktop."
        DOCKER_AVAILABLE=0
        return
    fi
    
    DOCKER_AVAILABLE=1
    log_success "Docker disponible"
}