#!/usr/bin/env bash

# ============================================================================
# Builders - Project creation functions
# ============================================================================

# ============================================================================
# Create Frontend Next.js
# ============================================================================

create_frontend_next() {
    log_info "Creando proyecto Next.js: $PROJECT_NAME..."

    if ! mkdir -p "$PROJECT_NAME"; then
        log_error "No se pudo crear el directorio $PROJECT_NAME"
        exit 1
    fi

    # Marcar que el directorio fue creado (para cleanup) - BEFORE cd
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

    log_info "Configurando Prisma schema..."
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
    
    cat > .env <<'EOF'
# Database
DATABASE_URL="postgresql://user:password@localhost:5432/dbname?schema=public"
EOF
    log_success "Prisma schema configurado"
}

# ============================================================================
# Create Frontend Vite
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

    log_info "Configurando Prisma schema..."
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
    
    cat > .env <<'EOF'
# Database
DATABASE_URL="postgresql://user:password@localhost:5432/dbname?schema=public"
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
# Create Backend NestJS
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

    log_info "Configurando Prisma schema..."
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
    
    cat > .env <<'EOF'
# Database
DATABASE_URL="postgresql://user:password@localhost:5432/dbname?schema=public"
EOF

    mkdir -p .agent/skills plans specs designs .github/workflows
    log_success "Proyecto NestJS configurado"
}

# ============================================================================
# Create Backend Golang
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

    cat > go.mod <<EOF
module ${PROJECT_NAME}

go 1.21

require (
	github.com/gin-gonic/gin v1.9.1
)
EOF

    run_with_timeout 120 go mod tidy

    run_with_timeout 60 go get github.com/gin-gonic/gin@v1.9.1

    mkdir -p .agent/skills plans specs designs .github/workflows
    log_success "Proyecto Go + Gin configurado"
}

# ============================================================================
# Create Monorepo
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