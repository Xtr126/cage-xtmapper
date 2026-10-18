# Building Cage XtMapper

These instructions describe the `v0.3.0` branch, which builds Cage 0.3.0 with wlroots 0.20.2.

## Host dependencies

- [Arch](https://github.com/cage-kiosk/cage/blob/eaeab71ffa3ab5884df09c5664c00e368ca2585e/.github/workflows/main.yml#L32): `pacman -Syu xcb-util-wm seatd git clang meson libinput libdrm mesa libxkbcommon wayland wayland-protocols xorg-server-xwayland scdoc hwdata`
- [Alpine](https://github.com/cage-kiosk/cage/blob/eaeab71ffa3ab5884df09c5664c00e368ca2585e/.github/workflows/main.yml#L26): `apk add build-base xcb-util-wm-dev libseat-dev clang git eudev-dev mesa-dev libdrm-dev libinput-dev libxkbcommon-dev pixman-dev wayland-dev meson wayland-protocols xwayland-dev scdoc-doc hwdata`
- Fedora: `dnf install gcc gnupg2 meson libwayland-server libxkbcommon-devel libdisplay-info libliftoff hwdata lcms2 libdrm libinput libseat vulkan libwayland-client pixman-devel wayland-devel wayland-protocols-devel libdrm-devel libxcb-devel xcb-util-renderutil-devel seatd libseat-devel systemd-devel git mesa-libEGL-devel mesa-libgbm-devel mesa-libGLES-devel vulkan-loader-devel`
- Ubuntu/Debian: `sudo apt build-dep wlroots`

To install host packages on Debian or Ubuntu, Fedora, Arch, or Alpine, use the optional helper:

```sh
./install_deps.sh --dry-run
sudo ./install_deps.sh
```

Review the package list printed by `--dry-run` first. The installer is never run automatically by `build.sh`.

## Build and install

Clone the selected branch with its submodules, then build:

```sh
git clone --recurse-submodules -b <branch> https://github.com/Xtr126/cage-xtmapper
cd cage-xtmapper
./build.sh
```

If the repository is already cloned, initialize its submodules with:

```sh
git submodule update --init --recursive
```

After a successful build, install the binary and launcher from the repository root:

```sh
cd build/installed/usr/local/bin/
sudo install -Dm755 ./cage_xtmapper /usr/local/bin/
sudo install -Dm755 ./cage_xtmapper.sh /usr/local/bin/
```

## Debug builds

Use a debug build when investigating build or runtime errors:

```sh
./build.sh --debug
```

This compiles and installs Cage and its embedded wlroots in debug mode. Debug builds enable Cage's verbose logging by default. To configure the debug build without compiling or installing, run `./build.sh --debug --dry-run`. Running `./build.sh` without `--debug` switches the build back to release mode.

Release builds log errors by default. Cage's runtime `-D` flag also enables verbose logging when running a release build.

## Pinned source inputs

The build uses the pinned Cage and wlroots fork commits as submodules, plus wlroots dependency archives and Meson wrap files. Source builds need both submodule checkouts; the dependency archives remain included for offline dependency fallback.

Check the dependency archives from the repository root with:

```sh
sha256sum --check SHA256SUMS
```

`SHA256SUMS` records the SHA-256 digest for each retained dependency archive. When an archive is intentionally replaced, update its digest and review the corresponding version and source URL in the wrap files.

This branch pins Cage from [Xtr126/cage](https://github.com/Xtr126/cage), branch `codex/xtmapper-v0.3.0`, and wlroots from [Xtr126/wlroots-xtmapper](https://github.com/Xtr126/wlroots-xtmapper), branch `codex/xtmapper-v0.20.2`. The build assembles the pinned commits under ignored `build/source/` and keeps Meson state separately under `build/meson/`. For fork changes and CI checks, see [CONTRIBUTING.md](CONTRIBUTING.md).

Pull requests run on Ubuntu 26.04, verify archive checksums, run ShellCheck and shell syntax checks, exercise the mocked installer/build/launcher checks, and compile Cage and wlroots. Release packaging uses the same Ubuntu 26.04 baseline and attaches `cage-xtmapper-<tag>.tar` to a draft release for that tag.
