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

## 🧠 Pautas de Comportamiento (Behavioral Guidelines)

Estas reglas buscan reducir errores comunes y asegurar la calidad del código.

### 1. Pensar antes de codear
**No asumas. No ocultes confusión. Mostrá los tradeoffs.**
- Explicá tus suposiciones explícitamente. Si no estás seguro, PREGUNTÁ.
- Si hay varias interpretaciones, presentalas; no elijas en silencio.
- Si hay un enfoque más simple, decilo.
- Si algo no está claro, DETENETE. Decí qué te confunde y preguntá.

### 2. Simplicidad ante todo
**Código mínimo que resuelva el problema. Nada especulativo.**
- Sin features extra que no se pidieron.
- Sin abstracciones para código de un solo uso.
- Sin "flexibilidad" o "configurabilidad" no solicitada.
- Si escribiste 200 líneas y se podía en 50, REESCRIBILO.
- Preguntate: "¿Un senior diría que esto es demasiado complicado?". Si la respuesta es sí, simplificá.

### 3. Cambios Quirúrgicos
**Tocá solo lo necesario. Limpiá solo tu propio desorden.**
- No "mejores" código adyacente, comentarios o formato que no tocaste.
- No refactorices cosas que no están rotas.
- Mantené el estilo existente, aunque lo harías distinto.
- Si ves código muerto no relacionado, mencionalo pero NO lo borres.
- Remové imports/variables/funciones que TUS cambios dejaron sin uso.

### 4. Ejecución orientada a objetivos
**Definí criterios de éxito. Iterá hasta verificar.**
- Transformá tareas en metas verificables (ej: "Fix the bug" → "Escribir un test que lo reproduzca y luego hacerlo pasar").
- Para tareas de varios pasos, declará un plan breve:
  1. [Paso] → verificar: [check]
  2. [Paso] → verificar: [check]

## Contacto

Autor: Sebastián Illa
Repo: https://github.com/Sebailla/SAI-toolbox
