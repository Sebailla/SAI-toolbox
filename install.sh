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

log "\n${CYAN}${BOLD}"
echo "  ╔═══════════════════════════════════════╗"
echo "  ║   SAI Toolbox Installer               ║"
echo "  ╚═══════════════════════════════════════╝"
log "${NC}\n"

# Detectar SO
if [[ "$OSTYPE" == "darwin"* ]]; then
    INSTALL_DIR="$HOME/.local/bin"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    INSTALL_DIR="$HOME/.local/bin"
else
    log "${RED}Error: Sistema operativo no soportado${NC}\n"
    exit 1
fi

# Crear directorio si no existe
mkdir -p "$INSTALL_DIR"

# URL del script
SCRIPT_URL="https://raw.githubusercontent.com/Sebailla/SAI-toolbox/main/init-project.sh"

log "${CYAN}[1/3]${NC} Descargando init-projects...\n"
if ! curl -fsSL --connect-timeout 30 --max-time 120 "$SCRIPT_URL" -o "$INSTALL_DIR/init-projects.tmp"; then
    log "${RED}Error: No se pudo descargar el script${NC}\n"
    rm -f "$INSTALL_DIR/init-projects.tmp"
    exit 1
fi

# Verificar que el archivo no esté vacío y sea un script de bash válido
if [ ! -s "$INSTALL_DIR/init-projects.tmp" ]; then
    log "${RED}Error: El archivo descargado está vacío${NC}\n"
    rm -f "$INSTALL_DIR/init-projects.tmp"
    exit 1
fi

if ! head -1 "$INSTALL_DIR/init-projects.tmp" | grep -q "^#!/"; then
    log "${RED}Error: El archivo descargado no parece ser un script válido${NC}\n"
    rm -f "$INSTALL_DIR/init-projects.tmp"
    exit 1
fi

# Mover a destino final
mv "$INSTALL_DIR/init-projects.tmp" "$INSTALL_DIR/init-projects"

log "${CYAN}[2/3]${NC} Haciendo ejecutable...\n"
chmod +x "$INSTALL_DIR/init-projects"

log "${CYAN}[3/3]${NC} Configurando PATH...\n"

# Detectar shell activo (no solo OS)
SHELL_NAME=$(basename "$SHELL")
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
