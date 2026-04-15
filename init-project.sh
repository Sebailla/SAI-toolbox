#!/usr/bin/env bash

# ============================================================================
# SAI Project Initializer
# Crea un proyecto Next.js con arquitectura Modular o Hexagonal.
# ============================================================================

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
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
# Selectores interactivos
# ============================================================================

print_banner() {
    echo -e "${CYAN}${BOLD}"
    echo "  ╔═══════════════════════════════════════════════╗"
    echo "  ║   SAI Project Initializer                   ║"
    echo "  ║   Arquitectura Modular o Hexagonal           ║"
    echo "  ╚═══════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
}

select_project_name() {
    echo -e "${BOLD}1/6${NC} - Nombre del proyecto"
    echo -e "${DIM}Ingresá el nombre del proyecto (ej: mi-app, api-rest)${NC}"
    echo ""
    read -r -p "Nombre: " PROJECT_NAME

    if [ -z "$PROJECT_NAME" ]; then
        log_error "El nombre no puede estar vacío"
        select_project_name
    fi
}

select_architecture() {
    echo ""
    echo -e "${BOLD}2/6${NC} - Arquitectura"
    echo -e "${DIM}Elegí el tipo de arquitectura para el proyecto${NC}"
    echo ""
    echo -e "  ${CYAN}1${NC}) Modular Vertical Slicing"
    echo -e "      Estructura por features/módulos con components, services, actions"
    echo ""
    echo -e "  ${CYAN}2${NC}) Hexagonal (Clean Architecture)"
    echo -e "      Domain → Application → Infrastructure (separación extrema)"
    echo ""
    read -r -p "Elegí [1-2]: " ARCH_CHOICE

    case "$ARCH_CHOICE" in
        1) ARCHITECTURE="modular" ;;
        2) ARCHITECTURE="hexagonal" ;;
        *) log_warn "Opción inválida. Usando Modular."; ARCHITECTURE="modular" ;;
    esac
    log_success "Arquitectura: $ARCHITECTURE"
}

select_agent() {
    echo ""
    echo -e "${BOLD}3/6${NC} - Agente de IA"
    echo -e "${DIM}Elegí el agente de IA principal para este proyecto${NC}"
    echo ""
    echo -e "  ${CYAN}1${NC}) OpenCode"
    echo -e "  ${CYAN}2${NC}) Claude Code"
    echo -e "  ${CYAN}3${NC}) Cursor"
    echo -e "  ${CYAN}4${NC}) Gemini CLI"
    echo -e "  ${CYAN}5${NC}) Todos (inyecta reglas para todos)"
    echo ""
    read -r -p "Elegí [1-5]: " AGENT_CHOICE

    case "$AGENT_CHOICE" in
        1) TARGET_AGENT="opencode" ;;
        2) TARGET_AGENT="claude" ;;
        3) TARGET_AGENT="cursor" ;;
        4) TARGET_AGENT="gemini" ;;
        5) TARGET_AGENT="all" ;;
        *) log_warn "Opción inválida. Usando OpenCode."; TARGET_AGENT="opencode" ;;
    esac
    log_success "Agente: $TARGET_AGENT"
}

select_graphify() {
    echo ""
    echo -e "${BOLD}4/6${NC} - Graphify (Knowledge Graph)"
    echo -e "${DIM}Graphify genera un grafo de conocimiento del proyecto${NC}"
    echo ""
    echo -e "  ${CYAN}1${NC}) Sí - Habilitar Graphify"
    echo -e "  ${CYAN}2${NC}) No - Omitir Graphify"
    echo ""
    read -r -p "Elegí [1-2]: " GRAPHIFY_CHOICE

    case "$GRAPHIFY_CHOICE" in
        1) USE_GRAPHIFY="yes" ;;
        2) USE_GRAPHIFY="no" ;;
        *) USE_GRAPHIFY="no" ;;
    esac
    if [ "$USE_GRAPHIFY" = "yes" ]; then
        log_success "Graphify: habilitado"
    else
        log_info "Graphify: omitido"
    fi
}

select_gga() {
    echo ""
    echo -e "${BOLD}5/6${NC} - GGA (Gentleman Guardian Angel)"
    echo -e "${DIM}Code review automático con IA en cada commit${NC}"
    echo ""
    echo -e "  ${CYAN}1${NC}) Sí - Habilitar GGA"
    echo -e "  ${CYAN}2${NC}) No - Omitir GGA"
    echo ""
    read -r -p "Elegí [1-2]: " GGA_CHOICE

    case "$GGA_CHOICE" in
        1) USE_GGA="yes" ;;
        2) USE_GGA="no" ;;
        *) USE_GGA="no" ;;
    esac
    if [ "$USE_GGA" = "yes" ]; then
        log_success "GGA: habilitado"
    else
        log_info "GGA: omitido"
    fi
}

confirm_setup() {
    echo ""
    echo -e "${BOLD}6/6${NC} - Confirmar configuración"
    echo ""
    echo -e "  ${CYAN}Proyecto:${NC}      $PROJECT_NAME"
    echo -e "  ${CYAN}Arquitectura:${NC}   $ARCHITECTURE"
    echo -e "  ${CYAN}Agente:${NC}         $TARGET_AGENT"
    echo -e "  ${CYAN}Graphify:${NC}       $USE_GRAPHIFY"
    echo -e "  ${CYAN}GGA:${NC}            $USE_GGA"
    echo ""
    read -r -p "Confirmar y crear proyecto? [s/n]: " CONFIRM

    if [[ ! "$CONFIRM" =~ ^[Ss]$ ]]; then
        log_info "Operación cancelada."
        exit 0
    fi
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
        exit 1
    fi
}

# ============================================================================
# Crear proyecto
# ============================================================================

create_project() {
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
}

# ============================================================================
# Estructura Modular
# ============================================================================

create_modular_structure() {
    log_info "Creando estructura Modular Vertical Slicing..."

    mkdir -p src/core/lib src/core/types src/core/hooks
    mkdir -p src/modules/example/components src/modules/example/services
    touch src/modules/example/actions.ts src/modules/example/types.ts src/modules/example/index.ts
    mkdir -p .docs .agent/skills plans specs designs .github/workflows
}

# ============================================================================
# Estructura Hexagonal (Clean Architecture)
# ============================================================================

create_hexagonal_structure() {
    log_info "Creando estructura Hexagonal (Clean Architecture)..."

    # Domain - Core business logic (no external dependencies)
    mkdir -p src/domain/entities
    mkdir -p src/domain/value-objects
    mkdir -p src/domain/services
    mkdir -p src/domain/events
    mkdir -p src/domain/exceptions
    mkdir -p src/domain/interfaces

    # Application - Use cases and application services
    mkdir -p src/application/use-cases
    mkdir -p src/application/dto
    mkdir -p src/application/ports/in
    mkdir -p src/application/ports/out

    # Infrastructure - External adapters
    mkdir -p src/infrastructure/persistence/repositories
    mkdir -p src/infrastructure/http/controllers
    mkdir -p src/infrastructure/http/middleware
    mkdir -p src/infrastructure/queue
    mkdir -p src/infrastructure/external

    # Shared - Utilities
    mkdir -p src/shared/constants
    mkdir -p src/shared/types
    mkdir -p src/shared/utils

    # API routes (Next.js App Router)
    mkdir -p src/app/api/example

    # Ejemplo de entidad
    cat > src/domain/entities/Example.ts <<'EOF'
// Domain Entity - Sin dependencias externas
// Esta clase representa un concepto del dominio

export interface ExampleProps {
  id: string;
  name: string;
  createdAt: Date;
}

export class Example {
  constructor(private props: ExampleProps) {}

  get id(): string { return this.props.id; }
  get name(): string { return this.props.name; }
  get createdAt(): Date { return this.props.createdAt; }

  // Domain methods
  updateName(name: string): void {
    if (!name || name.trim().length === 0) {
      throw new Error('Name cannot be empty');
    }
    this.props.name = name.trim();
  }
}
EOF

    # Interfaz de repositorio (puerto de salida)
    cat > src/domain/interfaces/IExampleRepository.ts <<'EOF'
// Puerto de salida - Interface para repositorio
import { Example } from '../entities/Example';

export interface IExampleRepository {
  findById(id: string): Promise<Example | null>;
  findAll(): Promise<Example[]>;
  save(example: Example): Promise<void>;
  delete(id: string): Promise<void>;
}
EOF

    # Use case de ejemplo
    cat > src/application/use-cases/CreateExampleUseCase.ts <<'EOF'
// Caso de uso - Lógica de aplicación
// Orquesta el flujo entre entidades y repositorios

import { Example, ExampleProps } from '../../domain/entities/Example';

export interface CreateExampleInput {
  name: string;
}

export interface IExampleRepository {
  save(example: Example): Promise<void>;
}

export class CreateExampleUseCase {
  constructor(private repository: IExampleRepository) {}

  async execute(input: CreateExampleInput): Promise<Example> {
    // Validaciones de aplicación
    if (!input.name || input.name.trim().length === 0) {
      throw new Error('Name is required');
    }

    // Crear entidad
    const exampleProps: ExampleProps = {
      id: crypto.randomUUID(),
      name: input.name.trim(),
      createdAt: new Date(),
    };

    const example = new Example(exampleProps);

    // Persistir
    await this.repository.save(example);

    return example;
  }
}
EOF

    mkdir -p .docs .agent/skills plans specs designs .github/workflows
}

# ============================================================================
# GitHub Actions
# ============================================================================

setup_github_actions() {
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

## Arquitectura: Hexagonal (Clean Architecture)
- **Domain** (`src/domain/`): Entidades, value objects, servicios de dominio. SIN dependencias externas.
- **Application** (`src/application/`): Use cases, DTOs, puertos de entrada/salida.
- **Infrastructure** (`src/infrastructure/`): Adaptadores externos (BD, HTTP, queues).
- **Shared** (`src/shared/`): Utilidades compartidas.

## Reglas de Dependencias (Ley de Dependencias)
- Domain NO puede depender de Application ni Infrastructure.
- Application puede depender de Domain.
- Infrastructure implementa las interfaces de Domain/Application.
- Shared puede ser usado por todos, pero idealmente no contiene lógica de negocio.

## Estándares
- Zod para validación de esquemas.
- Prisma para todas las operaciones de BD.
- Tailwind CSS v4 para estilos.
- Tests unitarios con Vitest.
- Conventional Commits estrictos.

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
- Conventional Commits estrictos.

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
}

# ============================================================================
# Scripts
# ============================================================================

setup_scripts() {
    log_info "Configurando scripts..."
    npm pkg set scripts.test="vitest" 2>/dev/null || true
    npm pkg set scripts.db:seed="tsx prisma/seed.ts" 2>/dev/null || true
    npm pkg set scripts.db:reset="prisma migrate reset --force && bun run db:seed" 2>/dev/null || true
    npm pkg set scripts.release="standard-version" 2>/dev/null || true
}

# ============================================================================
# Git ignore
# ============================================================================

setup_gitignore() {
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
}

# ============================================================================
# Día Cero
# ============================================================================

setup_git_initial() {
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
    if [ "$USE_GGA" != "yes" ]; then
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

    if ! command -v gga &>/dev/null; then
        log_warn "GGA no está instalado en el sistema."
        echo ""
        log_info "Para instalar GGA:"
        echo -e "  ${CYAN}brew install gentleman-programming/tap/gga${NC}"
        echo ""
        return 0
    fi

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
STRICT_MODE="false"
TIMEOUT="120"
EOF

    log_info "Instalando hook de git..."
    gga install 2>/dev/null || true

    log_success "GGA configurado. Provider: $default_provider"
}

# ============================================================================
# Main
# ============================================================================

main() {
    print_banner
    check_dependencies
    select_project_name
    select_architecture
    select_agent
    select_graphify
    select_gga
    confirm_setup

    echo ""
    log_info "Creando proyecto con las opciones seleccionadas..."
    echo ""

    create_project

    if [ "$ARCHITECTURE" = "hexagonal" ]; then
        create_hexagonal_structure
    else
        create_modular_structure
    fi

    setup_github_actions
    setup_vscode
    setup_agents_md
    setup_agent_rules
    setup_skills
    setup_husky
    setup_scripts
    setup_gitignore
    setup_git_initial
    setup_graphify
    setup_gga

    echo ""
    log_success "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_success "  PROYECTO DESPLEGADO: $PROJECT_NAME"
    log_success "  Arquitectura: $ARCHITECTURE"
    log_success "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    log_info "Próximos pasos:"
    echo "  cd $PROJECT_NAME"
    echo "  bun install"
    echo "  git checkout -b feat/nombre-tarea"
    echo ""

    SUCCESS=1
}

main "$@"
