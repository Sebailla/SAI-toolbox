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

## Git Workflow (Lo más importante)

### Estructura de ramas

```
main ←───────────────────────────────────── producción (NUNCA tocar directo)
  ↑                      ↑
  │                      │ merge desde develop
  │                      │
develop ←── feat/mi-feature ←── fix/bug ←── chore/update
```

### Crear commits automáticos

```bash
# Asegurate de estar en develop
git checkout develop

# Crear un commit (crea rama + corre tests + corre GGA + commit)
git c "agrego login con JWT"

# Output:
#   ▸ Tipo:    feat
#   ▸ Rama:    feat/agrego-login-con-jwt
#   ▸ Msg:     agrego login con JWT
#   
#   ✓ Tests OK
#   ✓ GGA OK (si está instalado)
#   ✓ Commit creado
```

### Workflow completo

```bash
# 1. Crear commit (desde develop)
git c "agrego módulo de usuarios"

# 2. Push y crear PR
git push -u origin feat/agrego-modulo-de-usuarios

# 3. Merge a develop (vía PR o manualmente)
git checkout develop
git merge feat/agrego-modulo-de-usuarios

# 4. Cuando esté listo para producción
git checkout main
git merge develop
bun run release  # bumps a 1.1.0, actualiza CHANGELOG, crea tag
```

---

## Comandos disponibles

### Desarrollo
```bash
bun dev              # Desarrollo (localhost:3000)
bun build            # Build de producción
bun start            # Iniciar producción
```

### Testing
```bash
bun test             # Tests unitarios (Vitest)
bun test:e2e         # Tests E2E (Playwright)
bun test:watch       # Tests en watch mode
bun test:coverage    # Coverage report
```

### Linting
```bash
bun lint             # Linting
bun lint:fix         # Linting con fixes automáticos
```

### Base de datos
```bash
bun db:generate      # Generar cliente Prisma
bun db:migrate       # Correr migraciones
bun db:push          # Push cambios a DB (desarrollo)
bun db:seed          # Seed data
bun db:studio        # UI de Prisma
bun db:reset         # Reset DB (⚠️ borra datos)
```

### Releases
```bash
bun run release      # Crear release (bumps version + CHANGELOG + tag)
```

### Git
```bash
git c "mensaje"      # Commit automático (creas desde develop)
git c --help         # Ver ayuda del commit automático
```

---

## Estructura inicial

```
mi-proyecto/
├── src/
│   ├── modules/              # (Modular)
│   │   └── example/
│   │       ├── components/
│   │       ├── services/
│   │       ├── actions.ts
│   │       ├── types.ts
│   │       └── index.ts
│   ├── core/                # Utilidades compartidas
│   └── app/                 # Next.js App Router
│       └── api/             # API routes
├── prisma/
│   └── schema.prisma         # Definición de tu base de datos
├── .env                      # Variables de entorno (NO commitear)
├── .env.template             # Template para copiar
├── CHANGELOG.md              # Historial de cambios
├── VERSION                   # Versión actual
├── AGENTS.md                 # Reglas para agentes de IA
├── git-c                     # Script de commit automático
└── .husky/                   # Git hooks
```

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

### Tests fallan en commit

```bash
# Correr tests manualmente para ver el error
bun test --run

# Fixear los tests y volver a intentar
git c "fix: tests rotos"
```

### GGA encontró errores

```bash
# GGA te va a mostrar los errores antes de commitear
# Corregilos y volvé a intentar
git c "fix: corrijo errores de GGA"
```

---

## Próximos pasos

1. Leé la documentación de arquitectura:
   - `.docs/Arquitectura-Modular.md`
   - `.docs/Arquitectura-Hexagonal.md`
   - `.docs/Git-Workflow.md`

2. Configurá tu agente de IA favorito con `AGENTS.md`

3. Empezá a codear en una branch `feat/` usando `git c`

4. Si tenés GGA instalado, el code review corre automático en cada commit
