# 🚀 SAI Project Initializer

**Script para crear proyectos Next.js production-ready con un solo comando.**

Crea un proyecto completo con Next.js, TypeScript, Tailwind CSS v4, Prisma, y toda la configuración de desarrollo lista para usar.

---

## ✨ Features

| Feature | Descripción |
|---------|-------------|
| **Next.js 16** | App Router, TypeScript, Tailwind CSS v4 |
| **Stack SAI** | Prisma, Zod, Vitest, Playwright, Husky |
| **Git hooks** | Commitlint + Conventional Commits + branch naming |
| **Skills para IA** | Documentación automática y planificación |
| **Graphify** | Knowledge graph para arquitectura (opcional) |
| **GGA** | Code review con IA (opcional) |

---

## ⚡ Uso

### Instalación global (recomendado)

```bash
# Instalar una vez
curl -fsSL https://raw.githubusercontent.com/Sebailla/SAI-toolbox/main/install.sh | bash

# Usar desde cualquier directorio
init-projects mi-proyecto
```

### Uso directo (sin instalación)

```bash
curl -fsSL https://raw.githubusercontent.com/Sebailla/SAI-toolbox/main/init-project.sh | bash -s -- mi-proyecto
```

---

## 🎯 Opciones

| Opción | Descripción |
|--------|-------------|
| `--agent` | Agente de IA: `opencode`, `claude`, `cursor`, `gemini`, `all` |
| `--graphify` | Habilitar knowledge graph |
| `--gga` | Habilitar Gentleman Guardian Angel (code review con IA) |

### Ejemplos

```bash
# Proyecto básico
./init-project.sh mi-proyecto

# Con Graphify
./init-project.sh mi-proyecto --graphify

# Con todo: agente, Graphify y GGA
./init-project.sh mi-proyecto --agent claude --graphify --gga

# Para todos los agentes
./init-project.sh mi-proyecto --agent all
```

---

## 📦 Qué se crea

```
mi-proyecto/
├── src/
│   ├── modules/           # Vertical slicing modules
│   │   └── example/
│   │       ├── components/
│   │       ├── services/
│   │       ├── actions.ts
│   │       └── types.ts
│   ├── core/             # Shared utilities
│   └── components/ui/    # Generic UI components
├── prisma/               # Database schema
├── .husky/               # Git hooks
├── .github/workflows/    # CI/CD
├── AGENTS.md             # AI agent rules
└── package.json
```

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
