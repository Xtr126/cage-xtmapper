#!/bin/bash

# cage-xtmapper automated dependency installer
# Designed for clean output and multi-distro support

set -e

# --- Configuration ---

DRY_RUN=false

while [ $# -gt 0 ]; do
    case "$1" in
        --dry-run)
            DRY_RUN=true
            ;;
        --help)
            echo "Usage: ./install_deps.sh [--dry-run] [--help]"
            exit 0
            ;;
    esac
    shift
done

log_status() {
    echo -e "\e[1;34m[*] $1\e[0m"
}

log_success() {
    echo -e "\e[1;32m[+] $1\e[0m"
}

log_error() {
    echo -e "\e[1;31m[!] $1\e[0m"
}

# Distro Detection
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
    LIKE=$ID_LIKE
else
    log_error "Cannot detect Linux distribution via /etc/os-release."
    exit 1
fi

# --- Package Definitions ---

DEBIAN_DEPS=(
    "build-essential" "git" "meson" "ninja-build" "pkg-config"
    "libwayland-dev" "libseat-dev" "libxkbcommon-dev" "libpixman-1-dev"
    "libudev-dev" "libinput-dev" "libdrm-dev" "libdisplay-info-dev"
    "libliftoff-dev" "hwdata" "scdoc" "libgbm-dev" "libgles-dev"
    "libegl-dev" "wayland-protocols"
)

FEDORA_DEPS=(
    "gcc" "git" "meson" "ninja-build" "pkgconf-pkg-config"
    "wayland-devel" "libxkbcommon-devel" "pixman-devel" "libinput-devel"
    "libdrm-devel" "mesa-libEGL-devel" "mesa-libGLES-devel" "mesa-libgbm-devel"
    "seatd-devel" "libdisplay-info-devel" "libliftoff-devel" "hwdata" "scdoc"
    "wayland-protocols-devel"
)

ARCH_DEPS=(
    "base-devel" "git" "meson" "ninja" "pkgconf" "wayland"
    "wayland-protocols" "libxkbcommon" "pixman" "libinput" "libdrm"
    "mesa" "seatd" "scdoc" "hwdata" "libdisplay-info" "libliftoff"
)

ALPINE_DEPS=(
    "build-base" "git" "meson" "ninja" "pkgconf" "wayland-dev"
    "libxkbcommon-dev" "pixman-dev" "libinput-dev" "libdrm-dev"
    "mesa-dev" "libseat-dev" "scdoc" "hwdata" "wayland-protocols"
)

# --- Configuration ---

INSTALL_CMD=""
UPDATE_CMD=""
FINAL_DEPS=()

if [[ "$DISTRO" == "ubuntu" || "$DISTRO" == "debian" || "$LIKE" == *"debian"* ]]; then
    log_status "Detected Debian-based system ($DISTRO)"
    INSTALL_CMD="apt-get install -y -q"
    UPDATE_CMD="apt-get update -q"
    FINAL_DEPS=("${DEBIAN_DEPS[@]}")
elif [[ "$DISTRO" == "fedora" ]]; then
    log_status "Detected Fedora system"
    INSTALL_CMD="dnf install -v -y"
    UPDATE_CMD="" # dnf updates cache automatically
    FINAL_DEPS=("${FEDORA_DEPS[@]}")
elif [[ "$DISTRO" == "arch" || "$LIKE" == *"arch"* ]]; then
    log_status "Detected Arch-based system ($DISTRO)"
    INSTALL_CMD="pacman -S --noconfirm --needed"
    UPDATE_CMD="pacman -Sy"
    FINAL_DEPS=("${ARCH_DEPS[@]}")
elif [[ "$DISTRO" == "alpine" ]]; then
    log_status "Detected Alpine system"
    INSTALL_CMD="apk add"
    UPDATE_CMD="apk update"
    FINAL_DEPS=("${ALPINE_DEPS[@]}")
else
    log_error "Unsupported distribution: $DISTRO"
    log_status "Please install the following dependencies manually:"
    echo "${DEBIAN_DEPS[*]}"
    exit 1
fi

# --- Execution ---

# Check for sudo
SUDO=""
if [ "$EUID" -ne 0 ]; then
    SUDO="sudo"
    if ! command -v sudo >/dev/null 2>&1; then
        log_error "Root privileges required but sudo not found."
        exit 1
    fi
    
    # Check for passwordless sudo
    if sudo -n true 2>/dev/null; then
        log_success "Passwordless escalation available."
    else
        log_status "Password required for dependency installation."
    fi
fi

if [ "$DRY_RUN" == true ]; then
    log_success "Dry-run complete. System detection and package mapping verified."
    exit 0
fi

log_status "Installing dependencies (${#FINAL_DEPS[@]} packages)..."
# We run the command and hide stdout to keep it clean, but keep stderr for troubleshooting
if $SUDO $INSTALL_CMD "${FINAL_DEPS[@]}" >/dev/null 2>/tmp/install_deps_error.log; then
    log_success "All dependencies installed successfully."
else
    log_error "Installation failed. Check /tmp/install_deps_error.log for details."
    cat /tmp/install_deps_error.log
    exit 1
fi
