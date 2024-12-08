#!/bin/bash -v

while [ $# -gt 0 ]; do
    case "$1" in
    --c11-patch)
        shift
        c11_patch=true
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

extract_source_archive "$parent_dir"/cage-*

cd cage-*

mkdir -p subprojects/

apply_cage_patches() {
    echo "Applying cage patches"
    for patch in "$parent_dir"/*.patch; do        
        patch -p1 -i "$patch"
    done
}
apply_cage_patches 

(   
    cd subprojects; 
    extract_source_archive "$parent_dir"/wlroots-*.tar.gz
    rm -rf wlroots
    mv wlroots-* wlroots
)

apply_wlroots_patches() {
    cd subprojects/wlroots/
    echo "Applying wlroots patches"
    for patch in "$parent_dir"/wlroots_patches/*.patch; do        
        patch -p1 -i "$patch"
    done
    mkdir -p subprojects/packagefiles

    ln -s "$parent_dir"/meson_wrapfiles/* ./subprojects/    
    ln -s "$parent_dir"/wlroots_deps/* ./subprojects/packagefiles/  
}
( apply_wlroots_patches )

meson setup build \
    --buildtype=release \
    -Ddefault_library=static \
    -Dprefix=/usr/local 

meson compile -C build

meson install -C build --destdir "$parent_dir"/build/installed



