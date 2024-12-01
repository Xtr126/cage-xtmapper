exit_error() {
    echo -e "$1"
    exit 1
}

extract_tarball() {
    local tarball="$1"
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
    for patch in "$parent_dir"/wlroots/*.patch; do        
        patch -d subprojects/wlroots/ -p1 -i "$patch"
    done
}
apply_wlroots_patches

meson setup build --buildtype=release -Ddefault_library=static
meson compile -C build



