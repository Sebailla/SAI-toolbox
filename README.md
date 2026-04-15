# 🚀 SAI Project Initializer

**Script para crear proyectos Next.js production-ready con un solo comando.**

Crea un proyecto completo con Next.js, TypeScript, Tailwind CSS v4, Prisma, y toda la configuración de desarrollo lista para usar.

---

## ✨ Features

| Feature | Descripción |
|---------|-------------|
| **Next.js 16** | App Router, TypeScript, Tailwind CSS v4 |
| **Stack SAI** | Prisma, Zod, Vitest, Playwright, Husky |
| **Arquitecturas** | Modular Vertical Slicing o Hexagonal (Clean Architecture) |
| **Git hooks** | Commitlint + Conventional Commits + branch naming + GGA |
| **Skills para IA** | Documentación automática y planificación |
| **Graphify** | Knowledge graph para arquitectura (opcional) |
| **GGA** | Code review con IA en cada commit (automático si está instalado) |

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

El script es **completamente interactivo**. Solo ejecutá `init-projects` y te hará preguntas:

1. **Nombre del proyecto** - El nombre de la carpeta
2. **Arquitectura** - Modular o Hexagonal (Clean Architecture)
3. **Agente de IA** - OpenCode, Claude, Cursor, Gemini o todos
4. **Graphify** - Knowledge graph para arquitectura
5. **GGA** - Se detecta automáticamente si está instalado
6. **Confirmar** - Revisar y crear

### Ejemplos

```bash
# Básico (te preguntará todo)
init-projects

# Directo (sin instalación)
curl -fsSL https://raw.githubusercontent.com/Sebailla/SAI-toolbox/main/init-project.sh | bash
```

---

## 📦 Estructuras disponibles

### Modular Vertical Slicing

```
src/
├── modules/              # Features/módulos
│   └── example/
│       ├── components/
│       ├── services/
│       ├── actions.ts
│       └── types.ts
├── core/                 # Utilidades compartidas
└── components/ui/        # UI genérica
```

### Hexagonal (Clean Architecture)

```
src/
├── domain/              # Lógica de negocio pura (sin dependencias)
│   ├── entities/
│   ├── value-objects/
│   ├── services/
│   ├── events/
│   ├── exceptions/
│   └── interfaces/      # Puertos (contratos)
├── application/         # Casos de uso
│   ├── use-cases/
│   ├── dto/
│   └── ports/           # Puertos de entrada/salida
├── infrastructure/      # Adaptadores externos
│   ├── persistence/     # Repositorios (Prisma)
│   ├── http/            # Controladores, middleware
│   ├── queue/           # Colas de mensajes
│   └── external/        # Servicios externos
└── shared/              # Utilidades compartidas
```

**Regla de dependencia:** Domain → Application → Infrastructure (nunca al revés)

---

## 🛠️ Stack Tecnológico

- **Framework:** Next.js 16 (App Router)
- **Styling:** Tailwind CSS v4
- **Database:** Prisma + PostgreSQL
- **Validation:** Zod
- **Testing:** Vitest + Playwright
- **Git:** Husky + Commitlint + Standard Version
- **AI Skills:** Documentación y planificación

---

## 🔧 Post-Instalación

```bash
cd mi-proyecto
bun install          # Instalar dependencias
bunx prisma migrate dev  # Migrar base de datos
bun dev              # Iniciar desarrollo
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
**Creado:** 2026-04-14  
**Última modificación:** 2026-04-14
