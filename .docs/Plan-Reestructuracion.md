# Plan de Reestructuración SAI Toolbox

**Autor:** Sebastián Illa  
**Fecha:** 2026-04-15  
**Última modificación:** 2026-04-15

---

## Objetivo

Expandir SAI Toolbox para soportar múltiples tipos de proyecto:
- Frontend con dos variantes (Next.js o React+Vite)
- Backend con dos variantes (NestJS o Gin/Go)
- Monorepo Fullstack combinando frontend + backend

---

## Tipos de Proyecto

### 1. Frontend - Next.js (existente)
```
proyecto/
├── src/
│   ├── app/
│   ├── components/
│   └── ...
├── prisma/
└── ... (stack actual)
```

### 2. Frontend - React + Vite (NUEVO)
```
proyecto/
├── src/
│   ├── components/
│   ├── pages/
│   └── ...
├── prisma/
└── ... (Tailwind + Vite)
```

### 3. Backend - NestJS (NUEVO)
```
proyecto/
├── src/
│   ├── modules/
│   ├── common/
│   └── ...
├── test/
└── ... (TypeScript + NestJS)
```

### 4. Backend - Gin/Echo Go (NUEVO)
```
proyecto/
├── cmd/
│   └── server/
├── internal/
│   ├── handlers/
│   ├── middleware/
│   └── ...
├── pkg/
└── ... (Go modules)
```

### 5. Monorepo Fullstack (NUEVO)
```
proyecto/
├── apps/
│   ├── web/          (Next.js)
│   └── api/           (NestJS o Gin/Go)
├── packages/
│   └── shared/
├── prisma/
└── ... (workspace config)
```

---

## Wizard Steps (Flujo Dinámico)

```
PASO 1: Nombre del proyecto
    ↓
PASO 2: Gestor de paquetes (bun/pnpm/npm)
    ↓
PASO 3: Tipo de proyecto
    ├─► 1) Frontend (Next.js)
    │       ↓
    │     PASO 5: Arquitectura
    │
    ├─► 2) Frontend (React + Vite)
    │       ↓
    │     PASO 5: Arquitectura
    │
    ├─► 3) Backend
    │       ↓
    │     PASO 4: Elegir backend (NestJS o Gin/Go)
    │       ↓
    │     PASO 6: Agente IA
    │
    └─► 4) Monorepo Fullstack
            ↓
          PASO 4: Elegir backend (NestJS o Gin/Go)
            ↓
          PASO 5: Arquitectura
```

---

## Variables del Script

```bash
PROJECT_NAME=""
SELECTED_PKG_MANAGER=""  # bun/pnpm/npm
PROJECT_TYPE=""          # frontend-next/frontend-vite/backend/monorepo
BACKEND_TYPE=""          # nestjs/golang (solo si PROJECT_TYPE=backend o monorepo)
ARCHITECTURE=""          # modular/hexagonal (si aplica)
TARGET_AGENT=""
USE_GRAPHIFY=""
```

---

## Estructura de Funciones

### Selector principal (reestructurado)
```bash
select_project_name()      # Paso 1
select_package_manager()   # Paso 2
select_project_type()      # Paso 3 - bifurca el flujo
select_backend_type()     # Paso 4 - solo si aplica
select_architecture()     # Paso 5 - solo si aplica
select_agent()             # Paso 6
select_graphify()          # Paso 7
confirm_setup()            # Paso 8
```

### Creación por tipo
```bash
create_frontend_next()     # Next.js
create_frontend_vite()    # React + Vite
create_backend_nestjs()   # NestJS
create_backend_golang()    # Gin/Echo Go
create_monorepo()         # Next.js + API
```

### Setup por tipo
```bash
setup_env_template()       # Común a todos
setup_github_actions()    # Común a todos
setup_gitignore()         # Común a todos
setup_agents_md()         # Común a todos
setup_skills()            # Común a todos

# Específicos
setup_husky()             #Todos
setup_versioning()        #Todos
setup_vitest()            # Frontend/Monorepo
setup_next_specific()     # Next.js
setup_vite_specific()     # Vite
setup_nestjs_specific()   # NestJS
setup_golang_specific()   # Gin/Echo
setup_monorepo_workspace() # Monorepo
```

---

## Dependencias por Tipo

### Frontend Next.js
- create-next-app con flags
- Dependencias actuales (prisma, zod, etc.)

### Frontend Vite
- bunx create-vite (o pnpm dlx / npx)
- Tailwind + PostCSS
- React + TypeScript
- Dependencias similares (prisma, zod, etc.)

### Backend NestJS
- @nestjs/core + modules
- TypeORM o Prisma
- class-validator + class-transformer
- Testing con Jest

### Backend Go
- gin-gonic/gin o labstack/echo
- go-chi/chi (alternative)
- wire (DI)
- golang-migrate
- Testing con testing package

### Monorepo
- Workspace config (bun/pnpm/npm)
- Shared packages
- Cada app configurable independientemente

---

## Gestor de Paquetes - Commands

| Acción | bun | pnpm | npm |
|--------|-----|------|-----|
| Scaffold Next.js | `bunx create-next-app` | `pnpm dlx create-next-app` | `npx create-next-app` |
| Scaffold Vite | `bunx create-vite` | `pnpm dlx create-vite` | `npx create-vite` |
| Install | `bun add` | `pnpm add` | `npm install` |
| Dev deps | `bun add -d` | `pnpm add -D` | `npm install -D` |
| Exec | `bun` | `pnpm exec` | `npm exec` |
| Run | `bun` | `pnpm` | `npm run` |

---

## Go Module Commands

Para Gin/Echo, Go no usa gestor de paquetes externo en el mismo sentido. Los commands son:

```bash
# Inicializar module
go mod init

# Agregar dependencia
go get github.com/gin-gonic/gin

# Install tools (para el proyecto generado)
go install ...
```

---

## Validación de Dependencias

```bash
case "$SELECTED_PKG_MANAGER" in
    bun)
        check: bun, git, npm
        ;;
    pnpm)
        check: pnpm, git, npm
        ;;
    npm)
        check: npm, git
        ;;
esac

# Go backend
case "$BACKEND_TYPE" in
    golang)
        check: go, git
        ;;
    nestjs)
        check: [gestor], git, npm
        ;;
esac
```

---

## Próximos Pasos Implementación

1. [ ] Refactorizar `select_project_type()` con case/if
2. [ ] Crear función `select_backend_type()` 
3. [ ] Crear funciones `create_frontend_vite()`
4. [ ] Crear funciones `create_backend_nestjs()`
5. [ ] Crear funciones `create_backend_golang()`
6. [ ] Crear funciones `create_monorepo()`
7. [ ] Adaptar `main()` al flujo dinámico
8. [ ] Actualizar README.md
9. [ ] Actualizar llms.txt
10. [ ] Testing con dry-run

---

## Notas

- El flujo dinámico se maneja con variables de estado
- Cada paso verifica si aplica según el tipo elegido
- Los pasos 4 y 5 se muestran SOLO si corresponde
- La numeración visual es "Paso X de 8" pero el flujo real varía
