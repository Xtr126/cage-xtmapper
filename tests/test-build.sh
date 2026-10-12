#!/usr/bin/env bash
set -Eeuo pipefail

repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
tmp="$(mktemp -d)"
trap 'rm -rf -- "$tmp"' EXIT

make_fixture() {
    local root="$1"
    mkdir -p "$root"/{bin,wlroots_patches,meson_wrapfiles,wlroots_deps}
    cp "$repo/build.sh" "$root/"
    touch "$root/one.patch" "$root/wlroots_patches/one.patch"
    touch "$root/meson_wrapfiles/local.wrap" "$root/wlroots_deps/local.tar.xz"
    mkdir -p "$tmp/archive-cage/cage-1" "$tmp/archive-wlroots/wlroots-1"
    tar -czf "$root/cage-1.tar.gz" -C "$tmp/archive-cage" cage-1
    tar -czf "$root/wlroots-1.tar.gz" -C "$tmp/archive-wlroots" wlroots-1
    cat > "$root/bin/patch" <<'MOCK'
#!/usr/bin/env bash
echo "patch $*" >> "$MOCK_LOG"
MOCK
    cat > "$root/bin/meson" <<'MOCK'
#!/usr/bin/env bash
echo "meson $*" >> "$MOCK_LOG"
if [[ "${1-}" == compile && "${MESON_FAIL-}" == compile ]]; then exit 31; fi
if [[ "${1-}" == install ]]; then
    mkdir -p "$MOCK_ROOT/build/installed/usr/local/bin" "$MOCK_ROOT/build/installed/usr/local/lib"
fi
MOCK
    chmod +x "$root/bin/patch" "$root/bin/meson"
}

assert() {
    if ! "$@"; then
        echo "FAIL: $*" >&2
        exit 1
    fi
}

# Invalid and duplicate flags fail before creating build output.
root="$tmp/cli"
make_fixture "$root"
export MOCK_LOG="$tmp/log" MOCK_ROOT="$root"
: > "$MOCK_LOG"
if PATH="$root/bin:$PATH" "$root/build.sh" --unknown >"$tmp/out" 2>&1; then
    echo "unknown flag unexpectedly succeeded" >&2; exit 1
fi
[[ ! -e "$root/build" ]] || { echo "unknown flag changed build tree" >&2; exit 1; }
if PATH="$root/bin:$PATH" "$root/build.sh" --dry-run --dry-run >"$tmp/out" 2>&1; then
    echo "duplicate --dry-run unexpectedly succeeded" >&2; exit 1
fi
[[ ! -e "$root/build" ]] || { echo "duplicate flag changed build tree" >&2; exit 1; }

# Dry-run still prepares/configures, but does not compile or install, from any cwd.
: > "$MOCK_LOG"
(cd / && PATH="$root/bin:$PATH" "$root/build.sh" --dry-run >/dev/null)
grep -q '^meson setup ' "$MOCK_LOG"
! grep -q '^meson compile ' "$MOCK_LOG"
! grep -q '^meson install ' "$MOCK_LOG"
[[ -f "$root/build/cage-1/.cage-xtmapper-prepared" ]]

# A prepared tree is rejected if source inputs change after it was patched.
printf 'changed\n' > "$root/one.patch"
: > "$MOCK_LOG"
if PATH="$root/bin:$PATH" "$root/build.sh" --dry-run >"$tmp/out" 2>&1; then
    echo "stale prepared source unexpectedly succeeded" >&2; exit 1
fi
grep -q 'Build inputs changed' "$tmp/out"
[[ ! -s "$MOCK_LOG" ]] || { echo "build tools ran on stale source" >&2; exit 1; }

# A compile failure propagates and prevents installation.
root="$tmp/failure"
make_fixture "$root"
export MOCK_ROOT="$root"
: > "$MOCK_LOG"
if PATH="$root/bin:$PATH" MESON_FAIL=compile "$root/build.sh" >"$tmp/out" 2>&1; then
    echo "compile failure unexpectedly succeeded" >&2; exit 1
fi
grep -q '^meson compile ' "$MOCK_LOG"
! grep -q '^meson install ' "$MOCK_LOG"

# An interrupted preparation is detected before any build tool is called.
root="$tmp/partial"
make_fixture "$root"
mkdir -p "$root/build/cage-partial"
export MOCK_ROOT="$root"
: > "$MOCK_LOG"
if PATH="$root/bin:$PATH" "$root/build.sh" >"$tmp/out" 2>&1; then
    echo "partial preparation unexpectedly succeeded" >&2; exit 1
fi
grep -q 'incomplete source preparation' "$tmp/out"
[[ ! -s "$MOCK_LOG" ]] || { echo "tools ran against partial source" >&2; exit 1; }

echo "build.sh tests passed"
