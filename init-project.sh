#!/usr/bin/env bash

# ============================================================================
# SAI Project Initializer
# Crea un proyecto Next.js con el stack SAI, sin dependencias externas.
# ============================================================================

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

log_info()    { echo -e "${CYAN}${BOLD}[INFO]${NC}   $*"; }
log_success() { echo -e "${GREEN}${BOLD}[OK]${NC}     $*"; }
log_warn()    { echo -e "${YELLOW}${BOLD}[WARN]${NC}  $*"; }
log_error()   { echo -e "${RED}${BOLD}[ERROR]${NC}  $*" >&2; }

ORIGINAL_DIR=$(pwd)
SUCCESS=0

cleanup() {
    if [ "$SUCCESS" -eq 0 ]; then
        echo -e "${RED}${BOLD}[FATAL]${NC} El script no terminó correctamente. Deshaciendo..."
        if [ -n "$PROJECT_NAME" ] && [ -d "$ORIGINAL_DIR/$PROJECT_NAME" ]; then
            log_warn "Borrando directorio a medio crear: $PROJECT_NAME"
            rm -rf "$ORIGINAL_DIR/$PROJECT_NAME"
        fi
        exit 1
    fi
}

trap cleanup EXIT INT TERM

# ============================================================================
# Help
# ============================================================================

show_help() {
    cat <<EOF
${BOLD}SAI Project Initializer${NC}

Usage: ./init-project.sh <nombre-proyecto> [opciones]

Options:
  --agent AGENTE   Agente de IA principal: opencode, claude, cursor, gemini, all
  --graphify        Habilitar Graphify (knowledge graph)
  --gga             Habilitar Gentleman Guardian Angel (revisión de código con IA)
  -h, --help       Mostrar esta ayuda

El script crea un proyecto Next.js completo con:
  - Next.js + TypeScript + Tailwind CSS v4 + App Router
  - Prisma + dependencias del stack SAI
  - Husky + Commitlint + versionado semántico
  - Skills de documentación y planificación para agentes
  - Graphify (opcional)
  - GGA (opcional)

No requiere sai ni gentle-ai preinstalado.

Ejemplos:
  ./init-project.sh mi-proyecto
  ./init-project.sh mi-proyecto --agent claude --graphify --gga
EOF
}

# ============================================================================
# Validaciones
# ============================================================================

check_dependencies() {
    local missing=()
    for cmd in bun git; do
        if ! command -v "$cmd" &>/dev/null; then
            missing+=("$cmd")
        fi
    done
    if [ ${#missing[@]} -gt 0 ]; then
        log_error "Faltan dependencias: ${missing[*]}"
        log_error "Instalalas antes de continuar."
        SUCCESS=1
        exit 1
    fi
}

# ============================================================================
# Parseo de argumentos
# ============================================================================

PROJECT_NAME=""
TARGET_AGENT="opencode"
USE_GRAPHIFY="no"
USE_GGA="no"

while [ $# -gt 0 ]; do
    case "$1" in
        --agent)
            [ $# -lt 2 ] && { log_error "--agent requiere valor"; SUCCESS=1; exit 1; }
            TARGET_AGENT="$2"; shift 2
            ;;
        --graphify)
            USE_GRAPHIFY="yes"; shift
            ;;
        --gga)
            USE_GGA="yes"; shift
            ;;
        -h|--help)
            show_help; exit 0
            ;;
        *)
            if [ -z "$PROJECT_NAME" ]; then
                PROJECT_NAME="$1"; shift
            else
                log_error "Opción desconocida: $1"; SUCCESS=1; exit 1
            fi
            ;;
    esac
done

if [ -z "$PROJECT_NAME" ]; then
    log_error "Falta el nombre del proyecto. Uso: ./init-project.sh <nombre>"
    SUCCESS=1
    exit 1
fi

# Pre-flight
check_dependencies
SUCCESS=0

# ============================================================================
# Crear proyecto
# ============================================================================

log_info "Creando proyecto: $PROJECT_NAME..."
mkdir -p "$PROJECT_NAME"
cd "$PROJECT_NAME"

log_info "Inicializando Git (rama main)..."
git init -q -b main

log_info "Scaffold Next.js (TypeScript, Tailwind v4, App Router, src/)..."
bunx create-next-app@latest . \
    --typescript \
    --tailwind \
    --eslint \
    --app \
    --src-dir \
    --import-alias "@/*" \
    --use-bun \
    --skip-install \
    --yes

log_info "Instalando dependencias del stack..."
bun add @prisma/client@latest lucide-react@latest clsx@latest tailwind-merge@latest \
    date-fns@latest zod@latest react-hot-toast@latest ioredis@latest \
    bcryptjs@latest jsonwebtoken@latest

bun add -d prisma@latest vitest@latest @testing-library/react@latest \
    @testing-library/dom@latest jsdom@latest @playwright/test@latest \
    husky@latest lint-staged@latest tsx@latest @types/node@latest \
    @types/react@latest @types/react-dom@latest @types/bcryptjs@latest \
    @types/jsonwebtoken@latest @commitlint/cli@latest \
    @commitlint/config-conventional@latest standard-version@latest

log_info "Inicializando Prisma..."
bunx prisma init

# ============================================================================
# Estructura de carpetas
# ============================================================================

log_info "Creando estructura modular..."
mkdir -p src/core/lib src/core/types src/core/hooks
mkdir -p src/modules example/components src/modules/example/services
touch src/modules/example/actions.ts src/modules/example/types.ts src/modules/example/index.ts
mkdir -p .docs .agent/skills plans specs designs .github/workflows

# ============================================================================
# GitHub Actions (Release + Health Check)
# ============================================================================

log_info "Configurando GitHub Actions..."
mkdir -p .github/workflows
cat > .github/workflows/release.yml <<'EOF'
name: Release on Main

on:
  push:
    branches:
      - main

jobs:
  release:
    name: "Release"
    runs-on: ubuntu-latest
    permissions:
      contents: write
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
          token: ${{ secrets.GITHUB_TOKEN }}
      - uses: oven-sh/setup-bun@v2
      - run: |
          git config --global user.name 'github-actions[bot]'
          git config --global user.email 'github-actions[bot]@users.noreply.github.com'
          bun run release
          git push --follow-tags origin main

  health-gate:
    name: "Health Check"
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
EOF

# ============================================================================
# VSCode settings
# ============================================================================

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

# ============================================================================
# AGENTS.md (reglas para la IA)
# ============================================================================

log_info "Generando AGENTS.md..."
cat > AGENTS.md <<'EOF'
# Project Rules

## Arquitectura: Modular Vertical Slicing
- Cada módulo en `src/modules/<nombre>/` debe tener: `components/`, `services/`, `actions.ts`, `types.ts`, `index.ts`.
- **Services**: Lógica de negocio pura y acceso a datos (Prisma).
- **Actions**: Server Actions para validación (Zod) y orquestación. Siempre usar `'use server'`.
- **Components**: UI pura. Delegar lógica compleja a Services o Actions.
- Lógica compartida global en `src/core/`. UI compartida genérica en `src/components/ui/`.

## Estándares
- Zod para validación de esquemas.
- Prisma para todas las operaciones de BD.
- Tailwind CSS v4 para estilos.
- Tests unitarios con Vitest.
- Tests E2E críticos con Playwright.
- Conventional Commits estrictos.

## Branch Naming
Formato: `tipo/nombre-en-kebab-case`. Tipos válidos: `feat, fix, hotfix, chore, docs, refactor, test`.

## Comunicación
- Idioma del código: Inglés.
- Comentarios y documentación: Español.
- Feedback del agente: Español Rioplatense (voseo).

## 🛡️ Protocolo de Actuación
- El orquestador DEBE limitarse a guiar. No debe escribir código directamente.
- Toda acción técnica DEBE ser delegada a subagentes.
- Cero suposiciones: siempre PREGUNTAR antes de inferir.
- Confirmación constante antes de cambios significativos.
- Rama de partida siempre `develop` (no main).

## 🧠 Knowledge Graph (Graphify)
- Si existe `graphify-out/`, leer `graphify-out/GRAPH_REPORT.md` antes de modificar arquitectura.

## Calidad
- Toda feature nueva debe tener tests unitarios.
- Flujos críticos deben tener tests E2E.
- Conventional Commits estrictos.
EOF

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

setup_agent_rules

# ============================================================================
# Skills de documentación
# ============================================================================

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

# ============================================================================
# Husky + Commitlint + Versionado
# ============================================================================

log_info "Configurando Husky y Commitlint..."
bunx husky init

cat > commitlint.config.mjs <<'EOF'
export default { extends: ['@commitlint/config-conventional'] };
EOF

cat > .husky/commit-msg <<'EOF'
bunx --no -- commitlint --edit $1
EOF

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

cat > .husky/pre-commit <<'EOF'
bun test
bunx lint-staged
EOF

# ============================================================================
# Scripts en package.json
# ============================================================================

log_info "Configurando scripts..."
npm pkg set scripts.test="vitest" 2>/dev/null || true
npm pkg set scripts.db:seed="tsx prisma/seed.ts" 2>/dev/null || true
npm pkg set scripts.db:reset="prisma migrate reset --force && bun run db:seed" 2>/dev/null || true
npm pkg set scripts.release="standard-version" 2>/dev/null || true

# ============================================================================
# Git ignore
# ============================================================================

log_info "Enriqueciendo .gitignore..."
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
EOF

# ============================================================================
# Día Cero: primer commit + versión
# ============================================================================

log_info "Ritual de Día Cero..."

if [ -z "$(git config --global user.email)" ]; then
    git config user.email "dev@bunker.local"
fi
if [ -z "$(git config --global user.name)" ]; then
    git config user.name "Developer"
fi

git add .
git commit -m "chore: initial project setup" -q --no-verify

bunx standard-version --first-release -q --no-verify 2>/dev/null || true

log_info "Creando rama develop..."
git checkout -b develop -q

# ============================================================================
# Graphify (opcional)
# ============================================================================

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

# ============================================================================
# GGA - Gentleman Guardian Angel (opcional)
# ============================================================================

setup_gga() {
    log_info "Configurando Gentleman Guardian Angel (GGA)..."

    # Detectar provider por defecto según agente
    local default_provider="claude"
    case "$TARGET_AGENT" in
        claude)  default_provider="claude" ;;
        cursor)  default_provider="claude" ;;
        opencode) default_provider="opencode" ;;
        gemini)  default_provider="gemini" ;;
        all)     default_provider="claude" ;;
    esac

    # 1. Instalar gga si no existe
    if ! command -v gga &>/dev/null; then
        log_warn "GGA no está instalado en el sistema."
        echo ""
        log_info "Para instalar GGA, ejecutá uno de estos comandos:"
        echo ""
        echo -e "  ${CYAN}# Opción 1: Homebrew (recomendado)${NC}"
        echo -e "  brew install gentleman-programming/tap/gga"
        echo ""
        echo -e "  ${CYAN}# Opción 2: Instalación manual${NC}"
        echo -e "  git clone https://github.com/Gentleman-Programming/gentleman-guardian-angel.git"
        echo -e "  cd gentleman-guardian-angel && ./install.sh"
        echo ""

        # Intentar instalar vía script si hay curl
        if command -v curl &>/dev/null; then
            echo -e "  ${YELLOW}¿Querés que intente instalar GGA automáticamente? [s/n]${NC}"
            read -r -p "" answer
            if [[ "$answer" =~ ^[Ss]$ ]]; then
                log_info "Instalando GGA vía Homebrew..."
                if command -v brew &>/dev/null; then
                    brew install gentleman-programming/tap/gga 2>/dev/null || {
                        log_error "Falló la instalación vía Homebrew."
                        log_info "Instalá GGA manualmente y luego ejecutá 'gga init' y 'gga install'"
                    }
                else
                    log_error "Homebrew no está instalado."
                    log_info "Instalá GGA manualmente: https://github.com/Gentleman-Programming/gentleman-guardian-angel"
                fi
            fi
        fi
    fi

    # 2. Verificar si gga está disponible después de la instalación
    if ! command -v gga &>/dev/null; then
        log_warn "GGA no está disponible. Saltando configuración."
        log_info "Cuando esté instalado, ejecutá: gga init && gga install"
        return 0
    fi

    # 3. Inicializar GGA en el proyecto
    log_info "Inicializando GGA..."
    gga init 2>/dev/null || {
        log_warn "gga init falló, creando .gga manualmente..."
    }

    # 4. Crear .gga con configuración para el agente seleccionado
    log_info "Configurando .gga para provider: $default_provider..."
    cat > .gga <<EOF
# Gentleman Guardian Angel Configuration
# https://github.com/Gentleman-Programming/gentleman-guardian-angel

# AI Provider (required)
# Opciones: claude, gemini, codex, opencode, ollama, lmstudio, github
PROVIDER="${default_provider}"

# File patterns to include in review (comma-separated globs)
FILE_PATTERNS="*.ts,*.tsx,*.js,*.jsx"

# Patterns to exclude from review
EXCLUDE_PATTERNS="*.test.ts,*.test.tsx,*.spec.ts,*.d.ts,*.stories.tsx,*.config.ts"

# File containing code review rules
RULES_FILE="AGENTS.md"

# Strict mode: fail if AI response is ambiguous
STRICT_MODE="false"

# Timeout per file (seconds)
TIMEOUT="120"
EOF

    # 5. Instalar hook de pre-commit
    log_info "Instalando hook de git..."
    gga install 2>/dev/null || {
        log_warn "gga install falló. Podés ejecutarlo manualmente después."
    }

    log_success "GGA configurado. Provider: $default_provider"
    echo ""
    log_info "Próximos pasos:"
    echo "  1. Editá .gga para ajustar el provider si es necesario"
    echo "  2. Asegurate de que tu provider CLI esté en PATH (claude, gemini, etc.)"
    echo "  3. GGA revisará automáticamente los archivos en cada commit"
}

if [ "$USE_GGA" = "yes" ]; then
    setup_gga
fi

# ============================================================================
# ¡Listo!
# ============================================================================

log_success "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_success "  PROYECTO DESPLEGADO: $PROJECT_NAME"
log_success "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo ""
log_info "Próximos pasos:"
echo "  cd $PROJECT_NAME"
echo "  bun install"
echo "  git checkout -b feat/nombre-tarea"
echo ""

SUCCESS=1
