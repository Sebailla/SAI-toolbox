#!/usr/bin/env bash

# ============================================================================
# SAI Toolbox Installer
# Instala init-projects globalmente para usar desde cualquier directorio.
# ============================================================================

set -e

# Colores usando ANSI-C quoting para obtener el caracter de escape real
RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[0;33m'
CYAN=$'\033[0;36m'
BOLD=$'\033[1m'
DIM=$'\033[2m'
NC=$'\033[0m'

# Helper para logs con color (printf '%b' interpreta \033 correctamente)
log() {
    printf '%b' "$1"
}

log_info()    { log "${CYAN}${BOLD}[INFO]${NC}   $*\n"; }
log_success() { log "${GREEN}${BOLD}[OK]${NC}     $*\n"; }
log_warn()    { log "${YELLOW}${BOLD}[WARN]${NC}  $*\n"; }
log_error()   { log "${RED}${BOLD}[ERROR]${NC}  $*\n" >&2; }

log "\n${CYAN}${BOLD}"
echo "  ╔═══════════════════════════════════════╗"
echo "  ║   SAI Toolbox Installer               ║"
echo "  ╚═══════════════════════════════════════╝"
log "${NC}\n"

# Detectar SO
if [[ "$OSTYPE" == "darwin"* ]]; then
    INSTALL_DIR="$HOME/.local/bin"
    EXTRACT_CMD="tar -xzf"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    INSTALL_DIR="$HOME/.local/bin"
    EXTRACT_CMD="tar -xzf"
else
    log_error "Sistema operativo no soportado\n"
    exit 1
fi

# Crear directorio si no existe
mkdir -p "$INSTALL_DIR"

# URL del tarball (rama configurable via SAI_BRANCH env var)
SAI_BRANCH="${SAI_BRANCH:-main}"
TARBALL_URL="https://github.com/Sebailla/SAI-toolbox/archive/refs/heads/${SAI_BRANCH}.tar.gz"

log "${CYAN}[1/4]${NC} Descargando SAI Toolbox...\n"
if ! curl -fsSL --connect-timeout 30 --max-time 120 "$TARBALL_URL" -o "$INSTALL_DIR/sai-toolbox.tar.gz"; then
    log_error "No se pudo descargar el tarball\n"
    rm -f "$INSTALL_DIR/sai-toolbox.tar.gz"
    exit 1
fi

# Verificar que el archivo no esté vacío
if [ ! -s "$INSTALL_DIR/sai-toolbox.tar.gz" ]; then
    log_error "El archivo descargado está vacío\n"
    rm -f "$INSTALL_DIR/sai-toolbox.tar.gz"
    exit 1
fi

log "${CYAN}[2/4]${NC} Extrayendo archivos...\n"
cd "$INSTALL_DIR"

# Extraer y obtener el nombre del directorio generado
EXTRACTED_DIR=$(tar -tzf "$INSTALL_DIR/sai-toolbox.tar.gz" | head -1 | cut -f1 -d"/")

# Limpiar instalación anterior si existe
if [ -d "$INSTALL_DIR/$EXTRACTED_DIR" ]; then
    rm -rf "$INSTALL_DIR/$EXTRACTED_DIR"
fi

# Extraer
if ! $EXTRACT_CMD "$INSTALL_DIR/sai-toolbox.tar.gz"; then
    log_error "Error al extraer el tarball\n"
    rm -f "$INSTALL_DIR/sai-toolbox.tar.gz"
    exit 1
fi

# Limpiar tarball
rm -f "$INSTALL_DIR/sai-toolbox.tar.gz"

# Verificar que existe init-project
if [ ! -d "$INSTALL_DIR/$EXTRACTED_DIR/init-project" ]; then
    log_error "Estructura de archivos inesperada en el tarball\n"
    rm -rf "$INSTALL_DIR/$EXTRACTED_DIR"
    exit 1
fi

# Crear symlink o copiar init-projects al directorio de instalación
log "${CYAN}[3/4]${NC} Instalando init-projects...\n"

# Remover versión anterior si existe
if [ -f "$INSTALL_DIR/init-projects" ]; then
    rm -f "$INSTALL_DIR/init-projects"
fi

# Copiar solo lo necesario (init-project.sh y el directorio lib/)
# en lugar de todo el repo
cp "$INSTALL_DIR/$EXTRACTED_DIR/init-project/init-project.sh" "$INSTALL_DIR/init-projects"
mkdir -p "$INSTALL_DIR/init-project"
cp -r "$INSTALL_DIR/$EXTRACTED_DIR/init-project/lib" "$INSTALL_DIR/init-project/"

# Hacer ejecutable
chmod +x "$INSTALL_DIR/init-projects"

# Limpiar directorio temporal
rm -rf "$INSTALL_DIR/$EXTRACTED_DIR"

log_success "init-projects instalado en $INSTALL_DIR/init-projects"

# Detectar shell activo usando múltiples métodos para mayor precisión
detect_shell() {
    # 1. Intentar desde el proceso padre (más confiable en Linux)
    if [ -f "/proc/$PPID/comm" ]; then
        local parent_shell=$(cat "/proc/$PPID/comm" 2>/dev/null)
        case "$parent_shell" in
            *zsh)  echo "zsh"; return ;;
            *bash) echo "bash"; return ;;
            *fish) echo "fish"; return ;;
        esac
    fi
    # 2. Intentar desde ps (funciona en macOS y Linux)
    if command -v ps &>/dev/null; then
        local current_shell=$(ps -p $$ -o comm= 2>/dev/null | tr -d ' ')
        case "$current_shell" in
            *zsh)  echo "zsh"; return ;;
            *bash) echo "bash"; return ;;
            *fish) echo "fish"; return ;;
        esac
    fi
    # 3. Fallback: usar SHELL env var
    basename "$SHELL"
}

SHELL_NAME=$(detect_shell)
case "$SHELL_NAME" in
    zsh)
        SHELL_PROFILE="$HOME/.zshrc"
        ;;
    bash)
        # Bash puede usar .bashrc o .bash_profile en macOS
        if [[ "$OSTYPE" == "darwin"* ]]; then
            SHELL_PROFILE="$HOME/.bash_profile"
        else
            SHELL_PROFILE="$HOME/.bashrc"
        fi
        ;;
    fish)
        SHELL_PROFILE="$HOME/.config/fish/config.fish"
        ;;
    *)
        # Fallback
        SHELL_PROFILE="$HOME/.profile"
        ;;
esac

# Agregar al PATH si no está
if [[ ":$PATH:" == *":$INSTALL_DIR:"* ]]; then
    log "${GREEN}✓${NC} $INSTALL_DIR ya está en tu PATH\n"
else
    # Agregar al shell profile
    if ! grep -q "$INSTALL_DIR" "$SHELL_PROFILE" 2>/dev/null; then
        echo "" >> "$SHELL_PROFILE"
        echo "# SAI Toolbox" >> "$SHELL_PROFILE"
        echo "export PATH=\"\$PATH:$INSTALL_DIR\"" >> "$SHELL_PROFILE"
        log "${GREEN}✓${NC} PATH agregado a $SHELL_PROFILE\n"
    else
        log "${GREEN}✓${NC} PATH ya configurado en $SHELL_PROFILE\n"
    fi
    # Exportar para la sesión actual
    export PATH="$PATH:$INSTALL_DIR"
fi

log "\n${GREEN}✓${NC} Instalación completa!\n"
log "${BOLD}Uso:${NC}\n"
log "  ${CYAN}init-projects${NC}\n"
log "${DIM}El script te hará preguntas interactivas para crear tu proyecto.${NC}\n"
