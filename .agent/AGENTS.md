# AGENTS.md — SAI Toolbox

**Instrucciones para agentes de IA que trabajan en este proyecto.**

## Proyecto

SAI Toolbox es un script de shell que inicializa proyectos Next.js con arquitecturas Modular o Hexagonal. Está escrito en Bash puro para máxima compatibilidad (macOS + Linux).

## stack Tecnológico

- **Shell**: Bash 3.2+ (POSIX compliant)
- **Git**: Workflow de 3 ramas (main → develop → feat/fix/chore)
- **Versionado**: Semantic Versioning con standard-version
- **Code Review**: GGA (Gentleman Guardian Angel) en cada commit
- **Documentación**: Markdown, llms.txt

## Reglas del Proyecto

### Reglas de Código

1. **Shell portability**: Usar solo features compatibles con Bash 3.2
   - `[[ ]]` en lugar de `[ ]` para condicionales
   - `$()` en lugar de backticks
   - Evitar `mapfile`/`readarray` (no disponible en todas partes)

2. **Colores ANSI**: Usar formato ANSI-C `$'\033['` o `\e[`
   - Ejemplo: `RED=$'\033[0;31m'` o `RED='\e[0;31m'`

3. **Sed compatibility**: Usar `sed -i ''` (BSD) Y `sed -i''` (GNU) detectando el SO
   - Alternativa: usar `sed -i.bak` + `rm *.bak`

4. **Timeout portable**: Verificar `timeout` → `gtimeout` → `perl -e 'alarm...'`

### Reglas de Git

1. **Commits**: Conventional Commits (`feat:`, `fix:`, `docs:`, `chore:`, `test:`)
2. **Ramas**: Siempre desde `develop`, nunca commitear directo a `main`
3. **GGA**: El hook pre-commit corre GGA review automáticamente

### Reglas de Documentación

1. **Idioma**: Español (Rioplatense) para documentación
2. **Autor**: Sebastián Illa en todos los archivos
3. **Fecha**: Incluir `created` y `modified`
4. **Ubicación**: Archivos de docs en `.docs/`

## Estructura del Proyecto

```
SAI-toolbox/
├── init-project.sh      # Script principal de inicialización
├── install.sh           # Instalador global
├── README.md            # Documentación principal
├── llms.txt             # Contexto para LLMs
├── .docs/               # Documentación adicional
│   ├── Guia-Rapida.md
│   ├── Arquitectura-Modular.md
│   ├── Arquitectura-Hexagonal.md
│   └── Git-Workflow.md
├── .gitignore
└── .agent/              # Este archivo
```

## Workflow para Agentes

### Antes de hacer cambios

1. Leer `.agent/AGENTS.md` (este archivo)
2. Leer `README.md` para contexto del proyecto
3. Verificar branch actual: `git branch --show-current`
4. Solo trabajar desde `develop` o ramas `feat/*`/`fix/*`

### Después de cambios

1. Verificar sintaxis: `bash -n script.sh`
2. Testear en macOS y Linux si es posible
3. Hacer commit con conventional commit
4. Ejecutar `git c` (automatiza tests + GGA)

### Code Review (Judgment Day)

Cuando se solicite "judgment day":
1. Lanzar dos agentes independientes a revisar el mismo código
2. Sintetizar findings y priorizarlos (CRITICAL/HIGH/MEDIUM)
3. Aplicar fixes para todos los CRITICAL
4. Repetir hasta que ambos agentes pasen

## Comandos Útiles

```bash
# Inicializar proyecto
./init-project.sh

# Instalar globalmente
./install.sh

# Crear commit automático
git c "mensaje"

# Verificar sintaxis Bash
bash -n script.sh

# Ejecutar todos los tests
bun test --run
```

## Contacto

Autor: Sebastián Illa
Repo: https://github.com/Sebailla/SAI-toolbox
