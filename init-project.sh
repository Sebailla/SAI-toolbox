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
    # Siempre hacer exit 1 en cleanup por error
    exit 1
}

trap cleanup EXIT INT TERM

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

select_project_name() {
    echo ""
    log "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    log "${BOLD}${CYAN}  ▸ Paso 1 de 5 ─── Nombre del proyecto${NC}"
    log "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    log "${DIM}Ingresá el nombre para tu proyecto (sin espacios)${NC}"
    echo ""
    read -r -p "   └─►  " PROJECT_NAME
    echo ""

    if [ -z "$PROJECT_NAME" ]; then
        log_error "El nombre no puede estar vacío"
        select_project_name
        return
    fi

    # Sanitizar nombre: solo letras, números, guiones y guiones bajos
    if [[ ! "$PROJECT_NAME" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        log_error "Solo letras, números, guiones (-) y guiones bajos (_)"
        select_project_name
        return
    fi

    # Verificar que no exista el directorio
    if [ -d "$PROJECT_NAME" ]; then
        log_error "El directorio '$PROJECT_NAME' ya existe. Elegí otro nombre."
        select_project_name
        return
    fi

    log "${GREEN}  ✓${NC} Proyecto: ${BOLD}$PROJECT_NAME${NC}"
}

select_architecture() {
    echo ""
    log "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    log "${BOLD}${CYAN}  ▸ Paso 2 de 5 ─── Arquitectura${NC}"
    log "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    log "${DIM}Elegí el tipo de arquitectura para tu proyecto${NC}"
    echo ""
    log "${YELLOW}  ┌─────────────────────────────────────────────┐${NC}"
    log "${YELLOW}  │${NC}  ${BOLD}1${NC}) ${GREEN}Modular Vertical Slicing${NC}                    ${YELLOW}│${NC}"
    log "${YELLOW}  │${NC}     Estructura por features/módulos           ${YELLOW}│${NC}"
    log "${YELLOW}  │${NC}     components, services, actions              ${YELLOW}│${NC}"
    log "${YELLOW}  └─────────────────────────────────────────────┘${NC}"
    echo ""
    log "${YELLOW}  ┌─────────────────────────────────────────────┐${NC}"
    log "${YELLOW}  │${NC}  ${BOLD}2${NC}) ${MAGENTA}Hexagonal (Clean Architecture)${NC}             ${YELLOW}│${NC}"
    log "${YELLOW}  │${NC}     Domain → Application → Infrastructure     ${YELLOW}│${NC}"
    log "${YELLOW}  │${NC}     Separación extrema del negocio            ${YELLOW}│${NC}"
    log "${YELLOW}  └─────────────────────────────────────────────┘${NC}"
    echo ""
    read -r -p "   └─►  " ARCH_CHOICE
    echo ""

    case "$ARCH_CHOICE" in
        1) ARCHITECTURE="modular" ;;
        2) ARCHITECTURE="hexagonal" ;;
        *) log_warn "Opción inválida. Usando Modular."; ARCHITECTURE="modular" ;;
    esac
    log "${GREEN}  ✓${NC} Arquitectura: ${BOLD}$ARCHITECTURE${NC}"
}

select_agent() {
    echo ""
    log "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    log "${BOLD}${CYAN}  ▸ Paso 3 de 5 ─── Agente de IA${NC}"
    log "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    log "${DIM}Elegí el agente de IA principal para este proyecto${NC}"
    echo ""
    log "${YELLOW}  ┌─────────────────────────────────────────────┐${NC}"
    log "${YELLOW}  │${NC}  ${BOLD}1${NC}) ${CYAN}OpenCode${NC}                                  ${YELLOW}│${NC}"
    log "${YELLOW}  │${NC}  ${BOLD}2${NC}) ${CYAN}Claude Code${NC}                              ${YELLOW}│${NC}"
    log "${YELLOW}  │${NC}  ${BOLD}3${NC}) ${CYAN}Cursor${NC}                                   ${YELLOW}│${NC}"
    log "${YELLOW}  │${NC}  ${BOLD}4${NC}) ${CYAN}Gemini CLI${NC}                               ${YELLOW}│${NC}"
    log "${YELLOW}  │${NC}  ${BOLD}5${NC}) ${CYAN}Todos${NC} (inyecta reglas para todos)          ${YELLOW}│${NC}"
    log "${YELLOW}  └─────────────────────────────────────────────┘${NC}"
    echo ""
    read -r -p "   └─►  " AGENT_CHOICE
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
    log "${BOLD}${CYAN}  ▸ Paso 4 de 5 ─── Graphify (Knowledge Graph)${NC}"
    log "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    log "${DIM}Graphify genera un grafo de conocimiento del proyecto${NC}"
    echo ""
    log "${YELLOW}  ┌─────────────────────────────────────────────┐${NC}"
    log "${YELLOW}  │${NC}  ${BOLD}1${NC}) ${GREEN}Sí - Habilitar Graphify${NC}                    ${YELLOW}│${NC}"
    log "${YELLOW}  │${NC}  ${BOLD}2${NC}) ${RED}No - Omitir Graphify${NC}                        ${YELLOW}│${NC}"
    log "${YELLOW}  └─────────────────────────────────────────────┘${NC}"
    echo ""
    read -r -p "   └─►  " GRAPHIFY_CHOICE
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
    log "${BOLD}${CYAN}  ▸ Paso 5 de 5 ─── Confirmar${NC}"
    log "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    log "${DIM}Resumen de tu proyecto:${NC}"
    echo ""
    log "${YELLOW}  ┌─────────────────────────────────────────────┐${NC}"
    log "${YELLOW}  │${NC}  ${BOLD}Proyecto:${NC}      ${GREEN}$PROJECT_NAME${NC}                       ${YELLOW}│${NC}"
    log "${YELLOW}  │${NC}  ${BOLD}Arquitectura:${NC}   ${CYAN}$ARCHITECTURE${NC}                      ${YELLOW}│${NC}"
    log "${YELLOW}  │${NC}  ${BOLD}Agente:${NC}         ${MAGENTA}$TARGET_AGENT${NC}                        ${YELLOW}│${NC}"
    log "${YELLOW}  │${NC}  ${BOLD}Graphify:${NC}       ${WHITE}$USE_GRAPHIFY${NC}                         ${YELLOW}│${NC}"
    if command -v gga &>/dev/null; then
        log "${YELLOW}  │${NC}  ${BOLD}GGA:${NC}            ${GREEN}Automático${NC}                        ${YELLOW}│${NC}"
    fi
    log "${YELLOW}  └─────────────────────────────────────────────┘${NC}"
    echo ""
    read -r -p "   └─►  Confirmar y crear proyecto? [${GREEN}s${NC}/${RED}n${NC}]: " CONFIRM
    echo ""

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
# Timeout portable (macOS no tiene timeout, usa gtimeout o perl)
# ============================================================================

run_with_timeout() {
    local seconds=$1
    shift
    local cmd=("$@")

    # Intentar timeout nativo (Linux)
    if command -v timeout &>/dev/null; then
        timeout "${seconds}s" "${cmd[@]}"
        return $?
    fi

    # Intentar gtimeout (macOS con GNU coreutils)
    if command -v gtimeout &>/dev/null; then
        gtimeout "${seconds}s" "${cmd[@]}"
        return $?
    fi

    # Intentar timeout de perl (macOS)
    if command -v perl &>/dev/null; then
        perl -e '
            use IPC::Open3;
            use Symbol qw(gensym);
            my $sigalrm = sub { die "timeout\n" };
            my $secs = shift;
            $SIG{ALRM} = $sigalrm;
            alarm($secs);
            eval {
                my $pid = open3(my $in, my $out, my $err = gensym, @_);
                waitpid($pid, 0);
                alarm(0);
                exit $? >> 8;
            };
            if ($@ eq "timeout\n") { exit 124 }
            die $@ if $@;
        ' "${seconds}" "${cmd[@]}"
        return $?
    fi

    # Si nada funciona, ejecutar sin timeout
    "${cmd[@]}"
}

# ============================================================================
# Crear proyecto
# ============================================================================

create_project() {
    log_info "Creando proyecto: $PROJECT_NAME..."

    # Crear directorio con verificación
    if ! mkdir -p "$PROJECT_NAME"; then
        log_error "No se pudo crear el directorio $PROJECT_NAME"
        exit 1
    fi

    # Entrar al directorio con verificación
    if ! cd "$PROJECT_NAME"; then
        log_error "No se pudo acceder al directorio $PROJECT_NAME"
        exit 1
    fi

    # Marcar que el directorio fue creado (para cleanup)
    PROJECT_CREATED=1

    log_info "Inicializando Git (rama main)..."
    git init -q -b main

    log_info "Scaffold Next.js (TypeScript, Tailwind v4, App Router, src/)..."
    run_with_timeout 300 bunx create-next-app@latest . \
        --typescript \
        --tailwind \
        --eslint \
        --app \
        --src-dir \
        --import-alias "@/*" \
        --use-bun \
        --skip-install \
        --yes || { log_error "create-next-app falló"; exit 1; }

    log_info "Instalando dependencias del stack..."
    bun add @prisma/client@latest lucide-react@latest clsx@latest tailwind-merge@latest \
        date-fns@latest zod@latest react-hot-toast@latest ioredis@latest \
        bcryptjs@latest jsonwebtoken@latest || log_warn "Algunas dependencias no se instalaron"

    bun add -d prisma@latest vitest@latest @testing-library/react@latest \
        @testing-library/dom@latest jsdom@latest @playwright/test@latest \
        husky@latest lint-staged@latest tsx@latest @types/node@latest \
        @types/react@latest @types/react-dom@latest @types/bcryptjs@latest \
        @types/jsonwebtoken@latest @commitlint/cli@latest \
        @commitlint/config-conventional@latest standard-version@latest \
        || log_warn "Algunas devDependencies no se instalaron"

    log_info "Inicializando Prisma..."
    bunx prisma init || log_warn "Prisma init falló"
}

# ============================================================================
# Environment Template
# ============================================================================

setup_env_template() {
    log_info "Creando .env.template para PostgreSQL..."

    cat > .env.template <<'EOF'
# Database
DATABASE_URL="postgresql://USER:PASSWORD@HOST:5432/DATABASE?schema=public"

# Auth
JWT_SECRET="your-super-secret-jwt-token-change-in-production"
JWT_EXPIRES_IN="7d"

# App
APP_URL="http://localhost:3000"
NODE_ENV="development"
EOF

    log_success ".env.template creado"
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
  health-gate:
    name: "Health Check"
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: oven-sh/setup-bun@v2
      - name: Install dependencies
        run: bun install --frozen-lockfile
      - name: Build
        run: bun run build
      - name: Test
        run: bun test --run

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
          token: ${{ secrets.GITHUB_TOKEN }}
      - uses: oven-sh/setup-bun@v2
      - name: Install deps
        run: bun install
      - name: Create Release
        run: |
          git config --global user.name 'github-actions[bot]'
          git config --global user.email 'github-actions[bot]@users.noreply.github.com'
          bun run release
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

    # GGA SIEMPRE en pre-commit si está instalado
    if command -v gga &>/dev/null; then
        cat > .husky/pre-commit <<'EOF'
bun test
bunx lint-staged
gga run || exit 1
EOF
    else
        cat > .husky/pre-commit <<'EOF'
bun test
bunx lint-staged
EOF
    fi
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

    # Reemplazar placeholder con datos reales
    sed -i.bak "s/USER\/PROJECT/$(git config user.email 2>/dev/null | cut -d@ -f1 | tr '[:upper:]' '[:lower:]')/$(basename "$(pwd)")/g" CHANGELOG.md 2>/dev/null || true
    sed -i "s/YYYY-MM-DD/$(date +%Y-%m-%d)/g" CHANGELOG.md 2>/dev/null || true
    rm -f CHANGELOG.md.bak

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

    # Crear tag inicial
    git tag -a v1.0.0 -m "Initial release v1.0.0" --no-sign

    # Crear rama develop desde main
    git checkout -b develop

    log_success "Versionado configurado: v1.0.0"
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
NC='\033[0m'

# Help
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo -e "${BOLD}Git Commit Automatizado${NC}"
    echo ""
    echo -e "${CYAN}Uso:${NC}  git-c \"mensaje del commit\""
    echo ""
    echo -e "El script detecta el tipo de cambio y crea la rama automáticamente."
    echo ""
    echo -e "${CYAN}Aliases útiles:${NC}"
    echo "  gc  = git-c (commit rápido)"
    echo "  gca = git-c --amend (ammend)"
    echo "  gcp = git-c --push (commit + push)"
    echo ""
    exit 0
fi

# Verificar que estamos en develop
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [[ "$CURRENT_BRANCH" != "develop" ]]; then
    echo -e "${RED}✗${NC} Necesitás estar en la rama ${YELLOW}develop${NC} para crear un commit."
    echo "  Rama actual: $CURRENT_BRANCH"
    exit 1
fi

# Mensaje obligatorio
if [[ -z "$1" ]]; then
    echo -e "${RED}✗${NC} Necesitás proporcionar un mensaje de commit."
    echo "  Uso: git-c \"tu mensaje aquí\""
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
        if echo "$COMMIT_MSG" | grep -qiE "^fix|^hotfix|^patch"; then
            echo "fix"
        else
            echo "feat"
        fi
    elif echo "$CHANGED $UNTRACKED" | grep -qE "^package\.json$|^bun\.lock$|^tsconfig|^next\.config|^prisma/"; then
        echo "chore"
    else
        echo "chore"
    fi
}

# Generar nombre de rama desde el mensaje
slugify() {
    echo "$1" | sed -E 's/[^a-zA-Z0-9]+/-/g' | sed -E 's/^-+|-+$//g' | tr '[:upper:]' '[:lower:]'
}

# Ejecutar
TYPE=$(detect_type)
BRANCH_NAME="${TYPE}/$(slugify "$COMMIT_MSG")"

echo -e "${CYAN}┌─────────────────────────────────────────┐${NC}"
echo -e "${CYAN}│${NC}  ${BOLD}Git Commit Automatizado${NC}"
echo -e "${CYAN}└─────────────────────────────────────────┘${NC}"
echo ""
echo -e "  ${YELLOW}▸ Tipo:${NC}    ${GREEN}$TYPE${NC}"
echo -e "  ${YELLOW}▸ Rama:${NC}    ${CYAN}$BRANCH_NAME${NC}"
echo -e "  ${YELLOW}▸ Msg:${NC}     $COMMIT_MSG"
echo ""

# Verificar cambios ( unstaged + staged + untracked )
if ! git diff --quiet && [[ -z "$(git ls-files --others --exclude-standard)" ]]; then
    echo -e "  ${RED}✗${NC} No hay cambios para commitear"
    exit 1
fi
echo -e "  ${GREEN}✓${NC} Hay cambios para commitear"

# Stagear todo
git add -A

# Ejecutar tests (si existen)
if [[ -f "package.json" ]] && grep -q '"test"' package.json; then
    echo ""
    echo -e "  ${CYAN}▸ Corriendo tests...${NC}"
    if ! bun test --run 2>/dev/null; then
        echo -e "  ${RED}✗${NC} Tests fallaron. Corregí antes de commitear."
        exit 1
    fi
    echo -e "  ${GREEN}✓${NC} Tests OK"
fi

# Ejecutar GGA si está instalado
if command -v gga &>/dev/null; then
    echo ""
    echo -e "  ${CYAN}▸ Code review con GGA...${NC}"
    if ! gga run; then
        echo -e "  ${RED}✗${NC} GGA encontró errores. Corregí antes de commitear."
        exit 1
    fi
    echo -e "  ${GREEN}✓${NC} GGA OK"
fi

# Crear rama y commit
echo ""
echo -e "  ${CYAN}▸ Creando rama y commit...${NC}"
git checkout -b "$BRANCH_NAME"
git commit -m "${TYPE}: ${COMMIT_MSG}"

echo ""
echo -e "${GREEN}✓${NC} Commit creado en rama ${CYAN}$BRANCH_NAME${NC}"
echo ""
echo -e "${DIM}Próximos pasos:${NC}"
echo -e "  ${CYAN}git push -u origin $BRANCH_NAME${NC}  # Push y crear PR"
echo -e "  ${CYAN}git checkout develop${NC}              # Volver a develop"
GITCOMMIT

    chmod +x git-c

    # Configurar git alias
    git config alias.c "!bash git-c"

    log_success "Git workflow configurado"
    echo ""
    echo -e "  ${CYAN}Comandos disponibles:${NC}"
    echo -e "    ${YELLOW}git c${NC} \"mensaje\"   - Commit rápido automático"
    echo -e "    ${YELLOW}git c -h${NC}           - Ver ayuda"
}

# ============================================================================
# Día Cero
# ============================================================================

setup_git_initial() {
    log_info "Ritual de Día Cero..."

    # Verificar y setear git config solo si no existe
    if [ -z "$(git config --global user.email)" ]; then
        git config user.email "dev@bunker.local"
        log_info "Git email configurado: dev@bunker.local"
    else
        log_info "Git email: $(git config --global user.email) (existente)"
    fi

    if [ -z "$(git config --global user.name)" ]; then
        git config user.name "Developer"
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
    select_architecture
    select_agent
    select_graphify
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
    setup_env_template
    setup_vscode
    setup_agents_md
    setup_agent_rules
    setup_skills
    setup_husky
    setup_scripts
    setup_gitignore
    setup_git_initial
    setup_versioning
    setup_git_workflow
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
    echo "  git checkout develop"
    echo "  bun dev"
    echo ""
    echo "  ${DIM}Para crear un commit automático:${NC}"
    echo "  ${CYAN}git c \"tu mensaje del commit\"${NC}"
    echo ""

    # Desregistrar trap - todo salió bien
    trap - EXIT INT TERM
}

main "$@"
