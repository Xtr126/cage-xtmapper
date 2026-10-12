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
prepared_marker='.cage-xtmapper-prepared'

fail() {
    echo "build.sh: $*" >&2
    exit 1
}

single_match() {
    local description="$1"
    shift
    local matches=("$@")
    ((${#matches[@]} == 1)) || fail "Expected exactly one $description; found ${#matches[@]}"
    [[ -f "${matches[0]}" ]] || fail "Missing $description: ${matches[0]}"
    printf '%s\n' "${matches[0]}"
}

input_fingerprint() {
    local files=(
        "$script_dir"/cage-*.tar.gz
        "$script_dir"/wlroots-*.tar.gz
        "$script_dir"/*.patch
        "$script_dir"/wlroots_patches/*.patch
        "$script_dir"/meson_wrapfiles/*
        "$script_dir"/wlroots_deps/*
    )
    ((${#files[@]} > 0)) || fail "No build inputs found"
    sha256sum -- "${files[@]}" | sha256sum | cut -d ' ' -f 1
}

extract_archive() {
    local archive="$1"
    echo "Extracting $(basename -- "$archive")"
    tar -xf "$archive" -C "$2" || fail "Failed to extract $archive"
}

mkdir -p -- "$build_root"
shopt -s nullglob
cage_candidates=("$build_root"/cage-*)
cage_dirs=()
for path in "${cage_candidates[@]}"; do
    [[ -d "$path" ]] && cage_dirs+=("$path")
done
if ((${#cage_dirs[@]} > 1)); then
    fail "Found multiple extracted cage source directories under $build_root"
fi

if ((${#cage_dirs[@]} == 1)); then
    source_dir="${cage_dirs[0]}"
    [[ -f "$source_dir/$prepared_marker" ]] || fail "Found incomplete source preparation at $source_dir. Remove that directory and rerun build.sh."
    current_fingerprint=$(input_fingerprint)
    prepared_fingerprint=$(<"$source_dir/$prepared_marker")
    [[ "$prepared_fingerprint" == "$current_fingerprint" ]] || fail "Build inputs changed since source preparation at $source_dir. Remove that directory and rerun build.sh."
    [[ -d "$source_dir/subprojects/wlroots/subprojects/packagefiles" ]] || fail "Prepared source tree is incomplete at $source_dir; remove it and rerun build.sh."
else
    cage_archive="$(single_match 'cage source archive' "$script_dir"/cage-*.tar.gz)"
    wlroots_archive="$(single_match 'wlroots source archive' "$script_dir"/wlroots-*.tar.gz)"
    mkdir -p -- "$build_root/.prepare"
    prepare_dir="$build_root/.prepare"
    extract_archive "$cage_archive" "$prepare_dir"
    extracted_cage=("$prepare_dir"/cage-*)
    ((${#extracted_cage[@]} == 1)) && [[ -d "${extracted_cage[0]}" ]] || fail "Cage archive must contain exactly one cage-* directory"
    source_dir="$build_root/${extracted_cage[0]##*/}"
    mv -- "${extracted_cage[0]}" "$source_dir"
    rmdir -- "$prepare_dir"

    mkdir -p -- "$source_dir/subprojects"
    cage_patches=("$script_dir"/*.patch)
    ((${#cage_patches[@]} > 0)) || fail "No cage patches found in $script_dir"
    echo "Applying cage patches"
    for patch_file in "${cage_patches[@]}"; do
        patch -p1 -i "$patch_file" -d "$source_dir"
    done

    wlroots_parent="$source_dir/subprojects"
    extract_archive "$wlroots_archive" "$wlroots_parent"
    wlroots_dirs=("$wlroots_parent"/wlroots-*)
    ((${#wlroots_dirs[@]} == 1)) && [[ -d "${wlroots_dirs[0]}" ]] || fail "wlroots archive must contain exactly one wlroots-* directory"
    mv -- "${wlroots_dirs[0]}" "$wlroots_parent/wlroots"

    mkdir -p -- "$wlroots_parent/wlroots/subprojects/packagefiles"
    wlroots_patches=("$script_dir"/wlroots_patches/*.patch)
    wrapfiles=("$script_dir"/meson_wrapfiles/*)
    dependencies=("$script_dir"/wlroots_deps/*)
    ((${#wlroots_patches[@]} > 0)) || fail "No wlroots patches found"
    ((${#wrapfiles[@]} > 0)) || fail "No Meson wrap files found"
    ((${#dependencies[@]} > 0)) || fail "No wlroots dependency archives found"
    echo "Applying wlroots patches"
    for patch_file in "${wlroots_patches[@]}"; do
        patch -p1 -i "$patch_file" -d "$wlroots_parent/wlroots"
    done
    cp -- "${wrapfiles[@]}" "$wlroots_parent/wlroots/subprojects/"
    ln -sf "${dependencies[@]}" "$wlroots_parent/wlroots/subprojects/packagefiles/"
    input_fingerprint > "$source_dir/$prepared_marker"
fi

cd -- "$source_dir"
meson_setup_args=(--buildtype=release -Ddefault_library=static -Dprefix=/usr/local)
if [[ -f build/meson-private/coredata.dat ]]; then
    meson setup --reconfigure build "${meson_setup_args[@]}"
else
    meson setup build "${meson_setup_args[@]}"
fi

if [[ "$dry_run" == true ]]; then
    echo "Dry run: skipped compile and install"
    exit 0
fi

meson compile -C build
meson install -C build --destdir "$build_root/installed"
installed_bin="$build_root/installed/usr/local/bin"
[[ -d "$installed_bin" ]] || fail "Meson install did not create $installed_bin"
cp -- "$script_dir/cage_xtmapper.sh" "$installed_bin/"
chmod a+x "$installed_bin/cage_xtmapper.sh"
for path in "$build_root/installed"/usr/local/lib* "$build_root/installed/usr/local/include"; do
    if [[ -e "$path" || -L "$path" ]]; then
        rm -rf -- "$path"
    fi
done
