#!/usr/bin/env bash
set -Eeuo pipefail

# Adapted from @SoufianoDev's dependency installer in PR #18,
# incorporated by PR #25: https://github.com/Xtr126/cage-xtmapper/pull/18

dry_run=false
while (($#)); do
    case "$1" in
        --dry-run) dry_run=true ;;
        -h|--help)
            echo "Usage: install_deps.sh [--dry-run]"
            exit 0
            ;;
        *)
            echo "Unknown argument: $1" >&2
            exit 2
            ;;
    esac
    shift
done

if [[ ! -r /etc/os-release ]]; then
    echo "Cannot detect Linux distribution from /etc/os-release." >&2
    exit 1
fi

distro="$(awk -F= '$1 == "ID" {gsub(/"/, "", $2); print $2}' /etc/os-release)"
distro_like="$(awk -F= '$1 == "ID_LIKE" {gsub(/"/, "", $2); print $2}' /etc/os-release)"

debian_deps=(
    build-essential git meson ninja-build pkg-config
    libwayland-dev libseat-dev libxkbcommon-dev libpixman-1-dev
    libudev-dev libinput-dev libdrm-dev libdisplay-info-dev
    libliftoff-dev hwdata scdoc libgbm-dev libgles-dev libegl-dev
    wayland-protocols
)

fedora_deps=(
    gcc git meson ninja-build pkgconf-pkg-config
    wayland-devel libxkbcommon-devel pixman-devel libinput-devel
    libdrm-devel mesa-libEGL-devel mesa-libGLES-devel mesa-libgbm-devel
    seatd-devel libdisplay-info-devel libliftoff-devel hwdata scdoc
    wayland-protocols-devel
)

arch_deps=(
    base-devel git meson ninja pkgconf wayland wayland-protocols
    libxkbcommon pixman libinput libdrm mesa seatd scdoc hwdata
    libdisplay-info libliftoff
)

alpine_deps=(
    build-base git meson ninja pkgconf wayland-dev libxkbcommon-dev
    pixman-dev libinput-dev libdrm-dev mesa-dev libseat-dev scdoc
    hwdata wayland-protocols
)

update_cmd=()
install_cmd=()
packages=()
if [[ "$distro" == ubuntu || "$distro" == debian || "$distro_like" == *debian* ]]; then
    update_cmd=(apt-get update -q)
    install_cmd=(apt-get install -y -q)
    packages=("${debian_deps[@]}")
elif [[ "$distro" == fedora ]]; then
    install_cmd=(dnf install -v -y)
    packages=("${fedora_deps[@]}")
elif [[ "$distro" == arch || "$distro_like" == *arch* ]]; then
    update_cmd=(pacman -Sy --noconfirm)
    install_cmd=(pacman -S --noconfirm --needed)
    packages=("${arch_deps[@]}")
elif [[ "$distro" == alpine ]]; then
    update_cmd=(apk update)
    install_cmd=(apk add)
    packages=("${alpine_deps[@]}")
else
    echo "Unsupported distribution: ${distro:-unknown}" >&2
    echo "Install these Debian-compatible package names manually: ${debian_deps[*]}" >&2
    exit 1
fi

if [[ "$dry_run" == true ]]; then
    printf 'Detected %s. Packages: %s\n' "$distro" "${packages[*]}"
    exit 0
fi

sudo_cmd=()
if ((EUID != 0)); then
    command -v sudo >/dev/null 2>&1 || { echo "Root privileges or sudo are required." >&2; exit 1; }
    sudo_cmd=(sudo)
fi

if ((${#update_cmd[@]})); then
    "${sudo_cmd[@]}" "${update_cmd[@]}"
fi
"${sudo_cmd[@]}" "${install_cmd[@]}" "${packages[@]}"
