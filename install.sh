#!/usr/bin/env bash

# ============================================================================
# SAI Toolbox Installer
# Instala init-projects globalmente para usar desde cualquier directorio.
# ============================================================================

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${CYAN}${BOLD}"
echo "  ╔═══════════════════════════════════════╗"
echo "  ║   SAI Toolbox Installer               ║"
echo "  ╚═══════════════════════════════════════╝"
echo -e "${NC}"

# Detectar SO
if [[ "$OSTYPE" == "darwin"* ]]; then
    INSTALL_DIR="$HOME/.local/bin"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    INSTALL_DIR="$HOME/.local/bin"
else
    echo -e "${RED}Error: Sistema operativo no soportado${NC}"
    exit 1
fi

# Crear directorio si no existe
mkdir -p "$INSTALL_DIR"

# URL del script
SCRIPT_URL="https://raw.githubusercontent.com/Sebailla/SAI-toolbox/main/init-project.sh"

echo -e "${CYAN}[1/3]${NC} Descargando init-projects..."
if ! curl -fsSL --connect-timeout 30 --max-time 120 "$SCRIPT_URL" -o "$INSTALL_DIR/init-projects.tmp"; then
    echo -e "${RED}Error: No se pudo descargar el script${NC}"
    exit 1
fi

# Verificar que el archivo no esté vacío y sea un script de bash válido
if [ ! -s "$INSTALL_DIR/init-projects.tmp" ]; then
    echo -e "${RED}Error: El archivo descargado está vacío${NC}"
    rm -f "$INSTALL_DIR/init-projects.tmp"
    exit 1
fi

if ! head -1 "$INSTALL_DIR/init-projects.tmp" | grep -q "^#!/"; then
    echo -e "${RED}Error: El archivo descargado no parece ser un script válido${NC}"
    rm -f "$INSTALL_DIR/init-projects.tmp"
    exit 1
fi

# Mover a destino final
mv "$INSTALL_DIR/init-projects.tmp" "$INSTALL_DIR/init-projects"

echo -e "${CYAN}[2/3]${NC} Haciendo ejecutable..."
chmod +x "$INSTALL_DIR/init-projects"

echo -e "${CYAN}[3/3]${NC} Configurando PATH..."

# Detectar shell profile
if [[ "$OSTYPE" == "darwin"* ]]; then
    SHELL_PROFILE="$HOME/.zshrc"
else
    SHELL_PROFILE="$HOME/.bashrc"
fi

# Agregar al PATH si no está
if [[ ":$PATH:" == *":$INSTALL_DIR:"* ]]; then
    echo -e "${GREEN}✓${NC} $INSTALL_DIR ya está en tu PATH"
else
    # Agregar al shell profile
    if ! grep -q "$INSTALL_DIR" "$SHELL_PROFILE" 2>/dev/null; then
        echo "" >> "$SHELL_PROFILE"
        echo "# SAI Toolbox" >> "$SHELL_PROFILE"
        echo "export PATH=\"\$PATH:$INSTALL_DIR\"" >> "$SHELL_PROFILE"
        echo -e "${GREEN}✓${NC} PATH agregado a $SHELL_PROFILE"
    else
        echo -e "${GREEN}✓${NC} PATH ya configurado en $SHELL_PROFILE"
    fi
    # Exportar para la sesión actual
    export PATH="$PATH:$INSTALL_DIR"
fi

echo ""
echo -e "${GREEN}✓${NC} Instalación completa!"
echo ""
echo -e "${BOLD}Uso:${NC}"
echo -e "  ${CYAN}init-projects${NC}"
echo ""
echo -e "${DIM}El script te hará preguntas interactivas para crear tu proyecto.${NC}"
