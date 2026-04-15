# Git Workflow - SAI Toolbox

**Autor:** Sebastián Illa  
**Fecha:** 2026-04-14  
**Última modificación:** 2026-04-14

---

## Concepto

El workflow está diseñado para:
1. **Proteger `main`** - Solo recibe merges de `develop`
2. **Facilitar colaboración** - Cada feature en su propia rama
3. **Automatizar validaciones** - Tests y GGA antes de cada commit
4. **Versionado semántico** - Releases automáticos con CHANGELOG

---

## Estructura de Ramas

```
main          ←── producción (protegida, solo merges de develop)
  ↑
  │         Tag: v1.0.0, v1.1.0, v2.0.0
  │
develop      ←── rama de trabajo permanente
  ↑
  │         Cada commit de feature/fix/chore
  │
feat/xxx     ←── ramas temporales por feature
fix/xxx
chore/xxx
docs/xxx
```

---

## Flujo Completo

### 1. Día a día: Trabajar en un feature

```bash
# Asegurate de estar en develop
git checkout develop

# Crear commit (automatiza TODO el flujo)
git c "agrego login con JWT"

# Output:
#   ▸ Tipo:    feat
#   ▸ Rama:    feat/agrego-login-con-jwt
#   ▸ Msg:     agrego login con JWT
#   
#   ✓ Hay cambios para commitear
#   ▸ Corriendo tests...
#   ✓ Tests OK
#   ▸ Code review con GGA...
#   ✓ GGA OK
#   
#   ▸ Creando rama y commit...
#   
#   ✓ Commit creado en rama feat/agrego-login-con-jwt
```

### 2. Push y crear PR

```bash
# Push la rama
git push -u origin feat/agrego-login-con-jwt

# Crear PR en GitHub o mergear manualmente
git checkout develop
git merge feat/agrego-login-con-jwt
git push origin develop
```

### 3. Release a producción

```bash
# Asegurar que todo está en develop
git checkout develop
git pull origin develop

# Hacer merge a main
git checkout main
git merge develop

# Crear release (bumps version, actualiza CHANGELOG, crea tag)
bun run release

# Push con tags
git push origin main --follow-tags
```

---

## El Script `git c`

### Qué hace automáticamente

1. **Verifica** que estés en `develop`
2. **Detecta** el tipo de cambio:
   - `feat` - Nuevos archivos en `src/`
   - `fix` - Archivos en `src/` con "fix" en el mensaje
   - `docs` - Archivos `.md`
   - `chore` - Config, scripts, deps
   - `test` - Archivos de test

3. **Genera** nombre de rama: `tipo/nombre-en-kebab-case`

4. **Corre tests**: `bun test --run`

5. **Corre GGA**: Si está instalado, hace code review

6. **Crea** la rama y hace el commit

### Uso

```bash
git c "agrego login con JWT"           # feat
git c "fix: bug en logout"             # fix
git c "docs: actualizo README"        # docs
git c "chore: actualizo dependencias" # chore
git c --help                          # Ver ayuda
```

### Si algo falla

Si los **tests fallan**:
```
✗ Tests fallaron. Corregí antes de commitear.
```
Fixeá los tests y volvé a ejecutar.

Si **GGA encuentra errores**:
```
✗ GGA encontró errores. Corregí antes de commitear.
```
GGA te muestra los problemas. Corregilos y volvé a ejecutar.

---

## Conventional Commits

El proyecto usa [Conventional Commits](https://www.conventionalcommits.org/):

```
<tipo>: <descripción>

[opcional body]

[opcional footer]
```

### Tipos

| Tipo | Uso | Ejemplo |
|------|-----|---------|
| `feat` | Nueva funcionalidad | `feat: agrego login con JWT` |
| `fix` | Corrección de bug | `fix: corrijo logout que no funciona` |
| `chore` | Mantenimiento | `chore: actualizo dependencias` |
| `docs` | Documentación | `docs: actualizo README` |
| `refactor` | Refactoring | `refactor: extraigo auth service` |
| `test` | Tests | `test: agrego tests para login` |
| `perf` | Performance | `perf: optimizo query de usuarios` |
| `ci` | CI/CD | `ci: agrego GitHub Actions` |

### Reglas

- **Siempre en inglés** para el mensaje (internacionalización)
- **Lowercase** para el tipo
- ** Imperativo**: "agrego" no "agregué"
- **Máximo 72 caracteres** en la primera línea

---

## Versionado Semántico

El proyecto usa [Semantic Versioning](https://semver.org/):

```
MAJOR.MINOR.PATCH
  │      │     │
  │      │     └── Bug fixes
  │      └──────── Nuevas features (backward compatible)
  └─────────────── Breaking changes
```

### Bumps automáticos

```bash
# Patch: 1.0.0 → 1.0.1 (fixes)
# Minor: 1.0.1 → 1.1.0 (features)
# Major: 1.1.0 → 2.0.0 (breaking changes)
```

standard-version detecta el tipo de cambio por el prefijo del commit:
- `feat:` → Minor bump
- `fix:` → Patch bump
- `feat!:` o `fix!:` → Major bump

---

## Hooks de Git

### pre-commit

```bash
bun test        # Corre tests
bunx lint-staged  # Linting en archivos staged
gga run         # Code review con GGA (si está instalado)
```

### commit-msg

```bash
bunx --no -- commitlint --edit $1
```

Valida que el mensaje de commit siga Conventional Commits.

### pre-push

```bash
# Verifica que no estés pusheando a main/master directo
# Verifica que el nombre de la rama siga el formato
```

---

## Tips

### Deshacer el último commit

```bash
git reset --soft HEAD~1
```

### Ver todos los commits

```bash
git log --oneline --graph --all
```

### Ver estado actual

```bash
git status
git branch -a
```

### Limpiar ramas merged

```bash
git branch --merged develop | grep -v develop | xargs git branch -d
```

---

## Reglas de Oro

1. **Nunca commitear directo a `develop` o `main`**
2. **Siempre usar `git c`** para crear commits
3. **Siempre estar en `develop`** antes de hacer `git c`
4. **Si GGA o tests fallan, NO commitear** hasta corregir
5. **Hacer merge de `develop` a `main`** antes de release
6. **Ejecutar `bun run release`** antes de pushear a main
