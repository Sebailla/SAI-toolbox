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
| **Git hooks** | Commitlint + Conventional Commits + branch naming + GGA |
| **Skills para IA** | Documentación automática y planificación |
| **Graphify** | Knowledge graph para arquitectura (opcional) |
| **GGA** | Code review con IA en cada commit (automático si está instalado) |
| **UI Colorida** | Interfaz interactiva con colores y ayuda visual |

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

## 🎯 Opciones

El script es **completamente interactivo**. Solo ejecutá `init-projects` y te guiará paso a paso:

```
  ╔═══════════════════════════════════════════════╗
  ║   SAI Project Initializer                    ║
  ║   Arquitectura Modular o Hexagonal           ║
  ╚═══════════════════════════════════════════════╝

  ▸ Paso 1 de 5 ─── Nombre del proyecto
  ▸ Paso 2 de 5 ─── Arquitectura  
  ▸ Paso 3 de 5 ─── Agente de IA
  ▸ Paso 4 de 5 ─── Graphify
  ▸ Paso 5 de 5 ─── Confirmar
```

### Preguntas interactivas

1. **Nombre del proyecto** - El nombre de la carpeta (solo letras, números, guiones)
2. **Arquitectura** - Modular Vertical Slicing o Hexagonal (Clean Architecture)
3. **Agente de IA** - OpenCode, Claude Code, Cursor, Gemini CLI o todos
4. **Graphify** - Knowledge graph para arquitectura (opcional)
5. **GGA** - Se detecta automáticamente si está instalado en el sistema
6. **Confirmar** - Revisar resumen y crear proyecto

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

**Reglas:**
- Services NO pueden usar hooks ni importar componentes
- Components NO pueden contener lógica de negocio
- Lógica compartida va a `src/core/`

### Hexagonal (Clean Architecture)

```
src/
├── domain/              # Lógica de negocio pura (SIN dependencias externas)
│   ├── entities/        # Entidades del dominio
│   ├── value-objects/   # Objetos de valor
│   ├── services/        # Servicios de dominio
│   ├── events/          # Eventos de dominio
│   ├── exceptions/       # Excepciones del dominio
│   └── interfaces/       # Contratos (puertos de salida)
├── application/         # Casos de uso (depende de Domain)
│   ├── use-cases/       # Casos de uso
│   ├── dto/             # Data Transfer Objects
│   └── ports/           # Puertos de entrada/salida
├── infrastructure/      # Adaptadores (implementa interfaces de Domain/Application)
│   ├── persistence/     # Repositorios (Prisma)
│   ├── http/            # Controladores, middleware
│   ├── queue/           # Colas de mensajes
│   └── external/        # Servicios externos
└── shared/              # Utilidades compartidas
```

**Reglas absolutas:**
1. Domain NO puede importar de `application/`, `infrastructure/`, ni `shared/`
2. Application NO puede importar de `infrastructure/`
3. Todo en `infrastructure/` DEBE implementar interfaces de Domain/Application
4. NINGÚN archivo de dominio puede tener imports de frameworks externos

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
├── .env.template          # Variables de entorno (copiar a .env)
├── prisma/
│   └── schema.prisma      # Esquema de Prisma
├── .husky/               # Git hooks
├── .github/workflows/     # GitHub Actions
├── .vscode/settings.json  # Configuración VSCode
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
# Editar .env con tu URL de PostgreSQL

# 3. Generar cliente Prisma
bunx prisma generate

# 4. Crear base de datos y tablas
bunx prisma migrate dev --name init

# 5. Iniciar desarrollo
bun dev
```

### Variables de entorno (.env.template)

```env
# Database
DATABASE_URL="postgresql://USER:PASSWORD@HOST:5432/DATABASE?schema=public"

# Auth
JWT_SECRET="your-super-secret-jwt-token-change-in-production"
JWT_EXPIRES_IN="7d"

# App
APP_URL="http://localhost:3000"
NODE_ENV="development"
```

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
**Última modificación:** 2026-04-14
