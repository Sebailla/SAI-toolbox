#!/usr/bin/env bash

# ============================================================================
# SAI Project Initializer
# Crea un proyecto Next.js con arquitectura Modular o Hexagonal.
# ============================================================================

set -e

# Colores usando ANSI-C quoting para portabilidad
RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[0;33m'
CYAN=$'\033[0;36m'
MAGENTA=$'\033[0;35m'
WHITE=$'\033[0;37m'
BOLD=$'\033[1m'
DIM=$'\033[2m'
NC=$'\033[0m'

# Gestor de paquetes seleccionado
SELECTED_PKG_MANAGER=""

# Tipo de proyecto: frontend-next | frontend-vite | backend | monorepo
PROJECT_TYPE=""

# Tipo de backend (si aplica): nestjs | golang
BACKEND_TYPE=""

# Arquitectura (si aplica): modular | hexagonal
ARCHITECTURE=""

# Helper para logs con color (printf '%b' interpreta \033 correctamente)
log() {
    printf '%b' "$1"
}

log_info()    { log "${CYAN}${BOLD}[INFO]${NC}   $*\\n"; }
log_success() { log "${GREEN}${BOLD}[OK]${NC}     $*\\n"; }
log_warn()    { log "${YELLOW}${BOLD}[WARN]${NC}  $*\\n"; }
log_error()   { log "${RED}${BOLD}[ERROR]${NC}  $*\\n" >&2; }

ORIGINAL_DIR=$(pwd)
PROJECT_CREATED=0
CLEANUP_DONE=0

cleanup() {
    local exit_code=${1:-0}
    cd "$ORIGINAL_DIR"
    # Evitar ejecución múltiple del cleanup
    if [ "$CLEANUP_DONE" -eq 1 ]; then
        return
    fi
    CLEANUP_DONE=1

    if [ "$PROJECT_CREATED" -eq 1 ]; then
        # El proyecto se creó pero algo falló después
        log "${RED}${BOLD}[FATAL]${NC} El script no terminó correctamente. Deshaciendo...\n"
        if [ -n "$PROJECT_NAME" ] && [ -d "$ORIGINAL_DIR/$PROJECT_NAME" ]; then
            log_warn "Borrando directorio a medio crear: $PROJECT_NAME"
            rm -rf "$ORIGINAL_DIR/$PROJECT_NAME"
        fi
    fi
    # Only exit 1 if there was an error
    if [ "$exit_code" -ne 0 ]; then
        exit 1
    fi
}

trap 'cleanup $?' EXIT INT TERM

# ============================================================================
# Selectores interactivos
# ============================================================================

print_banner() {
    log "${CYAN}${BOLD}"
    echo "  ╔═══════════════════════════════════════════════╗"
    echo "  ║   SAI Project Initializer                     ║"
    echo "  ║   Arquitectura Modular o Hexagonal            ║"
    echo "  ╚═══════════════════════════════════════════════╝"
    log "${NC}"
    echo ""
}

# FIX 4: Replace recursion with iterative while loop
select_project_name() {
    while true; do
        echo ""
        log "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        log "${BOLD}${CYAN}  ▸ Paso 1 de 6 ─── Nombre del proyecto${NC}"
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
        # npm/npmrc exige minúsculas para package.json name
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

select_package_manager() {
    echo ""
    log "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    log "${BOLD}${CYAN}  ▸ Paso 2 de 6 ─── Gestor de paquetes${NC}"
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

select_project_type() {
    echo ""
    log "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    log "${BOLD}${CYAN}  ▸ Paso 3 de 8 ─── Tipo de proyecto${NC}"
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

select_backend_type() {
    echo ""
    log "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    log "${BOLD}${CYAN}  ▸ Paso 4 de 8 ─── Backend${NC}"
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

# FIX 4: Replace recursion with iterative while loop (no recursion needed for simple case)
select_architecture() {
    echo ""
    log "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    log "${BOLD}${CYAN}  ▸ Paso 5 de 8 ─── Arquitectura${NC}"
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

# FIX 4: Replace recursion with iterative while loop (no recursion needed for simple case)
select_agent() {
    echo ""
    log "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    log "${BOLD}${CYAN}  ▸ Paso 6 de 8 ─── Agente de IA${NC}"
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

select_graphify() {
    echo ""
    log "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    log "${BOLD}${CYAN}  ▸ Paso 7 de 8 ─── Graphify (Knowledge Graph)${NC}"
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

confirm_setup() {
    echo ""
    log "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    log "${BOLD}${CYAN}  ▸ Paso 8 de 8 ─── Confirmar${NC}"
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

# ============================================================================
# Validaciones
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
# Timeout portable (macOS no tiene timeout, usa gtimeout o perl)
# ============================================================================

run_with_timeout() {
    local seconds=$1
    shift
    local cmd=("$@")

    # Intentar timeout nativo (Linux)
    if command -v timeout &>/dev/null; then
        timeout "$seconds" "${cmd[@]}"
        return $?
    fi

    # Intentar gtimeout (macOS con GNU coreutils)
    if command -v gtimeout &>/dev/null; then
        gtimeout "$seconds" "${cmd[@]}"
        return $?
    fi

    # FIX 2: Perl fallback - use alarm + system instead of IPC::Open3 to avoid deadlock
    # system() doesn't capture output so no pipe issues
    if command -v perl &>/dev/null; then
        perl -e '
            use strict;
            use warnings;
            my $secs = shift @ARGV;
            $SIG{ALRM} = sub { exit 124 };
            alarm($secs);
            system(@ARGV);
            my $cmd_exit = $?;  # Capture exit BEFORE alarm(0)
            alarm(0);
            exit $cmd_exit;
        ' "${seconds}" "${cmd[@]}"
        return $?
    fi

    # Si nada funciona, ejecutar sin timeout
    "${cmd[@]}"
}

# ============================================================================
# Crear proyecto
# ============================================================================

create_frontend_next() {
    log_info "Creando proyecto Next.js: $PROJECT_NAME..."

    # FIX 3: Set PROJECT_CREATED immediately after mkdir succeeds, before cd
    # Crear directorio con verificación
    if ! mkdir -p "$PROJECT_NAME"; then
        log_error "No se pudo crear el directorio $PROJECT_NAME"
        exit 1
    fi

    # Marcar que el directorio fue creado (para cleanup) - BEFORE cd
    PROJECT_CREATED=1

    # Entrar al directorio con verificación
    if ! cd "$PROJECT_NAME"; then
        log_error "No se pudo acceder al directorio $PROJECT_NAME"
        exit 1
    fi

    log_info "Inicializando Git (rama main)..."
    # Git 2.28+ soporta -b. Intentar directo y hacer fallback si falla.
    if ! git init -q -b main 2>/dev/null; then
        git init -q && git checkout -b main
    fi

    # Determinar el comando del gestor de paquetes seleccionado
    local create_cmd=""
    local install_cmd=""
    local install_dev_cmd=""
    local pkg_exec_cmd=""
    
    case "$SELECTED_PKG_MANAGER" in
        bun)
            create_cmd="bunx create-next-app@latest"
            install_cmd="bun add"
            install_dev_cmd="bun add -d"
            pkg_exec_cmd="bun"
            ;;
        pnpm)
            create_cmd="pnpm dlx create-next-app@latest"
            install_cmd="pnpm add"
            install_dev_cmd="pnpm add -D"
            pkg_exec_cmd="pnpm"
            ;;
        npm)
            create_cmd="npx create-next-app@latest"
            install_cmd="npm install"
            install_dev_cmd="npm install -D"
            pkg_exec_cmd="npm"
            ;;
        *)
            create_cmd="bunx create-next-app@latest"
            install_cmd="bun add"
            install_dev_cmd="bun add -d"
            pkg_exec_cmd="bun"
            ;;
    esac

    log_info "Scaffold Next.js (TypeScript, Tailwind v4, App Router, src/)..."
    run_with_timeout 300 $create_cmd . \
        --typescript \
        --tailwind \
        --eslint \
        --app \
        --src-dir \
        --import-alias "@/*" \
        --use-${SELECTED_PKG_MANAGER} \
        --skip-install \
        --yes || { log_error "create-next-app falló"; exit 1; }

    log_info "Instalando dependencias del stack..."
    run_with_timeout 120 $install_cmd @prisma/client@latest lucide-react@latest clsx@latest tailwind-merge@latest \
        date-fns@latest zod@latest react-hot-toast@latest ioredis@latest \
        bcryptjs@latest jsonwebtoken@latest dotenv@latest || log_warn "Algunas dependencias no se instalaron"

    run_with_timeout 120 $install_dev_cmd prisma@latest vitest@latest @testing-library/react@latest \
        @testing-library/dom@latest jsdom@latest @playwright/test@latest \
        husky@latest lint-staged@latest tsx@latest @types/node@latest \
        @types/react@latest @types/react-dom@latest @types/bcryptjs@latest \
        @types/jsonwebtoken@latest @commitlint/cli@latest \
        @commitlint/config-conventional@latest standard-version@latest \
        || log_warn "Algunas devDependencies no se instalaron"

    log_info "Inicializando Prisma..."
    $pkg_exec_cmd x prisma init || log_warn "Prisma init falló"

    mkdir -p prisma
    cat > prisma/schema.prisma <<'EOF'
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

model Example {
  id        String   @id @default(cuid())
  name      String
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
}
EOF
    log_success "Prisma schema configurado"
}

# ============================================================================
# Vite + React
# ============================================================================

create_frontend_vite() {
    log_info "Creando proyecto React + Vite: $PROJECT_NAME..."

    if ! mkdir -p "$PROJECT_NAME"; then
        log_error "No se pudo crear el directorio $PROJECT_NAME"
        exit 1
    fi

    PROJECT_CREATED=1

    if ! cd "$PROJECT_NAME"; then
        log_error "No se pudo acceder al directorio $PROJECT_NAME"
        exit 1
    fi

    log_info "Inicializando Git (rama main)..."
    if ! git init -q -b main 2>/dev/null; then
        git init -q && git checkout -b main
    fi

    local create_cmd=""
    local install_cmd=""
    local install_dev_cmd=""
    local pkg_exec_cmd=""

    case "$SELECTED_PKG_MANAGER" in
        bun)
            create_cmd="bunx create-vite"
            install_cmd="bun add"
            install_dev_cmd="bun add -d"
            pkg_exec_cmd="bun"
            ;;
        pnpm)
            create_cmd="pnpm dlx create-vite"
            install_cmd="pnpm add"
            install_dev_cmd="pnpm add -D"
            pkg_exec_cmd="pnpm"
            ;;
        npm)
            create_cmd="npx create-vite"
            install_cmd="npm install"
            install_dev_cmd="npm install -D"
            pkg_exec_cmd="npm"
            ;;
        *)
            create_cmd="bunx create-vite"
            install_cmd="bun add"
            install_dev_cmd="bun add -d"
            pkg_exec_cmd="bun"
            ;;
    esac

    log_info "Scaffold Vite + React + TypeScript..."
    run_with_timeout 300 $create_cmd . --template react-ts \
        || { log_error "create-vite falló"; exit 1; }

    log_info "Instalando Tailwind CSS..."
    run_with_timeout 120 $install_dev_cmd tailwindcss@latest postcss@latest autoprefixer@latest || log_warn "Tailwind no se instaló"

    log_info "Instalando dependencias del stack..."
    run_with_timeout 120 $install_cmd @prisma/client@latest lucide-react@latest clsx@latest tailwind-merge@latest \
        date-fns@latest zod@latest react-hot-toast@latest ioredis@latest \
        bcryptjs@latest jsonwebtoken@latest dotenv@latest || log_warn "Algunas dependencias no se instalaron"

    run_with_timeout 120 $install_dev_cmd prisma@latest vitest@latest @testing-library/react@latest \
        @testing-library/dom@latest jsdom@latest @playwright/test@latest \
        husky@latest lint-staged@latest tsx@latest @types/node@latest \
        @types/react@latest @types/react-dom@latest @types/bcryptjs@latest \
        @types/jsonwebtoken@latest @commitlint/cli@latest \
        @commitlint/config-conventional@latest standard-version@latest \
        || log_warn "Algunas devDependencies no se instalaron"

    log_info "Inicializando Prisma..."
    $pkg_exec_cmd x prisma init || log_warn "Prisma init falló"

    mkdir -p prisma
    cat > prisma/schema.prisma <<'EOF'
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

model Example {
  id        String   @id @default(cuid())
  name      String
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
}
EOF

    cat > tailwind.config.js <<'EOF'
/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {},
  },
  plugins: [],
}
EOF

    cat > postcss.config.js <<'EOF'
export default {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
}
EOF

    mkdir -p src/components src/services src/types
    touch src/actions.ts
    log_success "Proyecto Vite configurado"
}

# ============================================================================
# Backend NestJS
# ============================================================================

create_backend_nestjs() {
    log_info "Creando proyecto NestJS: $PROJECT_NAME..."

    if ! mkdir -p "$PROJECT_NAME"; then
        log_error "No se pudo crear el directorio $PROJECT_NAME"
        exit 1
    fi

    PROJECT_CREATED=1

    if ! cd "$PROJECT_NAME"; then
        log_error "No se pudo acceder al directorio $PROJECT_NAME"
        exit 1
    fi

    log_info "Inicializando Git (rama main)..."
    if ! git init -q -b main 2>/dev/null; then
        git init -q && git checkout -b main
    fi

    local create_cmd=""
    local install_cmd=""
    local install_dev_cmd=""
    local pkg_exec_cmd=""

    case "$SELECTED_PKG_MANAGER" in
        bun)
            create_cmd="bunx @nestjs/cli@latest new"
            install_cmd="bun add"
            install_dev_cmd="bun add -d"
            pkg_exec_cmd="bun"
            ;;
        pnpm)
            create_cmd="pnpm dlx @nestjs/cli@latest new"
            install_cmd="pnpm add"
            install_dev_cmd="pnpm add -D"
            pkg_exec_cmd="pnpm"
            ;;
        npm)
            create_cmd="npx @nestjs/cli@latest new"
            install_cmd="npm install"
            install_dev_cmd="npm install -D"
            pkg_exec_cmd="npm"
            ;;
        *)
            create_cmd="bunx @nestjs/cli@latest new"
            install_cmd="bun add"
            install_dev_cmd="bun add -d"
            pkg_exec_cmd="bun"
            ;;
    esac

    log_info "Scaffold NestJS..."
    run_with_timeout 300 $create_cmd . --skip-git --package-manager $SELECTED_PKG_MANAGER \
        || { log_error "NestJS scaffold falló"; exit 1; }

    log_info "Instalando dependencias adicionales..."
    run_with_timeout 120 $install_cmd @prisma/client@latest class-validator@latest class-transformer@latest \
        @nestjs/config@latest bcryptjs@latest jsonwebtoken@latest dotenv@latest \
        || log_warn "Algunas dependencias no se instalaron"

    run_with_timeout 120 $install_dev_cmd prisma@latest @types/bcryptjs@latest @types/jsonwebtoken@latest \
        @commitlint/cli@latest @commitlint/config-conventional@latest standard-version@latest \
        || log_warn "Algunas devDependencies no se instalaron"

    log_info "Inicializando Prisma..."
    $pkg_exec_cmd x prisma init || log_warn "Prisma init falló"

    mkdir -p prisma
    cat > prisma/schema.prisma <<'EOF'
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

model Example {
  id        String   @id @default(cuid())
  name      String
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
}
EOF

    mkdir -p .agent/skills plans specs designs .github/workflows
    log_success "Proyecto NestJS configurado"
}

# ============================================================================
# Backend Go (Gin)
# ============================================================================

create_backend_golang() {
    log_info "Creando proyecto Go + Gin: $PROJECT_NAME..."

    if ! mkdir -p "$PROJECT_NAME"; then
        log_error "No se pudo crear el directorio $PROJECT_NAME"
        exit 1
    fi

    PROJECT_CREATED=1

    if ! cd "$PROJECT_NAME"; then
        log_error "No se pudo acceder al directorio $PROJECT_NAME"
        exit 1
    fi

    log_info "Inicializando Git (rama main)..."
    if ! git init -q -b main 2>/dev/null; then
        git init -q && git checkout -b main
    fi

    log_info "Inicializando módulo Go..."
    go mod init "$PROJECT_NAME" || log_warn "go mod init falló"

    log_info "Creando estructura de directorios..."
    mkdir -p cmd/server
    mkdir -p internal/handlers
    mkdir -p internal/middleware
    mkdir -p internal/models
    mkdir -p pkg/response
    mkdir -p configs

    cat > cmd/server/main.go <<EOF
package main

import (
	"log"
	"os"

	"github.com/gin-gonic/gin"
	"${PROJECT_NAME}/internal/handlers"
	"${PROJECT_NAME}/internal/middleware"
)

func main() {
	r := gin.Default()

	r.Use(middleware.CORS())

	h := handlers.NewHandler()

	api := r.Group("/api")
	{
		api.GET("/health", h.Health)
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("Server starting on port %s", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}
EOF

    # Update go.mod with real module name
    cat > go.mod <<EOF
module ${PROJECT_NAME}

go 1.21

require (
	github.com/gin-gonic/gin v1.9.1
)
EOF

    go mod tidy

    go get github.com/gin-gonic/gin@v1.9.1

    mkdir -p .agent/skills plans specs designs .github/workflows
    log_success "Proyecto Go + Gin configurado"
}

# ============================================================================
# Monorepo Fullstack
# ============================================================================

create_monorepo() {
    log_info "Creando Monorepo Fullstack: $PROJECT_NAME..."

    if ! mkdir -p "$PROJECT_NAME"; then
        log_error "No se pudo crear el directorio $PROJECT_NAME"
        exit 1
    fi

    PROJECT_CREATED=1

    if ! cd "$PROJECT_NAME"; then
        log_error "No se pudo acceder al directorio $PROJECT_NAME"
        exit 1
    fi

    log_info "Inicializando Git (rama main)..."
    if ! git init -q -b main 2>/dev/null; then
        git init -q && git checkout -b main
    fi

    log_info "Creando estructura monorepo..."

    case "$SELECTED_PKG_MANAGER" in
        bun)
            cat > package.json <<EOF
{
  "name": "$PROJECT_NAME",
  "workspaces": [
    "apps/*",
    "packages/*"
  ],
  "private": true
}
EOF
            ;;
        pnpm)
            cat > pnpm-workspace.yaml <<EOF
packages:
  - 'apps/*'
  - 'packages/*'
EOF
            ;;
        npm)
            cat > package.json <<EOF
{
  "name": "$PROJECT_NAME",
  "workspaces": [
    "apps/*",
    "packages/*"
  ],
  "private": true
}
EOF
            ;;
    esac

    mkdir -p apps/web
    mkdir -p apps/api
    mkdir -p packages/shared

    if [ "$BACKEND_TYPE" = "nestjs" ]; then
        log_info "Configurando apps/api con NestJS..."
        cd apps/api

        case "$SELECTED_PKG_MANAGER" in
            bun)
                bunx @nestjs/cli@latest new . --skip-git --package-manager $SELECTED_PKG_MANAGER \
                    || log_warn "NestJS scaffold falló"
                ;;
            pnpm)
                pnpm dlx @nestjs/cli@latest new . --skip-git --package-manager $SELECTED_PKG_MANAGER \
                    || log_warn "NestJS scaffold falló"
                ;;
            npm)
                npx @nestjs/cli@latest new . --skip-git --package-manager $SELECTED_PKG_MANAGER \
                    || log_warn "NestJS scaffold falló"
                ;;
        esac

        cd ../..
    else
        log_info "Configurando apps/api con Gin/Go..."
        cd apps/api

        go mod init "${PROJECT_NAME}/api" || log_warn "go mod init falló"
        mkdir -p cmd/server internal/handlers internal/middleware

        cat > cmd/server/main.go <<'EOF'
package main

import "github.com/gin-gonic/gin"

func main() {
	r := gin.Default()
	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{"status": "ok"})
	})
	r.Run()
}
EOF

        go get github.com/gin-gonic/gin@v1.9.1
        cd ../..
    fi

    log_info "Configurando apps/web con Next.js..."
    cd apps/web

    case "$SELECTED_PKG_MANAGER" in
        bun)
            bunx create-next-app@latest . --typescript --tailwind --eslint --app --src-dir \
                --import-alias "@/*" --use-bun --skip-install --yes \
                || log_warn "Next.js scaffold falló"
            ;;
        pnpm)
            pnpm dlx create-next-app@latest . --typescript --tailwind --eslint --app --src-dir \
                --import-alias "@/*" --use-pnpm --skip-install --yes \
                || log_warn "Next.js scaffold falló"
            ;;
        npm)
            npx create-next-app@latest . --typescript --tailwind --eslint --app --src-dir \
                --import-alias "@/*" --use-npm --skip-install --yes \
                || log_warn "Next.js scaffold falló"
            ;;
    esac

    cd ../..

    cat > packages/shared/index.ts <<'EOF'
export const sharedConfig = {
  name: "shared",
};
EOF

    mkdir -p .agent/skills plans specs designs .github/workflows
    log_success "Monorepo Fullstack configurado"
}

# ============================================================================
# GitHub Actions
# ============================================================================

setup_github_actions() {
    log_info "Configurando GitHub Actions..."

    # Determinar commands según gestor
    local install_cmd=""
    local run_cmd=""
    local setup_action=""
    case "$SELECTED_PKG_MANAGER" in
        bun)
            install_cmd="bun install --frozen-lockfile"
            run_cmd="bun"
            setup_action="oven-sh/setup-bun@v2"
            ;;
        pnpm)
            install_cmd="pnpm install --frozen-lockfile"
            run_cmd="pnpm"
            setup_action="pnpm/action-setup@v2"
            ;;
        npm)
            install_cmd="npm ci"
            run_cmd="npm"
            setup_action="actions/setup-node@v4"
            ;;
        *)
            install_cmd="bun install --frozen-lockfile"
            run_cmd="bun"
            setup_action="oven-sh/setup-bun@v2"
            ;;
    esac

    mkdir -p .github/workflows
    cat > .github/workflows/release.yml <<EOF
name: Release on Main

on:
  push:
    branches:
      - main

jobs:
  health-gate:
    name: "Health Check"
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: ${setup_action}
      - name: Install dependencies
        run: ${install_cmd}
      - name: Build
        run: ${run_cmd} run build
      - name: Test
        run: ${run_cmd} test --run

  release:
    name: "Release"
    runs-on: ubuntu-latest
    needs: [health-gate]
    permissions:
      contents: write
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
          token: \${{ secrets.GITHUB_TOKEN }}
      - uses: ${setup_action}
      - name: Install deps
        run: ${install_cmd}
      - name: Create Release
        run: |
          git config --global user.name 'github-actions[bot]'
          git config --global user.email 'github-actions[bot]@users.noreply.github.com'
          ${run_cmd} run release
          git push --follow-tags origin main
EOF
}

# ============================================================================
# VSCode settings
# ============================================================================

setup_vscode() {
    log_info "Configurando VSCode..."
    mkdir -p .vscode
    cat > .vscode/settings.json <<'EOF'
{
  "explorer.exclude": {
    "**/.agent": true,
    "**/node_modules": true,
    "**/plans": true,
    "**/specs": true,
    "**/.docs": true
  },
  "editor.formatOnSave": true,
  "files.associations": {
    "*.md": "markdown"
  }
}
EOF
}

# ============================================================================
# AGENTS.md
# ============================================================================

setup_agents_md() {
    log_info "Generando AGENTS.md..."

    if [ "$ARCHITECTURE" = "hexagonal" ]; then
        cat > AGENTS.md <<'EOF'
# Project Rules

## 🗣️ Comunicación (OBLIGATORIO)

**Idioma:** Español Rioplatense (voseo). Uso obligatorio en todas las interacciones.

**Regla de Fundamentación:**
- NUNCA respondas con solo el "qué". Siempre incluye:
  - **POR QUÉ:** Explicá la razón técnica o de diseño detrás de la decisión.
  - **CÓMO:** Mostrá o explicá la implementación concreta.
- Si no entendés algo, PREGUNTÁ. No infles ni supongas.

**Estructura de respuestas:**
```
Respuesta breve + concreción.

**Por qué:** [razón técnica/de negocio]
**Cómo:** [implementación o ejemplo]
```

## 🚨 ARQUITECTURA HEXAGONAL (STRICT - NO VIOLABLE)

Esta proyecto usa **Hexagonal Architecture (Clean Architecture)**. 

**ESTRUCTURA OBLIGATORIA:**
```
src/
├── domain/           # Lógica pura de negocio - SIN dependencias externas
│   ├── entities/     # Entidades del dominio
│   ├── value-objects/ # Objetos de valor
│   ├── services/     # Servicios de dominio
│   ├── events/       # Eventos de dominio
│   ├── exceptions/    # Excepciones del dominio
│   └── interfaces/    # Contratos (puertos de salida)
├── application/      # Casos de uso - depende de Domain
│   ├── use-cases/    # Casos de uso
│   ├── dto/          # Data Transfer Objects
│   └── ports/        # Puertos de entrada/salida
├── infrastructure/   # Adaptadores - implementa interfaces de Domain/Application
│   ├── persistence/  # Prisma, repositorios
│   ├── http/        # Controllers, middleware
│   ├── queue/       # Colas de mensajes
│   └── external/    # Servicios externos
└── shared/          # Utilidades compartidas
```

**REGLAS ABSOLUTAS (PENALIZACIÓN: FALLA DE BUILD SI SE VIOLA):**
1. **Domain** NO puede importar de `application/`, `infrastructure/`, ni `shared/`
2. **Application** NO puede importar de `infrastructure/`
3. Todo lo que esté en `infrastructure/` DEBE implementar interfaces definidas en Domain/Application
4. NINGÚN archivo de dominio puede tener imports de frameworks externos (Prisma, Express, etc.)
5. Los casos de uso (application) reciben y devuelven DTOs, NO entidades directas

**COMPORTAMIENTO ANTE CÓDIGO VIOLADO:**
- Si el usuario pide algo que viola la arquitectura, DECLINÁ educadamente
- Explicá por qué viola la arquitectura y proponé alternativa que la respete
- Bajo NINGUNA circunstancia generes código que violente la estructura

## 📚 Consultas de Documentación

**ANTES de responder sobre frameworks o librerías:**
1. Consultá Context7 para obtener documentación oficial:
   - `context7_resolve-library-id` para obtener el ID de la librería
   - `context7_query-docs` para consultar la documentación

2. SIEMPRE citá la fuente de Context7 en la respuesta.

3. Si la información no está en Context7, buscá en la documentación oficial del proyecto.

**Ejemplo de respuesta correcta:**
```
Para implementar validation en React, necesitás Zod.

**Por qué:** Zod es el estándar de la industria para validación de esquemas en TypeScript,
ofreciendo inferencia de tipos estáticos y runtime validation.

**Cómo:** 
\`\`\`typescript
import { z } from 'zod';
const schema = z.object({ name: z.string() });
\`\`\`

*Fuente: Context7 - zod*
EOF
    else
        cat > AGENTS.md <<'EOF'
# Project Rules

## 🗣️ Comunicación (OBLIGATORIO)

**Idioma:** Español Rioplatense (voseo). Uso obligatorio en todas las interacciones.

**Regla de Fundamentación:**
- NUNCA respondas con solo el "qué". Siempre incluye:
  - **POR QUÉ:** Explicá la razón técnica o de diseño detrás de la decisión.
  - **CÓMO:** Mostrá o explicá la implementación concreta.
- Si no entendés algo, PREGUNTÁ. No infles ni supongas.

**Estructura de respuestas:**
```
Respuesta breve + concreción.

**Por qué:** [razón técnica/de negocio]
**Cómo:** [implementación o ejemplo]
```

## 🚨 ARQUITECTURA MODULAR VERTICAL SLICING (STRICT - NO VIOLABLE)

Este proyecto usa **Modular Vertical Slicing**. Todo código DEBE vivir en un módulo.

**ESTRUCTURA OBLIGATORIA POR MÓDULO:**
```
src/modules/<nombre>/
├── components/      # Componentes UI de este módulo
├── services/       # Lógica de negocio pura (sin React)
├── actions.ts      # Server Actions (validación + orquestación)
├── types.ts        # Tipos específicos del módulo
└── index.ts       # API pública del módulo
```

**COMPONENTES COMPARTIDOS:**
```
src/core/            # Utilidades, hooks, lib compartidos
src/components/ui/   # Componentes UI genéricos (Button, Dialog, etc.)
```

**REGLAS ABSOLUTAS (PENALIZACIÓN: FALLA DE BUILD SI SE VIOLA):**
1. **Services** NO pueden usar hooks de React ni importar componentes
2. **Components** NO pueden contener lógica de negocio (delegar a Services)
3. **Actions** SIEMPRE usan `'use server'` y validan con Zod
4. Cada módulo es auto-contenido: sus components/services/actions se comunican SOLO dentro del módulo
5. Lógica compartida va a `src/core/`, NO dentro de módulos específicos
6. UI genérica va a `src/components/ui/`, NO a módulos específicos

**COMPORTAMIENTO ANTE CÓDIGO VIOLADO:**
- Si el usuario pide algo que viola la arquitectura, DECLINÁ educadamente
- Explicá por qué viola la arquitectura y proponé alternativa que la respete
- Bajo NINGUNA circunstancia generes código que violente la estructura

## 📚 Consultas de Documentación

**ANTES de responder sobre frameworks o librerías:**
1. Consultá Context7 para obtener documentación oficial:
   - `context7_resolve-library-id` para obtener el ID de la librería
   - `context7_query-docs` para consultar la documentación

2. SIEMPRE citá la fuente de Context7 en la respuesta.

3. Si la información no está en Context7, buscá en la documentación oficial del proyecto.

**Ejemplo de respuesta correcta:**
```
Para implementar validation en React, necesitás Zod.

**Por qué:** Zod es el estándar de la industria para validación de esquemas en TypeScript,
ofreciendo inferencia de tipos estáticos y runtime validation.

**Cómo:** 
\`\`\`typescript
import { z } from 'zod';
const schema = z.object({ name: z.string() });
\`\`\`

*Fuente: Context7 - zod*
EOF
    fi

    cat >> AGENTS.md <<'EOF'

## Branch Naming
Formato: `tipo/nombre-en-kebab-case`. Tipos válidos: `feat, fix, hotfix, chore, docs, refactor, test`.

## 🛡️ Protocolo de Actuación
- El orquestador DEBE limitarse a guiar. No debe escribir código directamente.
- Toda acción técnica DEBE ser delegada a subagentes.
- Cero suposiciones: siempre PREGUNTAR antes de inferir.
- Confirmación constante antes de cambios significativos.
- Rama de partida siempre `develop` (no main).

## 🧠 Knowledge Graph (Graphify)
- Si existe `graphify-out/`, leer `graphify-out/GRAPH_REPORT.md` antes de modificar arquitectura.

## 🔄 SDD (Spec-Driven Development)

**OBLIGATORIO para toda feature nueva:**

1. **EXPLORE** - Investigar el codebase antes de proponer cambios
   - Usar skill `sdd-explore` para entender el contexto
   - Leer `graphify-out/GRAPH_REPORT.md` si existe

2. **PROPOSE** - Crear propuesta formal
   - Usar skill `sdd-propose`
   - Definir: intent, scope, approach, affected areas

3. **SPEC** - Escribir especificación formal
   - Usar skill `sdd-spec`
   - Incluir: requirements, scenarios, acceptance criteria

4. **DESIGN** - Documentar diseño técnico
   - Usar skill `sdd-design`
   - Arquitectura, dependencias, tradeoffs

5. **TASKS** - Dividir en tareas implementables
   - Usar skill `sdd-tasks`
   - Cada tarea = un commit atómico

6. **APPLY** - Implementar siguiendo spec y design
   - Usar skill `sdd-apply`

7. **VERIFY** - Validar contra specs
   - Usar skill `sdd-verify`

8. **ARCHIVE** - Guardar specs y cleanup
   - Usar skill `sdd-archive`

**FLUJO COMPLETO:**
```
User Request → SDD Explore → SDD Propose → SDD Spec → SDD Design → SDD Tasks → IMPLEMENT → VERIFY → ARCHIVE
```

## 🚨 GGA (Gentleman Guardian Angel) - CORRECCIÓN OBLIGATORIA

**NUNCA hagas commit si GGA reporta errores.**

**PROTOCOLO:**
1. `git commit` triggers `gga run`
2. Si GGA reporta errores/warnings:
   - DETENER el commit inmediatamente
   - CORREGIR todos los errores reportados
   - Volver a ejecutar `git commit` (se re-ejecuta GGA)
   - Repetir hasta que GGA apruebe (STATUS: PASSED)
3. SOLO cuando GGA dice PASSED, el commit se concreta

**REGLA DE ORO:** GGA es tu mentor. Si te dice que está mal, está mal. Corregí.

## Calidad
- Toda feature nueva debe tener tests unitarios.
- Conventional Commits estrictos.
EOF
}

# ============================================================================
# Reglas por agente
# ============================================================================

setup_agent_rules() {
    log_info "Configurando reglas para: $TARGET_AGENT..."

    if [ "$TARGET_AGENT" = "claude" ] || [ "$TARGET_AGENT" = "all" ]; then
        cp AGENTS.md CLAUDE.md
    fi
    if [ "$TARGET_AGENT" = "gemini" ] || [ "$TARGET_AGENT" = "all" ]; then
        cp AGENTS.md GEMINI.md
    fi
    if [ "$TARGET_AGENT" = "cursor" ] || [ "$TARGET_AGENT" = "all" ]; then
        cp AGENTS.md .cursorrules
    fi
}

# ============================================================================
# Skills
# ============================================================================

setup_skills() {
    log_info "Instalando skills..."
    mkdir -p .agent/skills/documentar-specs-usuario
    mkdir -p .agent/skills/documentar-plan-diseno

    cat > .agent/skills/documentar-specs-usuario/SKILL.md <<'EOF'
---
name: documentar-specs-usuario
description: Genera especificaciones funcionales para el usuario final en /specs.
---

# 📝 Documentación de Especificaciones para el Usuario

## Cuándo usar
- Trigger: Después de terminar una funcionalidad nueva (`feat`).

## Instrucciones
1. Crear archivo en `specs/YYYY-MM-DD-nombre-feature.md`.
2. Redactar en lenguaje no técnico para el usuario final.
3. Incluir: ¿Qué es?, Cómo se usa, Beneficios.
EOF

    cat > .agent/skills/documentar-plan-diseno/SKILL.md <<'EOF'
---
name: documentar-plan-diseno
description: Genera documentos de planificación técnica y diseño UI/UX en /plans y /designs.
---

# 🏗️ Planificación y Diseño

## Cuándo usar
- Trigger: ANTES de escribir código para features grandes o complejas.

## Flujo
1. Si es técnica: crear `plans/YYYY-MM-DD-plan-feature.md`.
2. Si es visual: crear `designs/YYYY-MM-DD-diseno-feature.md`.
3. Detallar arquitectura, dependencias, referencias a diseño.
EOF
}

# ============================================================================
# Husky + Commitlint
# ============================================================================

setup_husky() {
    log_info "Configurando Husky y Commitlint..."

    # Verificar que .git existe (husky init lo necesita)
    if [ ! -d ".git" ]; then
        log_error "No se encontró .git. ¿Corriste git init?"
        exit 1
    fi

    # Usar el gestor de paquetes seleccionado
    local install_cmd=""
    local exec_cmd=""
    case "$SELECTED_PKG_MANAGER" in
        bun)   install_cmd="bun install" ;;
        pnpm)  install_cmd="pnpm install" ;;
        npm)   install_cmd="npm install" ;;
        *)     install_cmd="bun install" ;;
    esac

    log_info "Instalando dependencias antes de Husky..."
    $install_cmd || log_warn "Instalación de deps falló, continuando..."

    log_info "Inicializando Husky..."
    $install_cmd --frozen-lockfile 2>/dev/null || $install_cmd 2>/dev/null || true

    local husky_cmd="$install_cmd"
    case "$SELECTED_PKG_MANAGER" in
        bun)   husky_cmd="bunx husky init" ;;
        pnpm)  husky_cmd="pnpm exec husky init" ;;
        npm)   husky_cmd="npm exec husky init" ;;
        *)     husky_cmd="bunx husky init" ;;
    esac

    $husky_cmd 2>/dev/null || log_warn "Husky init falló, continuando..."

    cat > .husky/commit-msg <<EOF
#!/usr/bin/env bash
${SELECTED_PKG_MANAGER} exec commitlint --edit "\$1"
EOF
    chmod +x .husky/commit-msg

    cat > .husky/pre-push <<'EOF'
#!/usr/bin/env bash
LOCAL_BRANCH=$(git rev-parse --abbrev-ref HEAD)
VALID_REGEX="^(feat|fix|hotfix|chore|docs|refactor|test)/[a-z0-9-]+$"

if [[ "$LOCAL_BRANCH" == "main" || "$LOCAL_BRANCH" == "master" ]]; then
    echo "No podés pushear directo a main."
    exit 1
fi

if [[ "$LOCAL_BRANCH" != "develop" ]] && [[ ! $LOCAL_BRANCH =~ $VALID_REGEX ]]; then
    echo "Rama inválida. Usá: tipo/nombre-en-kebab-case"
    exit 1
fi
EOF
    chmod +x .husky/pre-push

    # GGA SIEMPRE en pre-commit si está instalado
    local test_cmd=""
    local pkg_exec_cmd=""
    case "$SELECTED_PKG_MANAGER" in
        bun)
            test_cmd="bun test --run --passWithNoTests"
            pkg_exec_cmd="bun"
            ;;
        pnpm)
            test_cmd="pnpm test --run --passWithNoTests"
            pkg_exec_cmd="pnpm"
            ;;
        npm)
            test_cmd="npm test --run --passWithNoTests"
            pkg_exec_cmd="npm"
            ;;
        *)
            test_cmd="bun test --run --passWithNoTests"
            pkg_exec_cmd="bun"
            ;;
    esac

    if command -v gga &>/dev/null; then
        cat > .husky/pre-commit <<EOF
#!/usr/bin/env bash
${test_cmd}
${pkg_exec_cmd} exec lint-staged
gga run || exit 1
EOF
    else
        cat > .husky/pre-commit <<EOF
#!/usr/bin/env bash
${test_cmd}
${pkg_exec_cmd} exec lint-staged
EOF
    fi
    chmod +x .husky/pre-commit
}

# ============================================================================
# Scripts
# ============================================================================

setup_scripts() {
    log_info "Configurando scripts..."
    
    # Detectar el gestor de paquetes para commands que difieren
    local add_dev_cmd=""
    local pkg_exec_cmd=""
    local run_cmd=""
    
    case "$SELECTED_PKG_MANAGER" in
        bun)
            add_dev_cmd="bun add -d"
            pkg_exec_cmd="bun"
            run_cmd="bun"
            ;;
        pnpm)
            add_dev_cmd="pnpm add -D"
            pkg_exec_cmd="pnpm"
            run_cmd="pnpm"
            ;;
        npm)
            add_dev_cmd="npm install -D"
            pkg_exec_cmd="npm"
            run_cmd="npm"
            ;;
        *)
            add_dev_cmd="bun add -d"
            pkg_exec_cmd="bun"
            run_cmd="bun"
            ;;
    esac
    
    $pkg_exec_cmd pkg set scripts.test="vitest" 2>/dev/null || log_warn "No se pudo configurar scripts.test"
    $pkg_exec_cmd pkg set scripts.db:seed="tsx prisma/seed.ts" 2>/dev/null || log_warn "No se pudo configurar scripts.db:seed"
    $pkg_exec_cmd pkg set scripts.db:reset="prisma migrate reset --force && $run_cmd run db:seed" 2>/dev/null || log_warn "No se pudo configurar scripts.db:reset"
    $pkg_exec_cmd pkg set scripts.release="standard-version" 2>/dev/null || log_warn "No se pudo configurar scripts.release"

    log_info "Configurando overrides para evitar conflictos de dependencias..."
    
    # Los overrides de npm son específicos - solo aplicar para npm/bun
    if [ "$SELECTED_PKG_MANAGER" = "npm" ] || [ "$SELECTED_PKG_MANAGER" = "bun" ]; then
        $pkg_exec_cmd pkg set overrides.babel-plugin-react-compiler="^0.0.0-experimental-71f1f4c6-20240515" 2>/dev/null || log_warn "No se pudo configurar overrides"
    fi
}

# ============================================================================
# Vitest Strict TDD Mode
# ============================================================================

setup_vitest() {
    log_info "Configurando Vitest en Strict TDD Mode..."

    cat > vitest.config.ts <<'EOF'
import { defineConfig, loadEnv } from 'vitest/config'
import path from 'path'

export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), '')
  return {
    test: {
      dir: './src',
      environment: 'node',
      setupFiles: ['./vitest.setup.ts'],
      include: ['**/*.{test,spec}.{ts,tsx}'],
      coverage: {
        provider: 'v8',
        reporter: ['text', 'json', 'html'],
      },
      mode: 'strict',
      passWithNoTests: true,
      watch: false,
      typecheck: {
        enabled: true,
        tsconfig: './tsconfig.json',
      },
    },
    resolve: {
      alias: {
        '@': path.resolve(__dirname, './src'),
      },
    },
  }
})
EOF

    cat > vitest.setup.ts <<'EOF'
import { config } from 'dotenv'
config()
EOF

    log_success "vitest.config.ts creado con Strict TDD Mode"
}

# ============================================================================
# Versionado Automático
# ============================================================================

setup_versioning() {
    log_info "Configurando versionado semántico..."

    # Crear CHANGELOG.md inicial
    cat > CHANGELOG.md <<'EOF'
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - YYYY-MM-DD

### Added

- Initial project setup with Next.js, TypeScript, and chosen architecture

[1.0.0]: https://github.com/USER/PROJECT/releases/tag/v1.0.0
EOF

    # Reemplazar placeholder con datos reales (usar # como delimiter para evitar conflicto con /)
    # Intentar detectar username de GitHub desde remote URL
    local github_user="USER"
    if git remote get-url origin &>/dev/null; then
        local remote_url=$(git remote get-url origin)
        # Extraer username de URLs como:
        # https://github.com/username/repo.git
        # git@github.com:username/repo.git
        # ssh://git@github.com/username/repo
        if [[ "$remote_url" =~ github\.com[/:]([^/]+) ]]; then
            github_user="${BASH_REMATCH[1]}"
        fi
    fi
    if [[ "$github_user" == "USER" ]]; then
        log_warn "No se pudo detectar tu username de GitHub."
        echo "  El CHANGELOG usa USER como placeholder."
        echo "  Configurá tu Git username con: git config --global github.user TU_USUARIO"
    fi
    
    local project_name=$(basename "$(pwd)")
    local today=$(date +%Y-%m-%d)

    # Detectar si es macOS (BSD sed) o Linux (GNU sed)
    # Usamos OSTYPE que ya está definido y es confiable
    if [[ "$OSTYPE" == darwin* ]]; then
        # BSD sed (macOS) - necesita '' después de -i
        sed -i '' "s#USER/PROJECT#${github_user}/${project_name}#g" CHANGELOG.md
        sed -i '' "s#YYYY-MM-DD#${today}#g" CHANGELOG.md
    else
        # GNU sed (Linux)
        sed -i "s#USER/PROJECT#${github_user}/${project_name}#g" CHANGELOG.md
        sed -i "s#YYYY-MM-DD#${today}#g" CHANGELOG.md
    fi

    # Crear VERSION file
    echo "1.0.0" > VERSION

    # Configurar standard-version
    cat > .versionrc <<'EOF'
{
  "types": [
    {"type": "feat", "section": "Features"},
    {"type": "fix", "section": "Bug Fixes"},
    {"type": "chore", "section": "Maintenance"},
    {"type": "docs", "section": "Documentation"},
    {"type": "refactor", "section": "Refactoring"},
    {"type": "test", "section": "Tests"},
    {"type": "perf", "section": "Performance"},
    {"type": "ci", "section": "CI/CD"}
  ],
  "releaseCommitMessageFormat": "chore(release): {{currentTag}}",
  "skip": {
    "bumpFile": false,
    "changelog": false
  }
}
EOF

    # Hacer commit del versionado inicial en main
    git add CHANGELOG.md VERSION .versionrc
    git commit -m "chore: initial version 1.0.0"

    # Crear tag inicial (sin firma, usando -c para scope local)
    git -c tag.gpgsign=false tag -a v1.0.0 -m "Initial release v1.0.0"

    # Crear rama develop desde main
    git checkout -b develop

    log_success "Versionado configurado: v1.0.0"
}

# ============================================================================
# Git ignore
# ============================================================================

enrich_gitignore() {
    log_info "Enriqueciendo .gitignore según el tipo de proyecto..."

    case "$PROJECT_TYPE" in
        frontend-next)
            cat >> .gitignore <<'EOF'

# =========================
# SAI Ecosistema
# =========================
.agent/
plans/
specs/
designs/
design-md/
graphify-out/
.gga

# =========================
# Next.js
# =========================
node_modules/
.next/
out/
*.log
# Notion export artifacts
*.ldes.json
EOF
            ;;
        frontend-vite)
            cat >> .gitignore <<'EOF'

# =========================
# SAI Ecosistema
# =========================
.agent/
plans/
specs/
designs/
design-md/
graphify-out/
.gga

# =========================
# Vite
# =========================
node_modules/
dist/
dist-ssr/
*.local
# Notion export artifacts
*.ldes.json
EOF
            ;;
        backend)
            if [ "$BACKEND_TYPE" = "nestjs" ]; then
                cat >> .gitignore <<'EOF'

# =========================
# SAI Ecosistema
# =========================
.agent/
plans/
specs/
designs/
design-md/
graphify-out/
.gga

# =========================
# NestJS
# =========================
dist/
node_modules/
build/
.env
.env.*
!.env.example
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*
lerna-debug.log*
.DS_Store
*.local
coverage/
.nyc_output/
# Test artifacts
*.lcov
# Notion export artifacts
*.ldes.json
EOF
            else
                cat >> .gitignore <<'EOF'

# =========================
# SAI Ecosistema
# =========================
.agent/
plans/
specs/
designs/
design-md/
graphify-out/
.gga

# =========================
# Go
# =========================
bin/
tmp/
vendor/
*.exe
*.exe~
*.dll
*.so
*.a
*.out
*.test
*.prof
.env
.env.*
!.env.example
.DS_Store
# Test artifacts
coverage.out
coverage.html
# Notion export artifacts
*.ldes.json
EOF
            fi
            ;;
        monorepo)
            cat >> .gitignore <<'EOF'

# =========================
# SAI Ecosistema
# =========================
.agent/
plans/
specs/
designs/
design-md/
graphify-out/
.gga

# =========================
# Monorepo
# =========================
node_modules/
.next/
out/
dist/
build/
apps/web/node_modules/
apps/api/node_modules/
packages/*/node_modules/
*.log
.env
.env.*
!.env.example
.DS_Store
*.local
coverage/
.nyc_output/
*.lcov
# Notion export artifacts
*.ldes.json
EOF
            ;;
    esac
}

# ============================================================================
# Git Workflow Automatizado
# ============================================================================

setup_git_workflow() {
    log_info "Configurando Git workflow automatizado..."

    # Crear script de commit automático
    cat > git-c <<'GITCOMMIT'
#!/usr/bin/env bash
#
# Git Commit Automatizado
# Uso: git-c "mensaje del commit"
#
# Automáticamente:
# 1. Detecta el tipo de cambio según los archivos modificados
# 2. Crea una rama desde develop con el formato: tipo/nombre
# 3. Hace el commit en esa rama
#
# Tipos detectados:
#   feat: nuevos archivos en src/ (excluye components/ui)
#   fix: archivos en src/ con fix, hotfix, patch en nombre
#   chore: config, scripts, deps
#   docs: archivos .md
#   refactor: cambios en archivos existentes sin features
#   test: archivos .test.ts, .spec.ts
#

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# Help
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    printf '%b\n' "${BOLD}Git Commit Automatizado${NC}"
    echo ""
    printf '%b\n' "${CYAN}Uso:${NC}  git-c \"mensaje del commit\""
    echo ""
    printf '%s\n' "El script detecta el tipo de cambio y crea la rama automáticamente."
    echo ""
    printf '%b\n' "${CYAN}Aliases útiles:${NC}"
    printf '%s\n' "  gc  = git-c (commit rápido)"
    printf '%s\n' "  gca = git-c --amend (ammend)"
    printf '%s\n' "  gcp = git-c --push (commit + push)"
    echo ""
    exit 0
fi

# Verificar que estamos en develop
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

# Verificar que la rama develop existe
if ! git show-ref --verify --quiet refs/heads/develop 2>/dev/null; then
    printf '%b\n' "${RED}✗${NC} La rama ${YELLOW}develop${NC} no existe."
    printf '%b\n' "  Ejecutá ${CYAN}git checkout -b develop${NC} para crearla."
    exit 1
fi

# Verificar que estamos en develop
if [[ "$CURRENT_BRANCH" != "develop" ]]; then
    printf '%b\n' "${RED}✗${NC} Necesitás estar en la rama ${YELLOW}develop${NC} para crear un commit."
    printf '%s\n' "  Rama actual: $CURRENT_BRANCH"
    printf '%b\n' "  Ejecutá ${CYAN}git checkout develop${NC} para cambiarte."
    exit 1
fi

# Mensaje obligatorio
if [[ -z "$1" ]]; then
    printf '%b\n' "${RED}✗${NC} Necesitás proporcionar un mensaje de commit."
    printf '%s\n' "  Uso: git-c \"tu mensaje aquí\""
    exit 1
fi

COMMIT_MSG="$1"

# Detectar tipo de cambio
detect_type() {
    # Archivos cambiados
    CHANGED=$(git diff --cached --name-only)
    UNTRACKED=$(git ls-files --others --exclude-standard)

    if echo "$CHANGED $UNTRACKED" | grep -qE "\.(test|spec)\.(ts|tsx|js|jsx)$"; then
        echo "test"
    elif echo "$CHANGED $UNTRACKED" | grep -qE "^docs/|\.md$"; then
        echo "docs"
    elif echo "$CHANGED $UNTRACKED" | grep -qE "^src/"; then
        case "$COMMIT_MSG" in
            fix*|hotfix*|patch*) echo "fix" ;;
            *) echo "feat" ;;
        esac
    elif echo "$CHANGED $UNTRACKED" | grep -qE "^package\.json$|^bun\.lock$|^tsconfig|^next\.config|^prisma/"; then
        echo "chore"
    else
        echo "chore"
    fi
    return 0
}

# Generar nombre de rama desde el mensaje
# Soporta caracteres acentuados, trunca a 50 chars, verifica vacío
slugify() {
    local input="$1"
    local slug
    slug=$(echo "$input" | sed -E 's/[^a-zA-Z0-9áéíóúñüÁÉÍÓÚÑÜ]+/-/g' | tr '[:upper:]' '[:lower:]' | cut -c1-50)
    # Strip leading/trailing hyphens and check not empty
    slug=$(echo "$slug" | sed -E 's/^-+|-+$//g')
    if [[ -z "$slug" ]]; then
        echo "unnamed"
    else
        echo "$slug"
    fi
}

# Ejecutar
TYPE=$(detect_type)
BRANCH_NAME="${TYPE}/$(slugify "$COMMIT_MSG")"

# Verificar que la rama no exista ya
if git show-ref --verify --quiet "refs/heads/$BRANCH_NAME" 2>/dev/null; then
    printf '%b\n' "${RED}✗${NC} La rama ${YELLOW}$BRANCH_NAME${NC} ya existe."
    printf '%b\n' "  Usá ${CYAN}git checkout $BRANCH_NAME${NC} para trabajar en ella,"
    printf '%s\n' "  o usá otro mensaje para crear una nueva rama."
    exit 1
fi

printf '%b\n' "${CYAN}┌─────────────────────────────────────────┐${NC}"
printf '%b\n' "${CYAN}│${NC}  ${BOLD}Git Commit Automatizado${NC}"
printf '%b\n' "${CYAN}└─────────────────────────────────────────┘${NC}"
echo ""
printf '%b\n' "  ${YELLOW}▸ Tipo:${NC}    ${GREEN}$TYPE${NC}"
printf '%b\n' "  ${YELLOW}▸ Rama:${NC}    ${CYAN}$BRANCH_NAME${NC}"
printf '%s\n' "  ${YELLOW}▸ Msg:${NC}     $COMMIT_MSG"
echo ""

# Verificar cambios ( unstaged + staged + untracked )
# Sale si NO hay cambios unstaged Y NO hay cambios staged Y NO hay untracked
if git diff --quiet && git diff --cached --quiet && [[ -z "$(git ls-files --others --exclude-standard)" ]]; then
    printf '%b\n' "  ${RED}✗${NC} No hay cambios para commitear"
    exit 1
fi
printf '%b\n' "  ${GREEN}✓${NC} Hay cambios para commitear"

# Stagear todo
if ! git add -A; then
    printf '%b\n' "  ${RED}✗${NC} git add falló"
    exit 1
fi

# Ejecutar tests (si existen)
if [[ -f "package.json" ]] && grep -q '"test"' package.json; then
    echo ""
    printf '%b\n' "  ${CYAN}▸ Corriendo tests...${NC}"
    # Detectar package manager del proyecto
    local test_cmd="bun"
    if [[ -f "pnpm-lock.yaml" ]]; then
        test_cmd="pnpm"
    elif [[ -f "package-lock.json" ]] && ! [[ -f "bun.lockb" ]]; then
        test_cmd="npm"
    fi
    if ! ${test_cmd} test --run 2>/dev/null; then
        printf '%b\n' "  ${RED}✗${NC} Tests fallaron. Corregí antes de commitear."
        exit 1
    fi
    printf '%b\n' "  ${GREEN}✓${NC} Tests OK"
fi

# Ejecutar GGA si está instalado
if command -v gga &>/dev/null; then
    echo ""
    printf '%b\n' "  ${CYAN}▸ Code review con GGA...${NC}"
    if ! gga run; then
        printf '%b\n' "  ${RED}✗${NC} GGA encontró errores. Corregí antes de commitear."
        exit 1
    fi
    printf '%b\n' "  ${GREEN}✓${NC} GGA OK"
fi

# Crear rama y commit de forma atómica
# Si algo falla después de crear la rama, volvemos a develop y mostramos error
echo ""
printf '%b\n' "  ${CYAN}▸ Creando rama y commit...${NC}"
if ! git checkout -b "$BRANCH_NAME"; then
    printf '%b\n' "  ${RED}✗${NC} No se pudo crear la rama $BRANCH_NAME"
    exit 1
fi
if ! git commit -m "${TYPE}: ${COMMIT_MSG}"; then
    printf '%b\n' "  ${RED}✗${NC} Commit falló. Limpiando rama..."
    git checkout develop 2>/dev/null
    git branch -D "$BRANCH_NAME" 2>/dev/null
    printf '%b\n' "  ${YELLOW}Rama $BRANCH_NAME eliminada.${NC}"
    exit 1
fi

echo ""
printf '%b\n' "${GREEN}✓${NC} Commit creado en rama ${CYAN}$BRANCH_NAME${NC}"
echo ""
printf '%b\n' "${DIM}Próximos pasos:${NC}"
printf '%b\n' "  ${CYAN}git push -u origin $BRANCH_NAME${NC}  # Push y crear PR"
printf '%b\n' "  ${CYAN}git checkout develop${NC}              # Volver a develop"
GITCOMMIT

    chmod +x git-c

    # Configurar git alias - usa ruta absoluta desde el root del repo
    git config alias.c '!bash "$(git rev-parse --show-toplevel)/git-c"'

    log_success "Git workflow configurado"
    echo ""
    log "  ${CYAN}Comandos disponibles:${NC}"
    log "    ${YELLOW}git c${NC} \"mensaje\"   - Commit rápido automático"
    log "    ${YELLOW}git c -h${NC}           - Ver ayuda"
}

# ============================================================================
# Día Cero
# ============================================================================

setup_git_initial() {
    log_info "Ritual de Día Cero..."

    # Verificar y setear git config solo si no existe (global scope)
    if [ -z "$(git config --global user.email)" ]; then
        git config --global user.email "dev@bunker.local"
        log_info "Git email configurado: dev@bunker.local"
    else
        log_info "Git email: $(git config --global user.email) (existente)"
    fi

    if [ -z "$(git config --global user.name)" ]; then
        git config --global user.name "Developer"
        log_info "Git name configurado: Developer"
    else
        log_info "Git name: $(git config --global user.name) (existente)"
    fi

    # Stagear todo para el primer commit (versioning lo hara)
    git add .
}

# ============================================================================
# Graphify
# ============================================================================

setup_graphify() {
    if [ "$USE_GRAPHIFY" = "yes" ]; then
        log_info "Configurando Graphify..."
        if command -v pip3 &>/dev/null; then
            pip3 install -q graphifyy 2>/dev/null || log_warn "graphifyy no se instaló"
            if command -v graphify &>/dev/null; then
                graphify install --platform "$TARGET_AGENT" 2>/dev/null || log_warn "graphify --platform falló"
                log_success "Graphify listo. Ejecutá '/graphify .' cuando quieras."
            else
                log_warn "graphify no está en PATH"
            fi
        else
            log_warn "pip3 no encontrado. Saltando Graphify."
        fi
    fi
}

# ============================================================================
# GGA
# ============================================================================

setup_gga() {
    # GGA SIEMPRE se configura si está disponible en el sistema
    if ! command -v gga &>/dev/null; then
        log_warn "GGA no está instalado. Se recomienda instalar para code review automático."
        echo ""
        log_info "Para instalar GGA:"
        log "  ${CYAN}brew install gentleman-programming/tap/gga${NC}\n"
        echo ""
        return 0
    fi

    log_info "Configurando Gentleman Guardian Angel (GGA)..."

    local default_provider="claude"
    case "$TARGET_AGENT" in
        claude)  default_provider="claude" ;;
        cursor)  default_provider="claude" ;;
        opencode) default_provider="opencode" ;;
        gemini)  default_provider="gemini" ;;
        all)     default_provider="claude" ;;
    esac

    log_info "Inicializando GGA..."
    gga init 2>/dev/null || true

    log_info "Configurando .gga para provider: $default_provider..."
    cat > .gga <<EOF
# Gentleman Guardian Angel Configuration
# https://github.com/Gentleman-Programming/gentleman-guardian-angel

PROVIDER="${default_provider}"
FILE_PATTERNS="*.ts,*.tsx,*.js,*.jsx"
EXCLUDE_PATTERNS="*.test.ts,*.test.tsx,*.spec.ts,*.d.ts,*.stories.tsx,*.config.ts"
RULES_FILE="AGENTS.md"
STRICT_MODE="true"
TIMEOUT="120"
EOF

    log_info "Instalando hook de git..."
    gga install 2>/dev/null || true

    log_success "GGA configurado y activo. Provider: $default_provider"
    log_info "GGA se ejecutará AUTOMÁTICAMENTE en cada commit."
}

# ============================================================================
# Main
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
    confirm_setup

    echo ""
    log_info "Creando proyecto con las opciones seleccionadas..."
    echo ""

    # Dispatcher según tipo de proyecto
    case "$PROJECT_TYPE" in
        frontend-next)
            create_frontend_next
            if [ "$ARCHITECTURE" = "hexagonal" ]; then
                create_hexagonal_structure
            else
                create_hexagonal_structure
            fi
            ;;
        frontend-vite)
            create_frontend_vite
            create_hexagonal_structure
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
            if [ "$ARCHITECTURE" = "hexagonal" ]; then
                create_hexagonal_structure
            else
                create_hexagonal_structure
            fi
            # Aplicar arquitectura también a apps/web
            if [ "$ARCHITECTURE" = "hexagonal" ]; then
                (cd apps/web && create_hexagonal_structure)
            else
                (cd apps/web && create_hexagonal_structure)
            fi
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

main "$@"
