#!/usr/bin/env bash
set -Eeuo pipefail

repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT
mkdir -p "$tmp/bin"
export MOCK_LOG="$tmp/log"

fail() { echo "FAIL: $*" >&2; exit 1; }
write_os() { printf 'ID=%s\nID_LIKE=%s\n' "$1" "${2-}" > "$tmp/os-release"; }

cat > "$tmp/bin/apt-get" <<'MOCK'
#!/usr/bin/env bash
printf 'apt-get %s\n' "$*" >> "$MOCK_LOG"
[[ "${MOCK_FAIL-}" != apt-get ]]
MOCK
cat > "$tmp/bin/dnf" <<'MOCK'
#!/usr/bin/env bash
printf 'dnf %s\n' "$*" >> "$MOCK_LOG"
[[ "${MOCK_FAIL-}" != dnf ]]
MOCK
cat > "$tmp/bin/pacman" <<'MOCK'
#!/usr/bin/env bash
printf 'pacman %s\n' "$*" >> "$MOCK_LOG"
[[ "${MOCK_FAIL-}" != pacman ]]
MOCK
cat > "$tmp/bin/apk" <<'MOCK'
#!/usr/bin/env bash
printf 'apk %s\n' "$*" >> "$MOCK_LOG"
[[ "${MOCK_FAIL-}" != apk ]]
MOCK
cat > "$tmp/bin/sudo" <<'MOCK'
#!/usr/bin/env bash
printf 'sudo %s\n' "$*" >> "$MOCK_LOG"
exec "$@"
MOCK
chmod +x "$tmp/bin/"*
export PATH="$tmp/bin:$PATH"

# Dry-run selects package families without invoking a package manager.
write_os ubuntu
: > "$MOCK_LOG"
OS_RELEASE_FILE="$tmp/os-release" "$repo/install_deps.sh" --dry-run > "$tmp/out"
grep -q 'Detected ubuntu. Packages:.*build-essential' "$tmp/out" || fail 'Ubuntu packages were not selected'
[[ ! -s "$MOCK_LOG" ]] || fail 'dry-run invoked commands'
write_os fedora
OS_RELEASE_FILE="$tmp/os-release" "$repo/install_deps.sh" --dry-run > "$tmp/out"
grep -q 'Packages:.*wayland-devel' "$tmp/out" || fail 'Fedora packages were not selected'
write_os arch
OS_RELEASE_FILE="$tmp/os-release" "$repo/install_deps.sh" --dry-run > "$tmp/out"
grep -q 'Packages:.*base-devel' "$tmp/out" || fail 'Arch packages were not selected'
write_os alpine
OS_RELEASE_FILE="$tmp/os-release" "$repo/install_deps.sh" --dry-run > "$tmp/out"
grep -q 'Packages:.*build-base' "$tmp/out" || fail 'Alpine packages were not selected'
write_os linux 'debian ubuntu'
OS_RELEASE_FILE="$tmp/os-release" "$repo/install_deps.sh" --dry-run > "$tmp/out"
grep -q 'Detected linux.*build-essential' "$tmp/out" || fail 'ID_LIKE Debian family was not recognized'

# Unsupported distributions fail before any package manager call.
write_os gentoo
: > "$MOCK_LOG"
if OS_RELEASE_FILE="$tmp/os-release" "$repo/install_deps.sh" --dry-run > "$tmp/out" 2>&1; then fail 'unsupported distribution succeeded'; fi
grep -q 'Unsupported distribution: gentoo' "$tmp/out" || fail 'unsupported distribution was not explained'
[[ ! -s "$MOCK_LOG" ]] || fail 'unsupported distribution ran a package manager'

# A normal install uses privilege escalation for non-root callers.
if command -v runuser >/dev/null 2>&1 && [[ $(id -u) == 0 ]]; then
    chmod 755 "$tmp" "$tmp/bin"
    chmod 644 "$tmp/os-release"
    write_os ubuntu
    chmod 644 "$tmp/os-release"
    : > "$MOCK_LOG"
    chown "$(id -u nobody):$(id -g nobody)" "$MOCK_LOG"
    runuser -u nobody -- env PATH="$tmp/bin:/usr/bin:/bin" MOCK_LOG="$MOCK_LOG" OS_RELEASE_FILE="$tmp/os-release" "$repo/install_deps.sh" > "$tmp/out"
    grep -q '^sudo apt-get update' "$MOCK_LOG" || fail 'non-root caller did not use sudo for update'
    grep -q '^sudo apt-get install' "$MOCK_LOG" || fail 'non-root caller did not use sudo for install'
    : > "$MOCK_LOG"
    mkdir -p "$tmp/no-sudo"
    ln -sf /usr/bin/bash "$tmp/no-sudo/bash"
    ln -sf /usr/bin/awk "$tmp/no-sudo/awk"
    if runuser -u nobody -- env PATH="$tmp/no-sudo" MOCK_LOG="$MOCK_LOG" OS_RELEASE_FILE="$tmp/os-release" "$repo/install_deps.sh" > "$tmp/out" 2>&1; then fail 'non-root install without sudo succeeded'; fi
    grep -q 'Root privileges or sudo are required' "$tmp/out" || fail 'missing sudo error was not explained'
fi

# Package manager failures propagate and stop subsequent work.
write_os fedora
: > "$MOCK_LOG"
if MOCK_FAIL=dnf OS_RELEASE_FILE="$tmp/os-release" "$repo/install_deps.sh" > "$tmp/out" 2>&1; then fail 'package failure was hidden'; fi
grep -q '^dnf install' "$MOCK_LOG" || fail 'Fedora installer was not invoked'

echo 'install_deps.sh tests passed'
