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
echo "  ║   SAI Toolbox Installer              ║"
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
if ! curl -fsSL "$SCRIPT_URL" -o "$INSTALL_DIR/init-projects"; then
    echo -e "${RED}Error: No se pudo descargar el script${NC}"
    exit 1
fi

echo -e "${CYAN}[2/3]${NC} Haciendo ejecutable..."
chmod +x "$INSTALL_DIR/init-projects"

echo -e "${CYAN}[3/3]${NC} Verificando..."

# Verificar si está en PATH
if [[ ":$PATH:" == *":$INSTALL_DIR:"* ]]; then
    echo -e "${GREEN}✓${NC} $INSTALL_DIR ya está en tu PATH"
else
    echo -e "${YELLOW}!${NC} Agregá $INSTALL_DIR a tu PATH"
    echo ""
    echo -e "${BOLD}Agregá esta línea a tu ~/.zshrc o ~/.bashrc:${NC}"
    echo ""
    echo -e "  ${CYAN}export PATH=\"\$PATH:$INSTALL_DIR\"${NC}"
    echo ""
fi

echo ""
echo -e "${GREEN}✓${NC} Instalación completa!"
echo ""
echo -e "${BOLD}Uso:${NC}"
echo "  ${CYAN}init-projects mi-proyecto${NC}"
echo "  ${CYAN}init-projects mi-proyecto --agent claude --graphify --gga${NC}"
echo ""
echo -e "${DIM}Para ver todas las opciones: init-projects --help${NC}"
