#!/usr/bin/env bash

# ============================================================================
# Core - Constants, Colors, Logging, Cleanup, Banner, Timeout
# ============================================================================

# Colores usando ANSI-C quoting para portabilidad
RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[0;33m'
CYAN=$'\033[0;36m'
MAGENTA=$'\033[0;35m'
WHITE=$'\033[0;37m'
BOLD=$'\033[1m'
DIM=$'\033[2m'
NC=$'\033[0m'

# ============================================================================
# Global State Variables
# ============================================================================

ORIGINAL_DIR=$(pwd)
PROJECT_CREATED=0
CLEANUP_DONE=0

# ============================================================================
# Logging Functions
# ============================================================================

log() {
    printf '%b' "$1"
}

log_info()    { log "${CYAN}${BOLD}[INFO]${NC}   $*\n"; }
log_success() { log "${GREEN}${BOLD}[OK]${NC}     $*\n"; }
log_warn()    { log "${YELLOW}${BOLD}[WARN]${NC}  $*\n"; }
log_error()   { log "${RED}${BOLD}[ERROR]${NC}  $*\n" >&2; }

# ============================================================================
# Cleanup Handler
# ============================================================================

cleanup() {
    local exit_code=${1:-0}
    local already_cleaned=0
    if [ "$CLEANUP_DONE" -eq 1 ]; then
        return
    fi
    CLEANUP_DONE=1
    already_cleaned=1

    # Cambiar al directorio original solo si existe
    if [ -d "$ORIGINAL_DIR" ]; then
        cd "$ORIGINAL_DIR" 2>/dev/null || cd /tmp
    else
        cd /tmp 2>/dev/null || true
    fi

    if [ "$PROJECT_CREATED" -eq 1 ]; then
        # El proyecto se creó pero algo falló después
        log "${RED}${BOLD}[FATAL]${NC} El script no terminó correctamente. Deshaciendo...\n"
        if [ -n "$PROJECT_NAME" ] && [ -d "$ORIGINAL_DIR/$PROJECT_NAME" ]; then
            log_warn "Borrando directorio a medio crear: $PROJECT_NAME"
            rm -rf "$ORIGINAL_DIR/$PROJECT_NAME"
        fi
    fi
    # Only exit 1 if there was an error
    if [ "$exit_code" -ne 0 ]; then
        exit 1
    fi
}

trap 'cleanup $?' EXIT INT TERM

# ============================================================================
# Banner
# ============================================================================

print_banner() {
    log "${CYAN}${BOLD}"
    echo "  ╔═══════════════════════════════════════════════╗"
    echo "  ║   SAI Project Initializer                     ║"
    echo "  ║   Arquitectura Modular o Hexagonal            ║"
    echo "  ╚═══════════════════════════════════════════════╝"
    log "${NC}"
    echo ""
}

# ============================================================================
# Timeout portable (macOS no tiene timeout, usa gtimeout o perl)
# ============================================================================

run_with_timeout() {
    local seconds=$1
    shift
    local cmd=("$@")

    # Intentar timeout nativo (Linux)
    if command -v timeout &>/dev/null; then
        timeout "$seconds" "${cmd[@]}"
        return $?
    fi

    # Intentar gtimeout (macOS con GNU coreutils)
    if command -v gtimeout &>/dev/null; then
        gtimeout "$seconds" "${cmd[@]}"
        return $?
    fi

    # Perl fallback - use alarm + system instead of IPC::Open3 to avoid deadlock
    if command -v perl &>/dev/null; then
        perl -e '
            use strict;
            use warnings;
            my $secs = shift @ARGV;
            $SIG{ALRM} = sub { exit 124 };
            alarm($secs);
            system(@ARGV);
            my $cmd_exit = $?;
            alarm(0);
            exit $cmd_exit;
        ' "${seconds}" "${cmd[@]}"
        return $?
    fi

    # Si nada funciona, ejecutar sin timeout
    "${cmd[@]}"
}