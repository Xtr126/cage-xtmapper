#!/bin/bash -v
exit_error() {
    echo -e "$1"
    exit 1
}

extract_tarball() {
    local tarball="$1"
    echo "Extracting $tarball"
    if ! tar xf "$tarball";  then
        bsdtar -xf "$tarball" || exit_error "Failed to extract tarball\nTried tar and bsdtar"
    fi
}

parent_dir="$(pwd)"

if ! [[ -d ./build ]]; then
    mkdir ./build
    cd ./build 
else
    exit_error "build directory exists"
fi

extract_tarball "$parent_dir"/cage-0.2.0.tar.gz

cd cage-0.2.0



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
    extract_tarball "$parent_dir"/wlroots-0.18.1.tar.gz
    rm -rf wlroots
    mv wlroots-0.18.1 wlroots
)

apply_wlroots_patches() {
    cd subprojects/wlroots/
    echo "Applying wlroots patches"
    for patch in "$parent_dir"/wlroots/*.patch; do        
        patch -p1 -i "$patch"
    done
    mkdir -p subprojects/packagefiles

    ln -s "$parent_dir"/wayland.wrap ./subprojects/    
    ln -s "$parent_dir"/wayland-1.23.1.tar.xz ./subprojects/packagefiles/  
}
( apply_wlroots_patches )

meson setup build \
    --buildtype=release \
    -Ddefault_library=static \
    -Dprefix=/installed 

meson compile -C build

meson install -C build --destdir "$parent_dir"/build



