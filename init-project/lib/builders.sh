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

# ============================================================================
# Apply Architecture Folder Structure
# ============================================================================

apply_architecture() {
    log_info "Aplicando estructura de arquitectura: $ARCHITECTURE..."

    case "$ARCHITECTURE" in
        modular)
            _apply_modular_architecture
            ;;
        hexagonal)
            _apply_hexagonal_architecture
            ;;
        layered)
            _apply_layered_architecture
            ;;
        *)
            log_warn "Arquitectura desconocida: $ARCHITECTURE - omitiendo estructura"
            ;;
    esac
}

_apply_modular_architecture() {
    log_info "Creando estructura Modular Vertical Slicing..."

    # Shared UI components
    mkdir -p src/components/ui

    # Core utilities
    mkdir -p src/core

    # Example module: auth (to demonstrate structure)
    mkdir -p src/modules/auth/components
    mkdir -p src/modules/auth/services
    mkdir -p src/modules/auth/validators

    # auth module files
    cat > src/modules/auth/types.ts <<'EOF'
// Auth module types
export interface User {
  id: string;
  email: string;
  name: string;
}

export interface AuthState {
  user: User | null;
  isAuthenticated: boolean;
}
EOF

    cat > src/modules/auth/index.ts <<'EOF'
// Auth module public API
export * from './types';
export * from './services/auth.service';
export * from './validators/auth.validators';
EOF

    cat > src/modules/auth/services/auth.service.ts <<'EOF'
// Auth service - pure business logic
import type { User } from '../types';

export async function login(email: string, password: string): Promise<User> {
  // TODO: implement login logic
  throw new Error('Not implemented');
}

export async function logout(): Promise<void> {
  // TODO: implement logout logic
  throw new Error('Not implemented');
}

export async function getCurrentUser(): Promise<User | null> {
  // TODO: implement getCurrentUser logic
  return null;
}
EOF

    cat > src/modules/auth/validators/auth.validators.ts <<'EOF'
// Auth validators - Zod schemas
import { z } from 'zod';

export const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
});

export const registerSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
  name: z.string().min(2),
});

export type LoginInput = z.infer<typeof loginSchema>;
export type RegisterInput = z.infer<typeof registerSchema>;
EOF

    cat > src/modules/auth/components/LoginForm.tsx <<'EOF'
'use client';

import { useState } from 'react';

interface LoginFormProps {
  onSuccess?: () => void;
}

export function LoginForm({ onSuccess }: LoginFormProps) {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    // TODO: integrate with auth service
    console.log('Login:', { email, password });
    onSuccess?.();
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <div>
        <label htmlFor="email">Email</label>
        <input
          id="email"
          type="email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          required
        />
      </div>
      <div>
        <label htmlFor="password">Password</label>
        <input
          id="password"
          type="password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          required
        />
      </div>
      <button type="submit">Login</button>
    </form>
  );
}
EOF

    log_success "Estructura Modular creada: src/modules/<name>/"
}

_apply_hexagonal_architecture() {
    log_info "Creando estructura Hexagonal (Clean Architecture)..."

    # Domain layer - pure business logic
    mkdir -p src/domain/entities
    mkdir -p src/domain/value-objects
    mkdir -p src/domain/services
    mkdir -p src/domain/events
    mkdir -p src/domain/exceptions
    mkdir -p src/domain/interfaces

    # Application layer - use cases
    mkdir -p src/application/use-cases
    mkdir -p src/application/dto
    mkdir -p src/application/ports

    # Infrastructure layer - adapters
    mkdir -p src/infrastructure/persistence
    mkdir -p src/infrastructure/http/controllers
    mkdir -p src/infrastructure/http/middleware
    mkdir -p src/infrastructure/queue
    mkdir -p src/infrastructure/external

    # Shared utilities
    mkdir -p src/shared

    # Example domain entity
    cat > src/domain/entities/User.ts <<'EOF'
// Domain entity - pure, no external dependencies
export interface User {
  id: string;
  email: string;
  name: string;
  createdAt: Date;
}

export interface UserProps {
  id: string;
  email: string;
  name: string;
  createdAt?: Date;
}

export function createUser(props: UserProps): User {
  return {
    id: props.id,
    email: props.email,
    name: props.name,
    createdAt: props.createdAt ?? new Date(),
  };
}
EOF

    # Example domain interface (port)
    cat > src/domain/interfaces/IUserRepository.ts <<'EOF'
// Port - repository interface defined in domain
import type { User } from '../entities/User';

export interface IUserRepository {
  findById(id: string): Promise<User | null>;
  findByEmail(email: string): Promise<User | null>;
  save(user: User): Promise<void>;
  delete(id: string): Promise<void>;
}
EOF

    # Example use case
    cat > src/application/use-cases/RegisterUserUseCase.ts <<'EOF'
// Application use case - orchestrates domain logic
import type { User } from '../../domain/entities/User';
import type { IUserRepository } from '../../domain/interfaces/IUserRepository';

export interface RegisterUserInput {
  email: string;
  password: string;
  name: string;
}

export class RegisterUserUseCase {
  constructor(private userRepository: IUserRepository) {}

  async execute(input: RegisterUserInput): Promise<User> {
    const existing = await this.userRepository.findByEmail(input.email);
    if (existing) {
      throw new Error('User already exists');
    }

    const user: User = {
      id: crypto.randomUUID(),
      email: input.email,
      name: input.name,
      createdAt: new Date(),
    };

    await this.userRepository.save(user);
    return user;
  }
}
EOF

    log_success "Estructura Hexagonal creada: src/domain/, src/application/, src/infrastructure/"
}

_apply_layered_architecture() {
    log_info "Creando estructura Layered (Controllers → Services → Repositories)..."

    # Traditional layered structure
    mkdir -p src/controllers
    mkdir -p src/services
    mkdir -p src/repositories
    mkdir -p src/middleware
    mkdir -p src/routes
    mkdir -p src/dto
    mkdir -p src/utils

    # Example controller
    cat > src/controllers/UserController.ts <<'EOF'
// Layered Controller - handles HTTP concerns
import { Request, Response, NextFunction } from 'express';
import { UserService } from '../services/UserService';

const userService = new UserService();

export class UserController {
  static async getAll(req: Request, res: Response, next: NextFunction) {
    try {
      const users = await userService.findAll();
      res.json(users);
    } catch (error) {
      next(error);
    }
  }

  static async getById(req: Request, res: Response, next: NextFunction) {
    try {
      const user = await userService.findById(req.params.id);
      if (!user) {
        res.status(404).json({ error: 'User not found' });
        return;
      }
      res.json(user);
    } catch (error) {
      next(error);
    }
  }

  static async create(req: Request, res: Response, next: NextFunction) {
    try {
      const user = await userService.create(req.body);
      res.status(201).json(user);
    } catch (error) {
      next(error);
    }
  }

  static async update(req: Request, res: Response, next: NextFunction) {
    try {
      const user = await userService.update(req.params.id, req.body);
      if (!user) {
        res.status(404).json({ error: 'User not found' });
        return;
      }
      res.json(user);
    } catch (error) {
      next(error);
    }
  }

  static async delete(req: Request, res: Response, next: NextFunction) {
    try {
      await userService.delete(req.params.id);
      res.status(204).send();
    } catch (error) {
      next(error);
    }
  }
}
EOF

    # Example service
    cat > src/services/UserService.ts <<'EOF'
// Layered Service - business logic, no HTTP concerns
import { UserRepository } from '../repositories/UserRepository';
import type { User } from '../models/User';

export class UserService {
  private userRepository: UserRepository;

  constructor() {
    this.userRepository = new UserRepository();
  }

  async findAll(): Promise<User[]> {
    return this.userRepository.findAll();
  }

  async findById(id: string): Promise<User | null> {
    return this.userRepository.findById(id);
  }

  async create(data: { email: string; name: string; password: string }): Promise<User> {
    // Business logic: validation, password hashing, etc.
    if (!data.email || !data.email.includes('@')) {
      throw new Error('Invalid email');
    }
    if (data.password.length < 8) {
      throw new Error('Password must be at least 8 characters');
    }

    const user: User = {
      id: crypto.randomUUID(),
      email: data.email,
      name: data.name,
      createdAt: new Date(),
    };

    return this.userRepository.save(user);
  }

  async update(id: string, data: Partial<User>): Promise<User | null> {
    const existing = await this.userRepository.findById(id);
    if (!existing) return null;

    const updated: User = {
      ...existing,
      ...data,
      id: existing.id, // immutable
      createdAt: existing.createdAt, // immutable
    };

    return this.userRepository.update(updated);
  }

  async delete(id: string): Promise<void> {
    await this.userRepository.delete(id);
  }
}
EOF

    # Example repository
    cat > src/repositories/UserRepository.ts <<'EOF'
// Layered Repository - data access abstraction
import type { User } from '../models/User';

// In a real app, this would use Prisma
// import { prisma } from '../infrastructure/persistence/prisma';

export class UserRepository {
  private users: Map<string, User> = new Map();

  async findAll(): Promise<User[]> {
    return Array.from(this.users.values());
  }

  async findById(id: string): Promise<User | null> {
    return this.users.get(id) ?? null;
  }

  async findByEmail(email: string): Promise<User | null> {
    return Array.from(this.users.values()).find(u => u.email === email) ?? null;
  }

  async save(user: User): Promise<User> {
    this.users.set(user.id, user);
    return user;
  }

  async update(user: User): Promise<User> {
    this.users.set(user.id, user);
    return user;
  }

  async delete(id: string): Promise<void> {
    this.users.delete(id);
  }
}
EOF

    # Example model (shared between layers)
    mkdir -p src/models
    cat > src/models/User.ts <<'EOF'
// Domain model - shared across all layers
export interface User {
  id: string;
  email: string;
  name: string;
  createdAt: Date;
  updatedAt?: Date;
}
EOF

    log_success "Estructura Layered creada: src/controllers/, src/services/, src/repositories/"
}