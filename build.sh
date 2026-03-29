#!/bin/bash

while [ $# -gt 0 ]; do
    case "$1" in
    --dry-run)
        shift
        dry_run=true
        ;;
    --install-deps)
        shift
        install_deps=true
        ;;
    *)
	echo "Invalid argument"
        exit 1
	;;
    esac
    shift
done


exit_error() {
    echo -e "$1"
    exit 1
}

if [[ "$install_deps" == true ]]; then
    ./install_deps.sh
fi

# Detect if dependencies are missing (at least basic ones)
if ! command -v meson >/dev/null 2>&1 || ! command -v git >/dev/null 2>&1; then
    echo "Required build tools (meson, git) not found. Installing dependencies..."
    ./install_deps.sh
fi

extract_source_archive() {
    local file="$1"
    echo "Extracting $file"
    tar xf "$file" || \
    bsdtar -xf "$file" || \
    unzip "$file" || \
    exit_error "Failed to extract file\nTried tar,bsdtar and unzip"
}

parent_dir="$(pwd)"

if ! [[ -d ./build ]]; then
    mkdir ./build
    cd ./build 
else
    exit_error "build directory exists"
fi

extract_source_archive "$parent_dir"/deps/archives/cage-*

cd cage-*

mkdir -p subprojects/

apply_cage_patches() {
    echo "Applying cage patches"
    for patch in "$parent_dir"/patches/cage/*.patch; do        
        patch -p1 -i "$patch"
    done
}
apply_cage_patches 

(   
    cd subprojects; 
    extract_source_archive "$parent_dir"/deps/archives/wlroots-*.tar.gz
    rm -rf wlroots
    mv wlroots-* wlroots
)

apply_wlroots_patches() {
    cd subprojects/wlroots/
    echo "Applying wlroots patches"
    for patch in "$parent_dir"/patches/wlroots/*.patch; do        
        patch -p1 -i "$patch"
    done
    mkdir -p subprojects/packagefiles

    ln -s "$parent_dir"/deps/meson/* ./subprojects/    
    ln -s "$parent_dir"/deps/wlroots_deps/* ./subprojects/packagefiles/  
}
( apply_wlroots_patches )

meson setup build \
    --buildtype=release \
    -Ddefault_library=static \
    -Dprefix=/usr/local 

if [[ -z $dry_run ]]; then 
    meson compile -C build
    meson install -C build --destdir "$parent_dir"/build/installed
    cd "$parent_dir"/build/installed
    cp "$parent_dir"/cage_xtmapper.sh usr/local/bin
    chmod a+x usr/local/bin/cage_xtmapper.sh
    rm -r usr/local/{lib*,include}  
fi


