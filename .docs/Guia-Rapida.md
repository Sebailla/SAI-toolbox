# Guía Rápida - SAI Toolbox

**Autor:** Sebastián Illa  
**Fecha:** 2026-04-14  
**Última modificación:** 2026-04-14

---

## Instalación

### 1. Instalar el comando global

```bash
curl -fsSL https://raw.githubusercontent.com/Sebailla/SAI-toolbox/main/install.sh | bash
```

Esto instala `init-projects` en `~/.local/bin/` y agrega el PATH a tu shell config.

### 2. Crear un proyecto

```bash
init-projects
```

Seguí las instrucciones en pantalla:

```
  ▸ Paso 1 ─── Nombre del proyecto
  ▸ Paso 2 ─── Arquitectura (Modular o Hexagonal)
  ▸ Paso 3 ─── Agente de IA
  ▸ Paso 4 ─── Graphify
  ▸ Paso 5 ─── Confirmar
```

---

## Después de crear el proyecto

```bash
cd mi-proyecto

# 1. Instalar dependencias
bun install

# 2. Configurar .env
cp .env.template .env
# Editar DATABASE_URL con tu PostgreSQL

# 3. Generar cliente Prisma
bunx prisma generate

# 4. Crear tablas en la base de datos
bunx prisma migrate dev --name init

# 5. Iniciar desarrollo
bun dev
```

---

## Estructura inicial

```
mi-proyecto/
├── src/
│   ├── modules/              # (Modular) o domain/application/infrastructure (Hexagonal)
│   ├── core/                # Utilidades compartidas
│   └── app/                 # Next.js App Router
├── prisma/
│   └── schema.prisma         # Definición de tu base de datos
├── .env                      # Variables de entorno (NO commitear)
├── .env.template             # Template para copiar
├── AGENTS.md                # Reglas para agentes de IA
└── .husky/                   # Git hooks
```

---

## Comandos disponibles

```bash
bun dev              # Desarrollo
bun build            # Build de producción
bun test             # Tests unitarios (Vitest)
bun test:e2e         # Tests E2E (Playwright)
bun test:watch       # Tests en watch mode
bun lint             # Linting
bun lint:fix         # Linting con fixes automáticos
bun db:generate      # Generar cliente Prisma
bun db:migrate       # Correr migraciones
bun db:push          # Push cambios a DB (desarrollo)
bun db:seed          # Seed data
bun db:studio        # UI de Prisma
bun release          # Crear release (Standard Version)
```

---

## Trabajar con Git

```bash
# Crear branch para feature
git checkout -b feat/mi-nueva-feature

# Commit (el hook de commitlint valida el formato)
git add .
git commit -m "feat: descripción de lo que hacés"

# Push y crear PR
git push origin feat/mi-nueva-feature
```

### Formato de commits

```
feat: nueva funcionalidad
fix: corrección de bug
hotfix: corrección urgente en producción
chore: tareas de mantenimiento
docs: documentación
refactor: refactoring sin cambiar funcionalidad
test: agregar tests
```

---

## Roles de IA

El proyecto viene con reglas para agentes de IA configuradas en `AGENTS.md`:

- **OpenCode:** usa `AGENTS.md`
- **Claude:** copia a `CLAUDE.md`
- **Cursor:** copia a `.cursorrules`
- **Gemini:** copia a `GEMINI.md`

Estas reglas definen:
- Comunicación en Español Rioplatense
- Fundamentación obligatoria (por qué + cómo)
- Arquitectura estricta (Hexagonal o Modular)
- SDD workflow obligatorio
- GGA code review obligatorio

---

## Errores comunes

### "command not found: init-projects"

```bash
# Agregá manualmente al PATH
export PATH="$PATH:$HOME/.local/bin"

# O reabrí tu terminal
```

### "DATABASE_URL" not set

```bash
# Editá .env y configurá tu PostgreSQL
DATABASE_URL="postgresql://user:password@localhost:5432/mydb"
```

### Husky hooks no funcionan

```bash
# Reinstalar hooks
bunx husky init
```

---

## Próximos pasos

1. Leé la documentación de arquitectura:
   - `.docs/Arquitectura-Modular.md`
   - `.docs/Arquitectura-Hexagonal.md`

2. Configurá tu agente de IA favorito con `AGENTS.md`

3. Empezá a codear en una branch `feat/`

4. Si tenés GGA instalado, el code review corre automático en cada commit
