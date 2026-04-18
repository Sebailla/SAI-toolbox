#!/usr/bin/env bash

# ============================================================================
# Setup Module
# Funciones de configuración post-scaffolding del proyecto.
# Requiere: SELECTED_PKG_MANAGER, PROJECT_TYPE, BACKEND_TYPE, ARCHITECTURE,
#            TARGET_AGENT, USE_GRAPHIFY, DOCKER_DB_TYPE
# ============================================================================

# ============================================================================
# Helper: Slugify - Genera un nombre de rama válido desde un mensaje
# ============================================================================

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

# ============================================================================
# Helper: Detect Type - Detecta el tipo de commit según archivos modificados
# ============================================================================

detect_type() {
    local COMMIT_MSG="$1"
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
# Environment Template
# ============================================================================

setup_env_template() {
    log_info "Creando template de variables de entorno..."
    cat > .env.example <<'EOF'
# Database
DATABASE_URL="postgresql://user:password@localhost:5432/dbname?schema=public"

# Auth
JWT_SECRET="your-secret-key-here"
JWT_EXPIRES_IN="7d"

# App
NODE_ENV="development"
PORT="3000"
EOF
    log_success "Template .env.example creado"
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
- Bajo NINGUNA circunstancia generes código que violenten la estructura

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
- Bajo NINGUNA circunstancia generes código que violenten la estructura

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
- Toda acción técnica DEBE ser delegados a subagentes.
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
    
    # Agregar scripts a package.json usando jq o sed
    if command -v jq &>/dev/null; then
        jq --arg run_cmd "$run_cmd" '.scripts += {
            "test": "vitest",
            "db:seed": "tsx prisma/seed.ts",
            "db:reset": "prisma migrate reset --force && \($run_cmd) run db:seed",
            "release": "standard-version"
        }' package.json > package.json.tmp && mv package.json.tmp package.json 2>/dev/null || log_warn "No se pudieron configurar los scripts"
        
        # Agregar overrides si aplica
        if [ "$SELECTED_PKG_MANAGER" = "npm" ] || [ "$SELECTED_PKG_MANAGER" = "bun" ]; then
            jq 'if has("overrides") then .overrides += {"babel-plugin-react-compiler":"^0.0.0-experimental-71f1f4c6-20240515"} else .overrides = {"babel-plugin-react-compiler":"^0.0.0-experimental-71f1f4c6-20240515"} end' package.json > package.json.tmp && mv package.json.tmp package.json 2>/dev/null || true
        fi
    else
        # Fallback: usar sed para agregar scripts
        log_info "jq no disponible, omitiendo configuración de scripts"
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

setup_husky() {
    log_info "Configurando Husky y Commitlint..."

    # Verificar que .git existe (husky init lo necesita)
    if [ ! -d ".git" ]; then
        log_error "No se encontró .git. ¿Corriste git init?"
        exit 1
    fi

    # Usar el gestor de paquetes seleccionado
    local install_cmd=""
    local pkg_exec_cmd=""
    case "$SELECTED_PKG_MANAGER" in
        bun)   install_cmd="bun install"; pkg_exec_cmd="bunx" ;;
        pnpm)  install_cmd="pnpm install"; pkg_exec_cmd="pnpm exec" ;;
        npm)   install_cmd="npm install"; pkg_exec_cmd="npm exec" ;;
        *)     install_cmd="bun install"; pkg_exec_cmd="bunx" ;;
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
${pkg_exec_cmd} exec commitlint --edit "\$1"
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
    case "$SELECTED_PKG_MANAGER" in
        bun)
            test_cmd="bun test --run --passWithNoTests"
            pkg_exec_cmd="bunx"
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
# lint-staged requiere .lintstagedrc o config en package.json
# Si no tenés config, descomentá la siguiente línea:
# ${pkg_exec_cmd} exec lint-staged
gga run || exit 1
EOF
    else
        cat > .husky/pre-commit <<EOF
#!/usr/bin/env bash
${test_cmd}
# lint-staged requiere .lintstagedrc o config en package.json
# Si no tenés config, descomentá la siguiente línea:
# ${pkg_exec_cmd} exec lint-staged
EOF
    fi
    chmod +x .husky/pre-commit
}

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
    # Intentar detectar username de GitHub desde remote URL solo si existe origin
    local github_user="USER"
    local remote_url=""
    if git remote get-url origin 2>/dev/null | grep -q "github.com"; then
        remote_url=$(git remote get-url origin)
        # Extraer username de URLs como:
        # https://github.com/username/repo.git
        # git@github.com:username/repo.git
        # ssh://git@github.com/username/repo
        # Usar sed (portable BSD/GNU) en lugar de grep -oP que no tiene \K en macOS
        github_user=$(echo "$remote_url" | sed -E 's|.*github.com[/:]||' | cut -d/ -f1) || true
        if [ -z "$github_user" ]; then
            github_user="USER"
        fi
    fi
    if [[ "$github_user" == "USER" ]]; then
        # Solo warn si NO hay remote alguno (no es error, es esperado en local)
        if [[ -n "$remote_url" ]]; then
            log_warn "No se pudo detectar tu username de GitHub desde: $remote_url"
            echo "  El CHANGELOG usa USER como placeholder."
            echo "  Configurá tu Git username con: git config --global github.user TU_USUARIO"
        fi
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

    local default_provider="opencode"
    case "$TARGET_AGENT" in
        claude)  default_provider="claude" ;;
        cursor)  default_provider="opencode" ;;
        opencode) default_provider="opencode" ;;
        gemini)  default_provider="gemini" ;;
        all)     default_provider="opencode" ;;
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
# Docker Database Setup
# ============================================================================

setup_docker_db() {
    # Solo si el usuario eligió Docker DB
    if [ "$DOCKER_DB_TYPE" = "none" ]; then
        return 0
    fi
    
    log_info "Configurando Docker Database: $DOCKER_DB_TYPE..."
    
    # Verificar Docker nuevamente por las dudas
    if ! command -v docker &>/dev/null || ! docker info &>/dev/null; then
        log_warn "Docker no está disponible. Omitiendo configuración de contenedores."
        return 0
    fi
    
    # Crear docker-compose.yml
    cat > docker-compose.yml <<'EOF'
# ============================================================
# Docker Database Services
# Persistencia de datos en volúmenes Docker
# ============================================================

services:
EOF

    local db_user="saiuser"
    local db_pass="saipass"
    local db_name="saidb"
    
    # PostgreSQL
    if [ "$DOCKER_DB_TYPE" = "postgres" ] || [ "$DOCKER_DB_TYPE" = "postgres-redis" ] || [ "$DOCKER_DB_TYPE" = "all" ]; then
        cat >> docker-compose.yml <<'EOF'

  postgres:
    image: postgres:16-alpine
    container_name: sai_postgres
    ports:
      - "5432:5432"
    environment:
      POSTGRES_DB: saidb
      POSTGRES_USER: saiuser
      POSTGRES_PASSWORD: saipass
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U saiuser -d saidb"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 10s

EOF
        log_success "PostgreSQL configurado en puerto 5432"
    fi
    
    # MongoDB
    if [ "$DOCKER_DB_TYPE" = "mongodb" ] || [ "$DOCKER_DB_TYPE" = "mongodb-redis" ] || [ "$DOCKER_DB_TYPE" = "all" ]; then
        cat >> docker-compose.yml <<'EOF'

  mongodb:
    image: mongo:7.0
    container_name: sai_mongodb
    ports:
      - "27017:27017"
    environment:
      MONGO_INITDB_DATABASE: sai
      MONGO_INITDB_ROOT_USERNAME: saiuser
      MONGO_INITDB_ROOT_PASSWORD: saipass
    volumes:
      - mongodb_data:/data/db
      - mongodb_config:/data/configdb
    healthcheck:
      test: ["CMD", "mongosh", "--eval", "db.adminCommand('ping')"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 10s

EOF
        log_success "MongoDB configurado en puerto 27017"
    fi
    
    # Redis
    if [ "$DOCKER_DB_TYPE" = "redis" ] || [ "$DOCKER_DB_TYPE" = "postgres-redis" ] || [ "$DOCKER_DB_TYPE" = "mongodb-redis" ] || [ "$DOCKER_DB_TYPE" = "all" ]; then
        cat >> docker-compose.yml <<'EOF'

  redis:
    image: redis:7.2-alpine
    container_name: sai_redis
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    command: redis-server --appendonly yes
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 10s

EOF
        log_success "Redis configurado en puerto 6379"
    fi
    
    # Adminer (visualizador para PostgreSQL)
    if [ "$DOCKER_DB_TYPE" = "postgres" ] || [ "$DOCKER_DB_TYPE" = "postgres-redis" ] || [ "$DOCKER_DB_TYPE" = "all" ] || [ "$DOCKER_DB_TYPE" = "both" ]; then
        cat >> docker-compose.yml <<'EOF'

  adminer:
    image: adminer:latest
    container_name: sai_adminer
    ports:
      - "8080:8080"
    depends_on:
      - postgres
    healthcheck:
      test: ["CMD", "wget", "-q", "--spider", "http://localhost:8080"]
      interval: 10s
      timeout: 5s
      retries: 5

EOF
        log_success "Adminer (PostgreSQL admin) configurado en puerto 8080"
    fi
    
    # MongoDB Express (visualizador para MongoDB)
    if [ "$DOCKER_DB_TYPE" = "mongodb" ] || [ "$DOCKER_DB_TYPE" = "mongodb-redis" ] || [ "$DOCKER_DB_TYPE" = "all" ] || [ "$DOCKER_DB_TYPE" = "both" ]; then
        cat >> docker-compose.yml <<'EOF'

  mongo-express:
    image: mongo-express:latest
    container_name: sai_mongo_express
    ports:
      - "8081:8081"
    environment:
      ME_CONFIG_MONGODB_URL: "mongodb://saiuser:saipass@mongodb:27017/sai"
      ME_CONFIG_BASICAUTH_USERNAME: "saiuser"
      ME_CONFIG_BASICAUTH_PASSWORD: "saipass"
    depends_on:
      - mongodb
    healthcheck:
      test: ["CMD", "wget", "-q", "--spider", "http://localhost:8081"]
      interval: 10s
      timeout: 5s
      retries: 5

EOF
        log_success "MongoDB Express configurado en puerto 8081"
    fi
    
    # Redis Commander (visualizador para Redis)
    if [ "$DOCKER_DB_TYPE" = "redis" ] || [ "$DOCKER_DB_TYPE" = "postgres-redis" ] || [ "$DOCKER_DB_TYPE" = "mongodb-redis" ] || [ "$DOCKER_DB_TYPE" = "all" ]; then
        cat >> docker-compose.yml <<'EOF'

  redis-commander:
    image: rediscommander/redis-commander:latest
    container_name: sai_redis_commander
    ports:
      - "8082:8081"
    environment:
      REDIS_HOSTS: "local:sai_redis:6379"
      REDIS_HOST: "sai_redis"
      REDIS_PORT: "6379"
    depends_on:
      - redis
    healthcheck:
      test: ["CMD", "wget", "-q", "--spider", "http://localhost:8081"]
      interval: 10s
      timeout: 5s
      retries: 5

EOF
        log_success "Redis Commander configurado en puerto 8082"
    fi
    
    # Volumes al final del archivo
    cat >> docker-compose.yml <<'EOF'

volumes:
  postgres_data:
    driver: local
  mongodb_data:
    driver: local
  mongodb_config:
    driver: local
  redis_data:
    driver: local
EOF

    # Crear scripts de ayuda
    mkdir -p scripts
    
    # Script para iniciar contenedores
    cat > scripts/db-start.sh <<'EOF'
#!/usr/bin/env bash
# ============================================================
# Start Docker Database Containers
# ============================================================

set -e

CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BOLD='\033[1m'
NC='\033[0m'

echo ""
printf '%b\n' "${CYAN}${BOLD}╔═══════════════════════════════════════╗${NC}"
printf '%b\n' "${CYAN}${BOLD}║   Starting Docker Database...         ║${NC}"
printf '%b\n' "${CYAN}${BOLD}╚═══════════════════════════════════════╝${NC}"
echo ""

# Verificar Docker
if ! command -v docker &>/dev/null; then
    printf '%b\n' "${RED}✗${NC} Docker no está instalado."
    exit 1
fi

if ! docker info &>/dev/null; then
    printf '%b\n' "${RED}✗${NC} Docker daemon no está corriendo."
    printf '%s\n' "  Iniciá Docker Desktop."
    exit 1
fi

# Verificar que existe docker-compose.yml
if [ ! -f "docker-compose.yml" ]; then
    printf '%b\n' "${RED}✗${NC} docker-compose.yml no encontrado."
    exit 1
fi

# Iniciar contenedores
printf '%b\n' "${CYAN}▸ Levantando contenedores...${NC}"
docker compose up -d

echo ""
printf '%b\n' "${GREEN}✓${NC} Contenedores iniciados"
echo ""

# Mostrar estado
printf '%b\n' "${CYAN}▸ Estado de los servicios:${NC}"
docker compose ps

echo ""
printf '%b\n' "${YELLOW}▸ Connection strings:${NC}"
echo ""

# PostgreSQL connection string
if docker compose ps postgres &>/dev/null; then
    printf '%b\n' "  ${GREEN}PostgreSQL:${NC}"
    printf '%s\n' "    postgresql://saiuser:saipass@localhost:5432/saidb"
    echo ""
fi

# MongoDB connection string
if docker compose ps mongodb &>/dev/null; then
    printf '%b\n' "  ${CYAN}MongoDB:${NC}"
    printf '%s\n' "    mongodb://saiuser:saipass@localhost:27017/sai"
    echo ""
fi

# Redis connection string
if docker compose ps redis &>/dev/null; then
    printf '%b\n' "  ${YELLOW}Redis:${NC}"
    printf '%s\n' "    redis://default:redis123@localhost:6379"
    echo ""
fi

# Adminer
if docker compose ps adminer &>/dev/null; then
    printf '%b\n' "  ${GREEN}Adminer (PostgreSQL):${NC}"
    printf '%s\n' "    http://localhost:8080"
    echo ""
fi

# MongoDB Express
if docker compose ps mongo-express &>/dev/null; then
    printf '%b\n' "  ${CYAN}MongoDB Express:${NC}"
    printf '%s\n' "    http://localhost:8081"
    printf '%s\n' "    User: saiusers / Pass: saipass"
    echo ""
fi

# Redis Commander
if docker compose ps redis-commander &>/dev/null; then
    printf '%b\n' "  ${YELLOW}Redis Commander:${NC}"
    printf '%s\n' "    http://localhost:8082"
    echo ""
fi

echo ""
printf '%b\n' "${GREEN}✓${NC} Ready! Los datos persisten en volúmenes Docker."
printf '%s\n' "  ${YELLOW}./scripts/db-stop.sh${NC} para detener."
EOF
    chmod +x scripts/db-start.sh

    # Script para detener contenedores
    cat > scripts/db-stop.sh <<'EOF'
#!/usr/bin/env bash
# ============================================================
# Stop Docker Database Containers
# ============================================================

set -e

CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo ""
printf '%b\n' "${CYAN}╔═══════════════════════════════════════╗${NC}"
printf '%b\n' "${CYAN}║   Stopping Docker Database...         ║${NC}"
printf '%b\n' "${CYAN}╚═══════════════════════════════════════╝${NC}"
echo ""

if [ ! -f "docker-compose.yml" ]; then
    printf '%b\n' "${RED}✗${NC} docker-compose.yml no encontrado."
    exit 1
fi

printf '%b\n' "${CYAN}▸ Deteniendo contenedores...${NC}"
docker compose down

printf '%b\n' "${GREEN}✓${NC} Contenedores detenidos."
printf '%s\n' "  Los datos persisten en volúmenes Docker."
printf '%s\n' "  Usá ${CYAN}./scripts/db-reset.sh${NC} si necesitás resetear."
echo ""
EOF
    chmod +x scripts/db-stop.sh

    # Script para resetear base de datos
    cat > scripts/db-reset.sh <<'EOF'
#!/usr/bin/env bash
# ============================================================
# Reset Docker Database (BORRA todos los datos)
# ============================================================

set -e

CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BOLD='\033[1m'
NC='\033[0m'

echo ""
printf '%b\n' "${CYAN}${BOLD}╔═══════════════════════════════════════╗${NC}"
printf '%b\n' "${CYAN}${BOLD}║   RESET Docker Database               ║${NC}"
printf '%b\n' "${CYAN}${BOLD}╚═══════════════════════════════════════╝${NC}"
echo ""

printf '%b\n' "${YELLOW}⚠${NC} ${BOLD}ATENCIÓN: Esto BORRARÁ todos los datos${NC}"
printf '%s\n' "  Los volúmenes Docker serán eliminados."
echo ""

read -r -p "   └─►  Continuar? [${RED}s${NC}/${GREEN}n${NC}]: " CONFIRM
echo ""

if [[ ! "$CONFIRM" =~ ^[Ss]$ ]] && [[ ! "$CONFIRM" =~ ^[Ss][Ii]$ ]]; then
    printf '%b\n' "${CYAN}Operación cancelada.${NC}"
    exit 0
fi

if [ ! -f "docker-compose.yml" ]; then
    printf '%b\n' "${RED}✗${NC} docker-compose.yml no encontrado."
    exit 1
fi

printf '%b\n' "${CYAN}▸ Deteniendo y eliminando volúmenes...${NC}"
docker compose down -v

printf '%b\n' "${GREEN}✓${NC} Volúmenes eliminados."
printf '%b\n' "${CYAN}▸ Reiniciando contenedores...${NC}"
docker compose up -d

printf '%b\n' "${GREEN}✓${NC} Base de datos reseteada."
echo ""
EOF
    chmod +x scripts/db-reset.sh

    # Script para ver logs
    cat > scripts/db-logs.sh <<'EOF'
#!/usr/bin/env bash
# ============================================================
# Ver logs de Docker Database
# ============================================================

set -e

CYAN='\033[0;36m'
NC='\033[0m'

echo ""
printf '%b\n' "${CYAN}╔═══════════════════════════════════════╗${NC}"
printf '%b\n' "${CYAN}║   Docker Database Logs                ║${NC}"
printf '%b\n' "${CYAN}╚═══════════════════════════════════════╝${NC}"
echo ""

if [ ! -f "docker-compose.yml" ]; then
    echo "docker-compose.yml no encontrado."
    exit 1
fi

# Filtrar argumentos
SERVICE=""
if [ -n "$1" ]; then
    SERVICE="$1"
fi

if [ -n "$SERVICE" ]; then
    echo ""
    printf '%b\n' "${CYAN}▸ Logs de ${SERVICE}:${NC}"
    docker compose logs -f "$SERVICE"
else
    echo ""
    printf '%b\n' "${CYAN}▸ Todos los logs (Ctrl+C para salir):${NC}"
    docker compose logs -f
fi
EOF
    chmod +x scripts/db-logs.sh

    # Actualizar .env.template con las URLs correctas según la elección
    case "$DOCKER_DB_TYPE" in
        postgres)
            cat >> .env <<'EOF'

# ============================================================
# Docker PostgreSQL
# ============================================================
# PostgreSQL: postgresql://saiuser:saipass@localhost:5432/saidb
EOF
            ;;
        mongodb)
            cat >> .env <<'EOF'

# ============================================================
# Docker MongoDB
# ============================================================
# MongoDB: mongodb://saiuser:saipass@localhost:27017/sai
EOF
            ;;
        redis)
            cat >> .env <<'EOF'

# ============================================================
# Docker Redis
# ============================================================
# Redis: redis://default:redis123@localhost:6379
EOF
            ;;
        postgres-redis)
            cat >> .env <<'EOF'

# ============================================================
# Docker Databases
# ============================================================
# PostgreSQL: postgresql://saiuser:saipass@localhost:5432/saidb
# Redis: redis://default:redis123@localhost:6379
EOF
            ;;
        mongodb-redis)
            cat >> .env <<'EOF'

# ============================================================
# Docker Databases
# ============================================================
# MongoDB: mongodb://saiuser:saipass@localhost:27017/sai
# Redis: redis://default:redis123@localhost:6379
EOF
            ;;
        all)
            cat >> .env <<'EOF'

# ============================================================
# Docker Databases
# ============================================================
# PostgreSQL: postgresql://saiuser:saipass@localhost:5432/saidb
# MongoDB: mongodb://saiuser:saipass@localhost:27017/sai
# Redis: redis://default:redis123@localhost:6379
EOF
            ;;
        both)
            cat >> .env <<'EOF'

# ============================================================
# Docker Databases
# ============================================================
# PostgreSQL: postgresql://saiuser:saipass@localhost:5432/saidb
# MongoDB: mongodb://saiuser:saipass@localhost:27017/sai
EOF
            ;;
    esac

    # Actualizar .env.example
    if grep -q "docker-compose.yml" .env.example 2>/dev/null; then
        true  # ya existe
    else
        cat >> .env.example <<'EOF'

# ============================================================
# Docker Database (opcional)
# ============================================================
# Levantá con: docker compose up -d
# Detené con: docker compose down
# Resetear: ./scripts/db-reset.sh
EOF
    fi

    log_success "Docker Database configurado"
    echo ""
    log "  ${CYAN}Scripts disponibles:${NC}"
    log "    ${YELLOW}./scripts/db-start.sh${NC}  - Iniciar contenedores"
    log "    ${YELLOW}./scripts/db-stop.sh${NC}   - Detener contenedores"
    log "    ${YELLOW}./scripts/db-reset.sh${NC}  - Resetear base de datos"
    log "    ${YELLOW}./scripts/db-logs.sh${NC}   - Ver logs"
    echo ""
    log "  ${CYAN}Volúmenes persistentes:${NC}"
    [ "$DOCKER_DB_TYPE" = "postgres" ] || [ "$DOCKER_DB_TYPE" = "postgres-redis" ] || [ "$DOCKER_DB_TYPE" = "all" ] || [ "$DOCKER_DB_TYPE" = "both" ] && log "    ${GREEN}postgres_data${NC} - Datos de PostgreSQL"
    [ "$DOCKER_DB_TYPE" = "mongodb" ] || [ "$DOCKER_DB_TYPE" = "mongodb-redis" ] || [ "$DOCKER_DB_TYPE" = "all" ] || [ "$DOCKER_DB_TYPE" = "both" ] && log "    ${CYAN}mongodb_data${NC} - Datos de MongoDB"
    [ "$DOCKER_DB_TYPE" = "redis" ] || [ "$DOCKER_DB_TYPE" = "postgres-redis" ] || [ "$DOCKER_DB_TYPE" = "mongodb-redis" ] || [ "$DOCKER_DB_TYPE" = "all" ] && log "    ${YELLOW}redis_data${NC} - Datos de Redis"
    echo ""
}
