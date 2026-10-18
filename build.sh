#!/usr/bin/env bash
set -Eeuo pipefail

usage() {
    cat <<'USAGE'
Usage: build.sh [--dry-run]

  --dry-run  Prepare sources and configure Meson, but skip compile and install.
USAGE
}

dry_run=false
while (($#)); do
    case "$1" in
        --dry-run)
            if [[ "$dry_run" == true ]]; then
                echo "--dry-run may only be specified once" >&2
                usage >&2
                exit 2
            fi
            dry_run=true
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown argument: $1" >&2
            usage >&2
            exit 2
            ;;
    esac
    shift
done

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
build_root="$script_dir/build"
source_root="$build_root/source"
source_dir="$source_root/cage-0.3.0"
meson_build_dir="$build_root/meson"
prepared_marker='.cage-xtmapper-prepared'
cage_checkout="$script_dir/forks/cage"
wlroots_checkout="$script_dir/forks/wlroots-xtmapper"

fail() {
    echo "build.sh: $*" >&2
    exit 1
}

require_checkout() {
    local name="$1" path="$2" checkout_root expected_root
    [[ -d "$path" ]] || fail "$name submodule is missing at $path. Clone with --recurse-submodules or run 'git submodule update --init --recursive'."
    git -C "$path" rev-parse --is-inside-work-tree >/dev/null 2>&1 || fail "$name submodule is not initialized at $path. Run 'git submodule update --init --recursive'."
    checkout_root="$(git -C "$path" rev-parse --show-toplevel)"
    expected_root="$(cd -- "$path" && pwd -P)"
    [[ "$checkout_root" == "$expected_root" ]] || fail "$name submodule is not initialized at $path. Run 'git submodule update --init --recursive'."
}

require_checkout Cage "$cage_checkout"
require_checkout wlroots "$wlroots_checkout"

require_pinned_commit() {
    local name="$1" relative_path="$2" checkout="$3" entry mode pinned_commit stage current_commit
    entry="$(git -C "$script_dir" ls-files --stage -- "$relative_path")"
    [[ -n "$entry" ]] || fail "$name submodule is not recorded in the parent index at $relative_path"
    read -r mode pinned_commit stage _ <<<"$entry"
    [[ "$mode" == 160000 && "$stage" == 0 ]] || fail "$name path $relative_path is not a resolved submodule gitlink"
    current_commit="$(git -C "$checkout" rev-parse HEAD)"
    [[ "$current_commit" == "$pinned_commit" ]] || fail "$name checkout is at $current_commit but the parent pins $pinned_commit; update the parent gitlink before building"
    [[ -z "$(git -C "$checkout" status --porcelain)" ]] || fail "$name checkout has uncommitted changes; commit them before building the pinned source"
}

require_pinned_commit Cage forks/cage "$cage_checkout"
require_pinned_commit wlroots forks/wlroots-xtmapper "$wlroots_checkout"

shopt -s nullglob
wrapfiles=("$script_dir"/meson_wrapfiles/*)
dependencies=("$script_dir"/wlroots_deps/*)
((${#wrapfiles[@]} > 0)) || fail "No Meson wrap files found"
((${#dependencies[@]} > 0)) || fail "No wlroots dependency archives found"

input_fingerprint() {
    {
        git -C "$cage_checkout" rev-parse HEAD
        git -C "$wlroots_checkout" rev-parse HEAD
        sha256sum -- "${wrapfiles[@]}" "${dependencies[@]}"
    } | sha256sum | cut -d ' ' -f 1
}

extract_git_tree() {
    local checkout="$1" destination="$2" description="$3"
    echo "Assembling $description from $(git -C "$checkout" rev-parse --short HEAD)"
    mkdir -p -- "$destination"
    git -C "$checkout" archive --format=tar HEAD | tar -xf - -C "$destination" || fail "Failed to assemble $description from $checkout"
}

mkdir -p -- "$build_root"
current_fingerprint="$(input_fingerprint)"
if [[ -d "$source_dir" && -f "$source_dir/$prepared_marker" ]]; then
    prepared_fingerprint="$(<"$source_dir/$prepared_marker")"
else
    prepared_fingerprint=''
fi

if [[ "$prepared_fingerprint" != "$current_fingerprint" ]]; then
    rm -rf -- "$source_dir"
    rm -rf -- "$meson_build_dir"
    mkdir -p -- "$source_dir/subprojects/wlroots/subprojects/packagefiles"
    extract_git_tree "$cage_checkout" "$source_dir" Cage
    extract_git_tree "$wlroots_checkout" "$source_dir/subprojects/wlroots" wlroots
    cp -- "${wrapfiles[@]}" "$source_dir/subprojects/wlroots/subprojects/"
    ln -sf -- "${dependencies[@]}" "$source_dir/subprojects/wlroots/subprojects/packagefiles/"
    printf '%s\n' "$current_fingerprint" > "$source_dir/$prepared_marker"
elif [[ ! -d "$source_dir/subprojects/wlroots/subprojects/packagefiles" ]]; then
    fail "Prepared source tree is incomplete at $source_dir; remove it and rerun build.sh."
fi

# Meson subproject core options can persist independently of the root build.
# Set every wlroots project and available fallback explicitly so fresh setup
# and reconfigure both build all embedded sources as release code.
meson_setup_args=(
    --buildtype=release
    -Ddefault_library=static
    -Dprefix=/usr/local
    -Dwlroots:buildtype=release
    -Dwayland:buildtype=release
    -Dlibdrm:buildtype=release
    -Dlibxkbcommon:buildtype=release
    -Dpixman:buildtype=release
    -Dwayland-protocols:buildtype=release
    -Dlibdisplay-info:buildtype=release
    -Dedid-decode:buildtype=release
    -Dlibliftoff:buildtype=release
    -Dseatd:buildtype=release
)
if [[ -f "$meson_build_dir/meson-private/coredata.dat" ]]; then
    meson setup --reconfigure "$meson_build_dir" "$source_dir" "${meson_setup_args[@]}"
else
    meson setup "$meson_build_dir" "$source_dir" "${meson_setup_args[@]}"
fi

if [[ "$dry_run" == true ]]; then
    echo "Dry run: skipped compile and install"
    exit 0
fi

meson compile -C "$meson_build_dir"
meson install -C "$meson_build_dir" --destdir "$build_root/installed"
installed_bin="$build_root/installed/usr/local/bin"
[[ -d "$installed_bin" ]] || fail "Meson install did not create $installed_bin"
cp -- "$script_dir/cage_xtmapper.sh" "$installed_bin/"
chmod a+x "$installed_bin/cage_xtmapper.sh"
for path in "$build_root/installed"/usr/local/lib* "$build_root/installed/usr/local/include"; do
    if [[ -e "$path" || -L "$path" ]]; then
        rm -rf -- "$path"
    fi
done
