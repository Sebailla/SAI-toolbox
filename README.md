# 🚀 SAI Project Initializer

**Script para crear proyectos Next.js production-ready con un solo comando.**

Crea un proyecto completo con Next.js, TypeScript, Tailwind CSS v4, Prisma + PostgreSQL, y toda la configuración de desarrollo lista para usar.

---

## ✨ Features

| Feature | Descripción |
|---------|-------------|
| **Next.js 16** | App Router, TypeScript, Tailwind CSS v4 |
| **Stack SAI** | Prisma + PostgreSQL, Zod, Vitest, Playwright, Husky |
| **Arquitecturas** | Modular Vertical Slicing o Hexagonal (Clean Architecture) |
| **Git Workflow** | Ramas auto: main → develop → feat/fix/docs/chore |
| **Versionado** | Semantic Versioning con standard-version y CHANGELOG |
| **Git hooks** | Commitlint + Conventional Commits + branch naming + GGA |
| **Skills para IA** | Documentación automática y planificación |
| **Graphify** | Knowledge graph para arquitectura (opcional) |
| **GGA** | Code review con IA en cada commit (automático si está instalado) |
| **UI Colorida** | Interfaz interactiva con colores y ayuda visual |
| **Portable** | Compatible con macOS (BSD) y Linux (GNU) |
| **Shell Timeout** | Timeout portable con fallback a perl (macOS sin gtimeout) |

---

## ⚡ Uso

### Instalación global (recomendado)

```bash
# Instalar una vez
curl -fsSL https://raw.githubusercontent.com/Sebailla/SAI-toolbox/main/install.sh | bash

# Usar desde cualquier directorio
init-projects
```

### Uso directo (sin instalación)

```bash
curl -fsSL https://raw.githubusercontent.com/Sebailla/SAI-toolbox/main/init-project.sh | bash
```

---

## 🎯 Flujo de Creación

El script es **completamente interactivo**. Solo ejecutá `init-projects` y te guiará paso a paso:

```
  ▸ Paso 1 ─── Nombre del proyecto
  ▸ Paso 2 ─── Arquitectura (Modular o Hexagonal)  
  ▸ Paso 3 ─── Agente de IA
  ▸ Paso 4 ─── Graphify
  ▸ Paso 5 ─── Confirmar
```

---

## 📊 Git Workflow Automatizado

```
main ←───────────────────────────────────────── producción (protegida)
  ↑                      ↑
  │                      │ merge solo desde develop
  │                      │
develop ←── feat/mi-feature ─── fix/bug-fix ─── chore/update-deps
                ↑
                │ git c "mensaje" (crea rama + commit + GGA + tests)
```

### Comandos

```bash
# Crear commit automático (desde develop)
git c "agrego login con JWT"

# Help
git c --help
```

### Qué hace `git c`:

1. **Verifica** que estés en `develop` y que la rama exista
2. **Detecta el tipo** de cambio (feat/fix/docs/chore/test)
3. **Genera nombre de rama** con slugify (soporta acentos, truncado a 50 chars)
4. **Verifica que la rama** no exista ya
5. **Corre los tests**: `bun test --run --passWithNoTests`
6. **Corre GGA review** (si está instalado)
7. **Crea la rama** y hace el commit de forma atómica
8. Si algo falla después de crear la rama, la elimina automáticamente

---

## 📦 Estructuras disponibles

### Modular Vertical Slicing

```
src/
├── modules/              # Features/módulos auto-contenidos
│   └── example/
│       ├── components/   # Componentes UI del módulo
│       ├── services/    # Lógica de negocio pura
│       ├── actions.ts   # Server Actions (validación + orquestación)
│       ├── types.ts     # Tipos específicos del módulo
│       └── index.ts     # API pública del módulo
├── core/                 # Utilidades compartidas
│   ├── lib/
│   ├── types/
│   └── hooks/
└── components/ui/        # Componentes UI genéricos
```

### Hexagonal (Clean Architecture)

```
src/
├── domain/              # Lógica de negocio pura (SIN dependencias)
│   ├── entities/
│   ├── value-objects/
│   ├── services/
│   ├── events/
│   ├── exceptions/
│   └── interfaces/      # Contratos (puertos)
├── application/         # Casos de uso
│   ├── use-cases/
│   ├── dto/
│   └── ports/
├── infrastructure/      # Adaptadores
│   ├── persistence/    # Repositorios (Prisma)
│   ├── http/           # Controladores, middleware
│   ├── queue/
│   └── external/
└── shared/             # Utilidades compartidas
```

---

## 🛠️ Stack Tecnológico

| Categoría | Tecnología |
|-----------|------------|
| **Framework** | Next.js 16 (App Router) |
| **Styling** | Tailwind CSS v4 |
| **Database** | Prisma + PostgreSQL |
| **Validation** | Zod |
| **Testing** | Vitest + Playwright |
| **Auth** | JWT + bcryptjs |
| **Git** | Husky + Commitlint + Standard Version |
| **AI Skills** | Documentación y planificación |

---

## 📁 Archivos generados

```
proyecto/
├── .env.template          # Variables de entorno
├── .env                    # (NO commitear - tu config local)
├── prisma/schema.prisma    # Esquema de base de datos
├── CHANGELOG.md           # Historial de cambios
├── VERSION                # Versión actual (1.0.0)
├── .versionrc            # Config de standard-version
├── .husky/               # Git hooks
├── .github/workflows/    # GitHub Actions (health-gate + release)
├── .vscode/settings.json  # Config VSCode
├── git-c                 # Script de commit automatizado
├── AGENTS.md             # Reglas para agentes de IA
├── CLAUDE.md / .cursorrules / GEMINI.md  # Reglas por agente
└── .agent/skills/        # Skills personalizados
```

---

## 🔧 Post-Instalación

```bash
cd mi-proyecto

# 1. Instalar dependencias
bun install

# 2. Configurar variables de entorno
cp .env.template .env
# Editar DATABASE_URL con tu PostgreSQL

# 3. Generar cliente Prisma
bunx prisma generate

# 4. Crear base de datos y tablas
bunx prisma migrate dev --name init

# 5. Iniciar desarrollo
bun dev
```

### Variables de entorno (.env.template)

```env
DATABASE_URL="postgresql://USER:PASSWORD@HOST:5432/DATABASE?schema=public"
JWT_SECRET="your-super-secret-jwt-token-change-in-production"
JWT_EXPIRES_IN="7d"
APP_URL="http://localhost:3000"
NODE_ENV="development"
```

---

## 🔖 Versionado Semántico

El proyecto usa **Semantic Versioning** con standard-version:

```bash
# Ver versión actual
cat VERSION
# 1.0.0

# Crear release (bumps version, actualiza CHANGELOG, crea tag)
bun run release

# Formato de commits: tipo: descripción
git c "agrego endpoint para usuarios"
git c "fix: corrijo bug en login"
```

### Tipos de Commit

| Tipo | Uso |
|------|-----|
| `feat` | Nuevas funcionalidades |
| `fix` | Correcciones de bugs |
| `chore` | Mantenimiento, deps, config |
| `docs` | Documentación |
| `refactor` | Refactoring sin cambiar funcionalidad |
| `test` | Tests |
| `perf` | Performance |
| `ci` | CI/CD |

---

## 🤝 Workflow de Desarrollo

```bash
# 1. Desde develop, crear un commit
git c "agrego módulo de usuarios"

# 2. Push y crear PR
git push -u origin feat/agrego-modulo-de-usuarios

# 3. Merge a develop (vía PR o manualmente)
git checkout develop
git merge feat/agrego-modulo-de-usuarios

# 4. Cuando esté listo para producción
git checkout main
git merge develop
# O crear release:
bun run release  # bumps a 1.1.0, actualiza CHANGELOG, tag v1.1.0
```

---

## 🤖 Integración con Agentes de IA

El proyecto incluye configuración para agentes de IA en `.agent/AGENTS.md`. Este archivo contiene:

- **Stack tecnológico** del proyecto
- **Reglas de código** (portabilidad shell, colores ANSI, sed compatible)
- **Reglas de Git** (conventional commits, workflow de ramas)
- **Workflow para agentes** (antes/después de hacer cambios)
- **Comandos útiles**

Cuando trabajes con un agente de IA en este proyecto, debe leer `.agent/AGENTS.md` primero.

### Beneficios

| Feature | Descripción |
|---------|-------------|
| **Contexto persistente** | El agente sabe las reglas del proyecto |
| **Code review automático** | GGA revisa cada commit |
| **Judgment Day** | Revisión adversarial opcional |
| **Graphify** | Knowledge graph para entender la arquitectura |

---

## 📚 Documentación

| Archivo | Descripción |
|---------|-------------|
| `.agent/AGENTS.md` | Instrucciones para agentes de IA |
| `.docs/Guia-Rapida.md` | Quick start y comandos |
| `.docs/Arquitectura-Modular.md` | Guía de Modular Vertical Slicing |
| `.docs/Arquitectura-Hexagonal.md` | Guía de Clean Architecture |
| `.docs/Git-Workflow.md` | Workflow Git detallado |
| `llms.txt` | Contexto optimizado para LLMs |

---

## 🤝 Contribuir

1. Haz un fork del repo
2. Crea una rama: `git checkout -b feat/nueva-feature`
3. Commit: `git commit -m 'feat: nueva feature'`
4. Push: `git push origin feat/nueva-feature`
5. Abre un Pull Request

---

## 📄 Licencia

MIT

---

**Autor:** Sebastián Illa  
**Creado:** 2026-04-13  
**Última modificación:** 2026-04-15
