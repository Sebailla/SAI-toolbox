# Skill Registry

**Author:** Sebastián Illa  
**Created:** 2026-04-16  
**Last Updated:** 2026-04-16

---

## Project: SAI-toolbox

CLI tool que crea proyectos production-ready mediante scripts shell interactivos.

---

## Skills Disponibles (este proyecto)

> Este proyecto es una herramienta de scaffolding, no un proyecto de aplicación. Los skills SDD están disponibles para cuando se necesite desarrollar features o cambios en el tool mismo.

### SDD (Spec-Driven Development)

| Skill | Descripción | Trigger |
|-------|-------------|---------|
| `sdd-init` | Inicializa contexto SDD en el proyecto | `sdd init`, "iniciar sdd" |
| `sdd-explore` | Explora e investiga ideas antes de commitear | Lanzado por orquestador |
| `sdd-propose` | Crea propuesta formal de cambio | Lanzado por orquestador |
| `sdd-spec` | Escribe especificaciones con requirements y scenarios | Lanzado por orquestador |
| `sdd-design` | Documenta diseño técnico con arquitectura | Lanzado por orquestador |
| `sdd-tasks` | Divide en tareas implementables | Lanzado por orquestador |
| `sdd-apply` | Implementa tareas siguiendo spec y design | Lanzado por orquestador |
| `sdd-verify` | Valida implementación contra specs | Lanzado por orquestador |
| `sdd-archive` | Guarda specs y cleanup | Lanzado por orquestador |

### Code Review

| Skill | Descripción | Trigger |
|-------|-------------|---------|
| `judgment-day` | Revisión adversarial con dos agentes ciegos | "judgment day", "juzgar" |

---

## Skills Disponibles (global, ~/.kilocode/skills)

### Frameworks & Libraries

| Skill | Descripción | Trigger |
|-------|-------------|---------|
| `typescript` | TypeScript strict patterns | Código TypeScript |
| `react-19` | React 19 + React Compiler | Componentes React |
| `nextjs-15` | Next.js 15 App Router | Proyectos Next.js |
| `angular-architecture` | Arquitectura Angular | Proyectos Angular |
| `angular-core` | Angular standalone, signals, inject | Componentes Angular |
| `angular-forms` | Angular forms reactivos | Formularios Angular |
| `angular-performance` | Angular performance, @defer, lazy | Optimizar Angular |
| `tailwind-4` | Tailwind CSS 4 patterns | Estilos con Tailwind |
| `zod-4` | Zod schema validation | Validación con Zod |
| `zustand-5` | Zustand state management | Estado React con Zustand |
| `ai-sdk-5` | Vercel AI SDK 5 | Features de AI chat |
| `django-drf` | Django REST Framework | APIs REST con Django |
| `go-testing` | Go testing patterns, Bubbletea TUI | Tests en Go |
| `pytest` | Pytest patterns | Tests en Python |
| `playwright` | Playwright E2E testing | Tests E2E |

### Project & Workflow

| Skill | Descripción | Trigger |
|-------|-------------|---------|
| `skill-registry` | Escanea y actualiza el registry | "update skills", "skill registry" |
| `skill-creator` | Crea nuevas skills | "crear skill", "nueva skill" |
| `branch-pr` | PR creation workflow | Crear PR, pull request |
| `issue-creation` | GitHub issue workflow | Crear issue, reportar bug |
| `github-pr` | Conventional commits + PR description | Pull requests |
| `interface-design` | Dashboards, admin panels, apps | Diseño de interfaces |

---

## Project Conventions

### Archivos de configuración de agentes

- `.agent/AGENTS.md` — Reglas principales para agentes IA
- `AGENTS.md` — Copia para Claude Code
- `GEMINI.md` — Copia para Gemini CLI
- `.cursorrules` — Copia para Cursor

### Convenciones de código Shell

1. **Portabilidad**: Bash 3.2+ compatible
2. **Colores ANSI**: Formato `$'\033['` o `\e[`
3. **Sed**: `sed -i ''` (BSD) / `sed -i''` (GNU) detectando SO
4. **Timeout**: `timeout` → `gtimeout` → `perl -e 'alarm...'`

### Documentación

- **Idioma**: Español (Rioplatense)
- **Autor**: Sebastián Illa
- **Ubicación docs**: `.docs/`
- **Formato fecha**: ISO 8601

---

## Ubicación de Skills

```
Global: ~/.config/kilo/skills/
User:   ~/.kilocode/skills/
Project: .agent/skills/
```

---

**Nota:** Este registry es generado automáticamente por `skill-registry`. Para actualizar, ejecutar el skill correspondiente.
