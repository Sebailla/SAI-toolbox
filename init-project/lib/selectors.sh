#!/usr/bin/env bash

# ============================================================================
# Selectors - Interactive selection functions
# ============================================================================

# Global state variables
SELECTED_PKG_MANAGER=""
PROJECT_TYPE=""
BACKEND_TYPE=""
ARCHITECTURE=""
TARGET_AGENT=""
USE_GRAPHIFY=""
DOCKER_DB_TYPE="none"

# ============================================================================
# Select Project Name
# ============================================================================

select_project_name() {
    while true; do
        echo ""
        log "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        log "${BOLD}${CYAN}  ▸ Paso 1 de 9 ─── Nombre del proyecto${NC}"
        log "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        log "${DIM}Ingresá el nombre para tu proyecto (sin espacios)${NC}"
        echo ""
        read -r -t 120 -p "   └─►  " PROJECT_NAME
        echo ""

        # Si read timeout, treat as cancel
        if [ -z "$PROJECT_NAME" ]; then
            log_error "El nombre no puede estar vacío"
            continue
        fi

        # Sanitizar nombre: debe empezar con letra minúscula, solo letras minúsculas, números, guiones y guiones bajos
        if [[ ! "$PROJECT_NAME" =~ ^[a-z][a-z0-9_-]*$ ]]; then
            log_error "Debe empezar con letra minúscula, solo letras minúsculas, números, guiones (-) y guiones bajos (_)"
            continue
        fi

        # Convertir a minúsculas por seguridad (npm naming restrictions) - POSIX way
        PROJECT_NAME=$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]')

        # Verificar que no exista el directorio
        if [ -d "$PROJECT_NAME" ]; then
            log_error "El directorio '$PROJECT_NAME' ya existe. Elegí otro nombre."
            continue
        fi

        break
    done

    log "${GREEN}  ✓${NC} Proyecto: ${BOLD}$PROJECT_NAME${NC}"
}

# ============================================================================
# Select Package Manager
# ============================================================================

select_package_manager() {
    echo ""
    log "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    log "${BOLD}${CYAN}  ▸ Paso 2 de 9 ─── Gestor de paquetes${NC}"
    log "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    log "${DIM}Elegí el gestor de paquetes para tu proyecto${NC}"
    echo ""
    log "${WHITE}  ▸${NC}  ${BOLD}1${NC}) ${GREEN}bun${NC} (recomendado - más rápido)"
    log "${DIM}        Gestor nativo de JavaScript/TypeScript${NC}"
    echo ""
    log "${WHITE}  ▸${NC}  ${BOLD}2${NC}) ${CYAN}pnpm${NC}"
    log "${DIM}        Gestor de paquetes eficiente con symlinks${NC}"
    echo ""
    log "${WHITE}  ▸${NC}  ${BOLD}3${NC}) ${MAGENTA}npm${NC}"
    log "${DIM}        Gestor de paquetes oficial de Node.js${NC}"
    echo ""
    read -r -t 120 -p "   └─►  " PKG_CHOICE
    echo ""

    case "$PKG_CHOICE" in
        1) SELECTED_PKG_MANAGER="bun" ;;
        2) SELECTED_PKG_MANAGER="pnpm" ;;
        3) SELECTED_PKG_MANAGER="npm" ;;
        *) log_warn "Opción inválida. Usando bun."; SELECTED_PKG_MANAGER="bun" ;;
    esac
    log "${GREEN}  ✓${NC} Gestor: ${BOLD}$SELECTED_PKG_MANAGER${NC}"
}

# ============================================================================
# Select Project Type
# ============================================================================

select_project_type() {
    echo ""
    log "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    log "${BOLD}${CYAN}  ▸ Paso 3 de 9 ─── Tipo de proyecto${NC}"
    log "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    log "${DIM}Elegí el tipo de proyecto a crear${NC}"
    echo ""
    log "${WHITE}  ▸${NC}  ${BOLD}1${NC}) ${GREEN}Frontend - Next.js${NC}"
    log "${DIM}        Next.js + Tailwind + Prisma + App Router${NC}"
    echo ""
    log "${WHITE}  ▸${NC}  ${BOLD}2${NC}) ${CYAN}Frontend - React + Vite${NC}"
    log "${DIM}        Vite + React + TypeScript + Tailwind${NC}"
    echo ""
    log "${WHITE}  ▸${NC}  ${BOLD}3${NC}) ${MAGENTA}Backend${NC}"
    log "${DIM}        API standalone (NestJS o Gin/Go)${NC}"
    echo ""
    log "${WHITE}  ▸${NC}  ${BOLD}4${NC}) ${YELLOW}Monorepo Fullstack${NC}"
    log "${DIM}        Next.js + API backend en workspace${NC}"
    echo ""
    read -r -t 120 -p "   └─►  " TYPE_CHOICE
    echo ""

    case "$TYPE_CHOICE" in
        1) PROJECT_TYPE="frontend-next" ;;
        2) PROJECT_TYPE="frontend-vite" ;;
        3) PROJECT_TYPE="backend" ;;
        4) PROJECT_TYPE="monorepo" ;;
        *) log_warn "Opción inválida. Usando Frontend Next.js."; PROJECT_TYPE="frontend-next" ;;
    esac
    log "${GREEN}  ✓${NC} Tipo: ${BOLD}$PROJECT_TYPE${NC}"
}

# ============================================================================
# Select Backend Type
# ============================================================================

select_backend_type() {
    echo ""
    log "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    log "${BOLD}${CYAN}  ▸ Paso 4 de 9 ─── Backend${NC}"
    log "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    log "${DIM}Elegí el framework para el backend${NC}"
    echo ""
    log "${WHITE}  ▸${NC}  ${BOLD}1${NC}) ${GREEN}NestJS${NC}"
    log "${DIM}        TypeScript + Decorators + DI${NC}"
    echo ""
    log "${WHITE}  ▸${NC}  ${BOLD}2${NC}) ${CYAN}Gin/Go${NC}"
    log "${DIM}        Go + Gin Framework (binario standalone)${NC}"
    echo ""
    read -r -t 120 -p "   └─►  " BACKEND_CHOICE
    echo ""

    case "$BACKEND_CHOICE" in
        1) BACKEND_TYPE="nestjs" ;;
        2) BACKEND_TYPE="golang" ;;
        *) log_warn "Opción inválida. Usando NestJS."; BACKEND_TYPE="nestjs" ;;
    esac
    log "${GREEN}  ✓${NC} Backend: ${BOLD}$BACKEND_TYPE${NC}"
}

# ============================================================================
# Select Architecture
# ============================================================================

select_architecture() {
    echo ""
    log "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    log "${BOLD}${CYAN}  ▸ Paso 5 de 9 ─── Arquitectura${NC}"
    log "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    log "${DIM}Elegí el tipo de arquitectura para tu proyecto${NC}"
    echo ""
    log "${WHITE}  ▸${NC}  ${BOLD}1${NC}) ${GREEN}Modular Vertical Slicing${NC}"
    log "${DIM}        Estructura por features/módulos${NC}"
    log "${DIM}        components, services, actions${NC}"
    echo ""
    log "${WHITE}  ▸${NC}  ${BOLD}2${NC}) ${MAGENTA}Hexagonal (Clean Architecture)${NC}"
    log "${DIM}        Domain → Application → Infrastructure${NC}"
    log "${DIM}        Separación extrema del negocio${NC}"
    echo ""
    read -r -t 120 -p "   └─►  " ARCH_CHOICE
    echo ""

    case "$ARCH_CHOICE" in
        1) ARCHITECTURE="modular" ;;
        2) ARCHITECTURE="hexagonal" ;;
        *) log_warn "Opción inválida. Usando Modular."; ARCHITECTURE="modular" ;;
    esac
    log "${GREEN}  ✓${NC} Arquitectura: ${BOLD}$ARCHITECTURE${NC}"
}

# ============================================================================
# Select Agent
# ============================================================================

select_agent() {
    echo ""
    log "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    log "${BOLD}${CYAN}  ▸ Paso 6 de 9 ─── Agente de IA${NC}"
    log "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    log "${DIM}Elegí el agente de IA principal para este proyecto${NC}"
    echo ""
    log "${WHITE}  ▸${NC}  ${BOLD}1${NC}) ${CYAN}OpenCode${NC}"
    log "${WHITE}  ▸${NC}  ${BOLD}2${NC}) ${CYAN}Claude Code${NC}"
    log "${WHITE}  ▸${NC}  ${BOLD}3${NC}) ${CYAN}Cursor${NC}"
    log "${WHITE}  ▸${NC}  ${BOLD}4${NC}) ${CYAN}Gemini CLI${NC}"
    log "${WHITE}  ▸${NC}  ${BOLD}5${NC}) ${CYAN}Todos${NC} (inyecta reglas para todos)"
    echo ""
    read -r -t 120 -p "   └─►  " AGENT_CHOICE
    echo ""

    case "$AGENT_CHOICE" in
        1) TARGET_AGENT="opencode" ;;
        2) TARGET_AGENT="claude" ;;
        3) TARGET_AGENT="cursor" ;;
        4) TARGET_AGENT="gemini" ;;
        5) TARGET_AGENT="all" ;;
        *) log_warn "Opción inválida. Usando OpenCode."; TARGET_AGENT="opencode" ;;
    esac
    log "${GREEN}  ✓${NC} Agente: ${BOLD}$TARGET_AGENT${NC}"
}

# ============================================================================
# Select Graphify
# ============================================================================

select_graphify() {
    echo ""
    log "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    log "${BOLD}${CYAN}  ▸ Paso 7 de 9 ─── Graphify (Knowledge Graph)${NC}"
    log "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    log "${DIM}Graphify genera un grafo de conocimiento del proyecto${NC}"
    echo ""
    log "${WHITE}  ▸${NC}  ${BOLD}1${NC}) ${GREEN}Sí - Habilitar Graphify${NC}"
    log "${WHITE}  ▸${NC}  ${BOLD}2${NC}) ${RED}No - Omitir Graphify${NC}"
    echo ""
    read -r -t 120 -p "   └─►  " GRAPHIFY_CHOICE
    echo ""

    case "$GRAPHIFY_CHOICE" in
        1) USE_GRAPHIFY="yes" ;;
        2) USE_GRAPHIFY="no" ;;
        *) USE_GRAPHIFY="no" ;;
    esac
    if [ "$USE_GRAPHIFY" = "yes" ]; then
        log "${GREEN}  ✓${NC} Graphify: ${GREEN}habilitado${NC}"
    else
        log "${DIM}  ○${NC} Graphify: omitido${NC}"
    fi

    # GGA se detecta automáticamente si está instalado
    if command -v gga &>/dev/null; then
        echo ""
        log "${GREEN}  ✓${NC} GGA: ${GREEN}detectado y configurado automáticamente${NC}"
    fi
}

# ============================================================================
# Select Docker DB
# ============================================================================

select_docker_db() {
    echo ""
    log "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    log "${BOLD}${CYAN}  ▸ Paso 8 de 9 ─── Docker Database (opcional)${NC}"
    log "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    log "${DIM}Contenedores Docker con PostgreSQL y/o MongoDB con persistencia${NC}"
    echo ""
    
    # Verificar Docker primero
    check_docker
    
    if [ "$DOCKER_AVAILABLE" -eq 0 ]; then
        log_warn "Docker no disponible. Mostrando solo opción 'No incluir'."
        echo ""
        log "${WHITE}  ▸${NC}  ${BOLD}1${NC}) ${RED}No incluir Docker${NC}"
        echo ""
        log "${DIM}    (Docker no está instalado o el daemon no está corriendo)${NC}"
        echo ""
        read -r -t 120 -p "   └─►  " DB_CHOICE
        echo ""
        DOCKER_DB_TYPE="none"
        log "${DIM}  ○${NC} Docker Database: omitido${NC}"
        return
    fi
    
    log "${WHITE}  ▸${NC}  ${BOLD}1${NC}) ${GREEN}PostgreSQL${NC} (SQL - ideal para Prisma)"
    log "${DIM}        Relational DB, PostgreSQL 16-alpine${NC}"
    echo ""
    log "${WHITE}  ▸${NC}  ${BOLD}2${NC}) ${CYAN}MongoDB${NC} (NoSQL)"
    log "${DIM}        Document DB, MongoDB 7.0${NC}"
    echo ""
    log "${WHITE}  ▸${NC}  ${BOLD}3${NC}) ${MAGENTA}Ambas${NC} (PostgreSQL + MongoDB)"
    log "${DIM}        Ambientes SQL + NoSQL${NC}"
    echo ""
    log "${WHITE}  ▸${NC}  ${BOLD}4${NC}) ${RED}No incluir Docker${NC}"
    log "${DIM}        Usar base de datos externa${NC}"
    echo ""
    read -r -t 120 -p "   └─►  " DB_CHOICE
    echo ""

    case "$DB_CHOICE" in
        1) DOCKER_DB_TYPE="postgres" ;;
        2) DOCKER_DB_TYPE="mongodb" ;;
        3) DOCKER_DB_TYPE="both" ;;
        4) DOCKER_DB_TYPE="none" ;;
        *) DOCKER_DB_TYPE="none" ;;
    esac
    
    case "$DOCKER_DB_TYPE" in
        postgres)
            log "${GREEN}  ✓${NC} Docker Database: ${GREEN}PostgreSQL${NC}"
            ;;
        mongodb)
            log "${GREEN}  ✓${NC} Docker Database: ${CYAN}MongoDB${NC}"
            ;;
        both)
            log "${GREEN}  ✓${NC} Docker Database: ${MAGENTA}PostgreSQL + MongoDB${NC}"
            ;;
        none)
            log "${DIM}  ○${NC} Docker Database: omitido${NC}"
            ;;
    esac
}

# ============================================================================
# Confirm Setup
# ============================================================================

confirm_setup() {
    echo ""
    log "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    log "${BOLD}${CYAN}  ▸ Paso 9 de 9 ─── Confirmar${NC}"
    log "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    log "${DIM}Resumen de tu proyecto:${NC}"
    echo ""
    log "${WHITE}  ▸${NC}  ${BOLD}Proyecto:${NC}     ${GREEN}$PROJECT_NAME${NC}"
    log "${WHITE}  ▸${NC}  ${BOLD}Tipo:${NC}        ${CYAN}$PROJECT_TYPE${NC}"
    if [ "$PROJECT_TYPE" = "backend" ] || [ "$PROJECT_TYPE" = "monorepo" ]; then
        log "${WHITE}  ▸${NC}  ${BOLD}Backend:${NC}     ${MAGENTA}$BACKEND_TYPE${NC}"
    fi
    if [ "$PROJECT_TYPE" = "frontend-next" ] || [ "$PROJECT_TYPE" = "frontend-vite" ] || [ "$PROJECT_TYPE" = "monorepo" ]; then
        log "${WHITE}  ▸${NC}  ${BOLD}Arquitectura:${NC}  ${CYAN}$ARCHITECTURE${NC}"
    fi
    log "${WHITE}  ▸${NC}  ${BOLD}Paquetes:${NC}     ${CYAN}$SELECTED_PKG_MANAGER${NC}"
    log "${WHITE}  ▸${NC}  ${BOLD}Agente:${NC}        ${MAGENTA}$TARGET_AGENT${NC}"
    log "${WHITE}  ▸${NC}  ${BOLD}Graphify:${NC}      ${WHITE}$USE_GRAPHIFY${NC}"
    
    case "$DOCKER_DB_TYPE" in
        postgres)
            log "${WHITE}  ▸${NC}  ${BOLD}Docker DB:${NC}     ${GREEN}PostgreSQL${NC}"
            ;;
        mongodb)
            log "${WHITE}  ▸${NC}  ${BOLD}Docker DB:${NC}     ${CYAN}MongoDB${NC}"
            ;;
        both)
            log "${WHITE}  ▸${NC}  ${BOLD}Docker DB:${NC}     ${MAGENTA}PostgreSQL + MongoDB${NC}"
            ;;
        none)
            log "${WHITE}  ▸${NC}  ${BOLD}Docker DB:${NC}     ${DIM}Omitido${NC}"
            ;;
    esac
    
    if command -v gga &>/dev/null; then
        log "${WHITE}  ▸${NC}  ${BOLD}GGA:${NC}         ${GREEN}Automático${NC}"
    fi
    echo ""
    read -r -t 120 -p "   └─►  Confirmar y crear proyecto? [${GREEN}s${NC}/${RED}n${NC}]: " CONFIRM
    echo ""

    if [[ ! "$CONFIRM" =~ ^[Ss]$ ]] && [[ ! "$CONFIRM" =~ ^[Ss][Ii]$ ]] && [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
        log_info "Operación cancelada."
        exit 0
    fi
}