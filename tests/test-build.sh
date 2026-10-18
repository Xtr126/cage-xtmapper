#!/usr/bin/env bash
set -Eeuo pipefail

repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
tmp="$(mktemp -d)"
trap 'rm -rf -- "$tmp"' EXIT

make_source_repo() {
    local path="$1" file="$2"
    mkdir -p -- "$path"
    git -C "$path" init -q
    git -C "$path" config user.name 'Build test'
    git -C "$path" config user.email 'build-test@example.invalid'
    printf 'fixture source\n' > "$path/$file"
    git -C "$path" add -- "$file"
    git -C "$path" commit -q -m 'fixture source'
}

make_fixture() {
    local root="$1"
    mkdir -p "$root"/{bin,meson_wrapfiles,wlroots_deps}
    cp "$repo/build.sh" "$root/"
    cp "$repo/cage_xtmapper.sh" "$root/"
    touch "$root/meson_wrapfiles/local.wrap" "$root/wlroots_deps/local.tar.xz"
    make_source_repo "$root/forks/cage" cage.c
    make_source_repo "$root/forks/wlroots-xtmapper" wlroots.c
    git -C "$root" init -q
    git -C "$root" config user.name 'Build test'
    git -C "$root" config user.email 'build-test@example.invalid'
    git -C "$root" update-index --add --cacheinfo "160000,$(git -C "$root/forks/cage" rev-parse HEAD),forks/cage"
    git -C "$root" update-index --add --cacheinfo "160000,$(git -C "$root/forks/wlroots-xtmapper" rev-parse HEAD),forks/wlroots-xtmapper"
    cat > "$root/bin/meson" <<'MOCK'
#!/usr/bin/env bash
echo "meson $*" >> "$MOCK_LOG"
if [[ "${1-}" == compile && "${MESON_FAIL-}" == compile ]]; then exit 31; fi
if [[ "${1-}" == install ]]; then
    mkdir -p "$MOCK_ROOT/build/installed/usr/local/bin" "$MOCK_ROOT/build/installed/usr/local/lib"
fi
MOCK
    chmod +x "$root/bin/meson"
}

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

# Invalid and duplicate flags fail before creating build output.
root="$tmp/cli"
make_fixture "$root"
export MOCK_LOG="$tmp/log" MOCK_ROOT="$root"
: > "$MOCK_LOG"
if PATH="$root/bin:$PATH" "$root/build.sh" --unknown >"$tmp/out" 2>&1; then
    fail 'unknown flag unexpectedly succeeded'
fi
[[ ! -e "$root/build" ]] || fail 'unknown flag changed build tree'
if PATH="$root/bin:$PATH" "$root/build.sh" --dry-run --dry-run >"$tmp/out" 2>&1; then
    fail 'duplicate --dry-run unexpectedly succeeded'
fi
[[ ! -e "$root/build" ]] || fail 'duplicate flag changed build tree'

# Dry-run assembles committed fork sources and configures Meson out of tree, from any cwd.
: > "$MOCK_LOG"
(cd / && PATH="$root/bin:$PATH" "$root/build.sh" --dry-run >/dev/null)
grep -q '^meson setup ' "$MOCK_LOG"
grep -q '^meson setup .* --buildtype=release ' "$MOCK_LOG" || fail 'fresh Meson setup did not request release buildtype'
grep -q -- '-Dwlroots:buildtype=release' "$MOCK_LOG" || fail 'wlroots did not receive release buildtype'
if grep -q '^meson compile ' "$MOCK_LOG"; then fail 'dry-run invoked compile'; fi
if grep -q '^meson install ' "$MOCK_LOG"; then fail 'dry-run invoked install'; fi
[[ -f "$root/build/source/cage-0.3.0/cage.c" ]] || fail 'Cage source was not assembled'
[[ -f "$root/build/source/cage-0.3.0/subprojects/wlroots/wlroots.c" ]] || fail 'wlroots source was not placed under Cage subprojects'
[[ -d "$root/build/source/cage-0.3.0/subprojects/wlroots/subprojects/packagefiles" ]] || fail 'dependency archive location is missing'
[[ ! -e "$root/build/source/cage-0.3.0/.git" ]] || fail 'staged source unexpectedly contains Git metadata'
grep -q "setup $root/build/meson $root/build/source/cage-0.3.0" "$MOCK_LOG" || fail 'Meson build directory is not outside the staged source tree'

# Reconfiguration must reset an existing debug build to release too.
mkdir -p "$root/build/meson/meson-private"
touch "$root/build/meson/meson-private/coredata.dat"
: > "$MOCK_LOG"
PATH="$root/bin:$PATH" "$root/build.sh" --dry-run >/dev/null
grep -q '^meson setup --reconfigure .* --buildtype=release ' "$MOCK_LOG" || fail 'Meson reconfigure did not request release buildtype'
grep -q -- '-Dwlroots:buildtype=release' "$MOCK_LOG" || fail 'wlroots did not receive release buildtype'

# Debug is opt-in and may be combined with dry-run in either order.
for flags in '--debug --dry-run' '--dry-run --debug'; do
    : > "$MOCK_LOG"
    read -r -a debug_args <<< "$flags"
    PATH="$root/bin:$PATH" "$root/build.sh" "${debug_args[@]}" >/dev/null
    grep -q -- '--buildtype=debug' "$MOCK_LOG" || fail 'debug mode was not requested'
    grep -q -- '-Dwlroots:buildtype=debug' "$MOCK_LOG" || fail 'wlroots debug mode was not requested'
done
: > "$MOCK_LOG"
PATH="$root/bin:$PATH" "$root/build.sh" --dry-run >/dev/null
grep -q -- '-Dwlroots:buildtype=release' "$MOCK_LOG" || fail 'default did not restore wlroots release mode'
if PATH="$root/bin:$PATH" "$root/build.sh" --debug --debug >/dev/null 2>&1; then
    fail 'duplicate --debug unexpectedly succeeded'
fi

# A changed fork commit must first be recorded by the parent gitlink.
printf 'updated fixture source\n' > "$root/forks/cage/cage.c"
git -C "$root/forks/cage" add cage.c
git -C "$root/forks/cage" commit -q -m 'updated fixture source'
: > "$MOCK_LOG"
if PATH="$root/bin:$PATH" "$root/build.sh" --dry-run >"$tmp/out" 2>&1; then
    fail 'build unexpectedly accepted a commit different from the parent gitlink'
fi
grep -q 'update the parent gitlink before building' "$tmp/out"
[[ ! -s "$MOCK_LOG" ]] || fail 'Meson ran before the parent gitlink was updated'
git -C "$root" update-index --cacheinfo "160000,$(git -C "$root/forks/cage" rev-parse HEAD),forks/cage"
: > "$MOCK_LOG"
PATH="$root/bin:$PATH" "$root/build.sh" --dry-run >/dev/null
grep -q '^meson setup ' "$MOCK_LOG"
grep -q 'updated fixture source' "$root/build/source/cage-0.3.0/cage.c" || fail 'changed commit was not staged'

# A compile failure propagates and prevents installation.
root="$tmp/failure"
make_fixture "$root"
export MOCK_ROOT="$root"
: > "$MOCK_LOG"
if PATH="$root/bin:$PATH" MESON_FAIL=compile "$root/build.sh" >"$tmp/out" 2>&1; then
    fail 'compile failure unexpectedly succeeded'
fi
grep -q '^meson compile ' "$MOCK_LOG"
if grep -q '^meson install ' "$MOCK_LOG"; then fail 'compile failure did not stop installation'; fi

# A successful build installs the launcher script alongside the Meson binary.
root="$tmp/success"
make_fixture "$root"
export MOCK_ROOT="$root"
: > "$MOCK_LOG"
PATH="$root/bin:$PATH" "$root/build.sh" >/dev/null
grep -q '^meson compile ' "$MOCK_LOG"
grep -q '^meson install ' "$MOCK_LOG"
[[ -x "$root/build/installed/usr/local/bin/cage_xtmapper.sh" ]] || fail 'launcher was not copied into the install tree'

# An uninitialized submodule checkout is reported before invoking Meson.
root="$tmp/uninitialized"
make_fixture "$root"
rm -rf -- "$root/forks/wlroots-xtmapper/.git"
export MOCK_ROOT="$root"
: > "$MOCK_LOG"
if PATH="$root/bin:$PATH" "$root/build.sh" --dry-run >"$tmp/out" 2>&1; then
    fail 'uninitialized wlroots checkout unexpectedly succeeded'
fi
grep -q 'submodule is not initialized' "$tmp/out"
[[ ! -s "$MOCK_LOG" ]] || fail 'Meson ran with an uninitialized submodule'

echo 'build.sh tests passed'
