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
        log_warn "Docker no está instalado."
        log "${YELLOW}▸${NC} Instalá Docker Desktop desde: https://www.docker.com/products/docker-desktop"
        log "${DIM}  La opción de Docker DB no estará disponible hasta que instales Docker.${NC}"
        echo ""
        DOCKER_AVAILABLE=0
        return
    fi
    
    # Verificar que Docker daemon esté corriendo (docker info falla si no)
    if ! docker info &>/dev/null; then
        log_warn "Docker daemon no está corriendo."
        echo ""
        log "${CYAN}▸${NC} Intentando iniciar Docker Desktop..."
        
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # En macOS, intentar abrir Docker Desktop
            open -a Docker 2>/dev/null || true
            
            # Esperar hasta 30 segundos a que Docker esté listo
            log "${DIM}  Esperando a que Docker esté listo (máx 30s)...${NC}"
            local wait_time=0
            while [ $wait_time -lt 30 ]; do
                if docker info &>/dev/null; then
                    break
                fi
                sleep 2
                wait_time=$((wait_time + 2))
                echo -n "."
            done
            echo ""
            
            # Verificar si Docker está disponible después de esperar
            if docker info &>/dev/null; then
                DOCKER_AVAILABLE=1
                log_success "Docker iniciado y disponible"
                return
            fi
        fi
        
        log_warn "No se pudo iniciar Docker."
        log "${DIM}  Iniciá Docker Desktop manualmente y esperar a que esté listo.${NC}"
        log "${DIM}  La opción de Docker DB estará disponible cuando Docker esté corriendo.${NC}"
        echo ""
        DOCKER_AVAILABLE=0
        return
    fi
    
    DOCKER_AVAILABLE=1
    log_success "Docker disponible"
}