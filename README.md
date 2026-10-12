# Usage
Download pre-built binaries from releases or build from source (recommended) as explained below.

Run the [cage_xtmapper.sh](./cage_xtmapper.sh) script as the regular user:  

    cage_xtmapper.sh


# Features
- Change refresh rate or FPS of waydroid
https://xtr126.github.io/XtMapper-docs/waydroid/2-fps/
- Touchpad input
https://xtr126.github.io/XtMapper-docs/waydroid/3-touchpad/
- Customize window
https://xtr126.github.io/XtMapper-docs/waydroid/4-window-customization/
- How to fullscreen cage-xtmapper
https://xtr126.github.io/XtMapper-docs/waydroid/5-fullscreen/
- Disable colored logcat output in the terminal
https://xtr126.github.io/XtMapper-docs/waydroid/6-disable-logging/
- Passthrough mouse input to waydroid instead of to XtMapper  
Use F10 or any other key defined in  [togglekey.h](https://github.com/Xtr126/cage/blob/master/togglekey.h) to toggle between XtMapper or Waydroid handling mouse input.  

# Some tips
### SteamOS session/ Bazzite steam gaming mode
In desktop mode, go to Start menu > System, then right click on Konsole/Terminal and add to steam. Now you can launch Terminal or Konsole in Steam and run cage_xtmapper.sh.

### Using cage's DRM backend
Remove 0007-fix-build-Remove-all-session-dependent-code.patch and build. Then start cage_xtmapper.sh from a TTY.

### Fix invisible cursor issue
Enable cursor on subsurface if cursor is invisible:
  
    waydroid prop set persist.waydroid.cursor_on_subsurface true

> [!NOTE]
cage v0.1.5 has a two cursors on-screen issue.

### Disable fake touch (persist.waydroid.fake_touch)
If you have enabled fake touch it might [interfere with mouse movement](https://github.com/Xtr126/XtMapper/discussions/184). Clear it by running:
    
    waydroid prop set persist.waydroid.fake_touch ""




# Download and install
To download and install from [pre-builts](https://github.com/Xtr126/cage-xtmapper/releases), paste the following into a terminal.

### Step 1
Download v0.3.0 - Cage 0.3.0 with wlroots 0.20.2 for newer distributions: Arch, Fedora 44+

    curl -fOL --retry 3 --retry-delay 3  "https://github.com/Xtr126/cage-xtmapper/releases/latest/download/cage-xtmapper-v0.3.0.tar"

Download v0.2.0 - Cage 0.2.0 with wlroots 0.18.3: Debian 13, Ubuntu 25/26

    curl -fOL --retry 3 --retry-delay 3  "https://github.com/Xtr126/cage-xtmapper/releases/latest/download/cage-xtmapper-v0.2.0.tar"

Download v0.1.5 - Cage 0.1.5 with wlroots 0.17.x for older distributions: Ubuntu 24.04 (noble), Debian 13 (Trixie)

    curl -fOL --retry 3 --retry-delay 3  "https://github.com/Xtr126/cage-xtmapper/releases/latest/download/cage-xtmapper-v0.1.5.tar"

You will encounter compile-time errors by picking the wrong version.
### Step 2
To install from the downloaded tarball:

    tar xvf cage-xtmapper*.tar
    cd usr/local/bin
    sudo install -Dm755 ./cage_xtmapper /usr/local/bin/
    sudo install -Dm755 ./cage_xtmapper.sh /usr/local/bin/
    
# Build 
**Cage dependencies**  
- [Arch](https://github.com/cage-kiosk/cage/blob/eaeab71ffa3ab5884df09c5664c00e368ca2585e/.github/workflows/main.yml#L32) `pacman -Syu xcb-util-wm seatd git clang meson libinput libdrm mesa libxkbcommon wayland wayland-protocols xorg-server-xwayland scdoc hwdata`  
- [Alpine](https://github.com/cage-kiosk/cage/blob/eaeab71ffa3ab5884df09c5664c00e368ca2585e/.github/workflows/main.yml#L26) `apk add build-base xcb-util-wm-dev libseat-dev clang git eudev-dev mesa-dev libdrm-dev libinput-dev libxkbcommon-dev pixman-dev wayland-dev meson wayland-protocols xwayland-dev scdoc-doc hwdata`
- Fedora `dnf install gcc gnupg2 meson libwayland-server libxkbcommon-devel libdisplay-info libliftoff hwdata lcms2 libdrm libinput libseat vulkan libwayland-client pixman-devel wayland-devel wayland-protocols-devel libdrm-devel libxcb-devel xcb-util-renderutil-devel seatd libseat-devel systemd-devel git patch mesa-libEGL-devel mesa-libgbm-devel mesa-libGLES-devel vulkan-loader-devel`
- Ubuntu/Debian `sudo apt build-dep wlroots`

> [!IMPORTANT]
Three branches are maintained:

- `v0.3.0` builds Cage 0.3.0 with wlroots 0.20.2. It needs Wayland 1.24+, wayland-protocols 1.47+, libdrm 2.4.129+, libxkbcommon 1.8+, and Pixman 0.46+. Use it for distributions whose system packages meet these versions; the build also includes pinned fallback sources for these libraries.
- `v0.2.0` builds Cage 0.2.0 with wlroots 0.18.3.
- `v0.1.5` builds Cage 0.1.5 with wlroots 0.17.x.

Choose the branch that matches the distribution you need to support.

    git clone https://github.com/Xtr126/cage-xtmapper -b <branch>
    cd cage-xtmapper
    ./build.sh

## Reproducible inputs and patch maintenance

The build uses the checked-in Cage and wlroots source archives, wlroots dependency archives, Meson wrap files, and patch series. Verify the vendored archives from the repository root with:

    sha256sum --check SHA256SUMS

`SHA256SUMS` records the SHA-256 digest for each source and dependency archive. Update it whenever an archive is intentionally replaced, and review the corresponding version and source URL in the wrap files and this documentation.

The Cage patches in each maintained branch are exported from the corresponding development branch. Cage 0.3.0 development is maintained in [Xtr126/cage](https://github.com/Xtr126/cage), branch `codex/xtmapper-v0.3.0`, based on upstream Cage 0.3.0. The older 0.2 line uses branch `rebased-v0.2.0`, on Cage 0.2.0. Regenerate the 0.3 series from the `Xtr126/cage` checkout with:

    cd /path/to/cage
    git format-patch --output-directory /tmp/cage-xtmapper-patches 3783af4..codex/xtmapper-v0.3.0

The root-level `000*.patch` files and `cage-0.3.0.tar.gz` belong to the 0.3 line. Keep the 0.2 patch series on its own branch.

The wlroots patches in this branch are maintained in [Xtr126/wlroots-xtmapper](https://github.com/Xtr126/wlroots-xtmapper), branch `codex/xtmapper-v0.20.2`. Regenerate them from the wlroots 0.20.2 tag:

    cd /path/to/wlroots-xtmapper
    git format-patch --output-directory /tmp/cage-xtmapper-wlroots-patches 0.20.2..codex/xtmapper-v0.20.2

The `Xtr126/wlroots-xtmapper` fork also carries the 0.18.3 line on branch `codex/xtmapper-v0.18.3`. Keep each patch series with its matching source archive and branch. After changing archives, patches, wraps, or dependency inputs, remove the prepared `build/cage-*` source directory before rebuilding so the new inputs are applied.

### Push the prepared branches to GitHub

The commits are ready locally. Set the GitHub repositories as `origin` in each checkout and push the version branches:

    cd /path/to/cage
    git remote add origin https://github.com/Xtr126/cage.git
    git push -u origin codex/xtmapper-v0.3.0

    cd /path/to/wlroots-xtmapper
    git remote add origin https://github.com/Xtr126/wlroots-xtmapper.git
    git push -u origin codex/xtmapper-v0.20.2
    git push -u origin codex/xtmapper-v0.18.3

If `origin` already exists, update its URL with `git remote set-url origin <URL>` instead of adding it. Push each branch only after checking out that branch if you want to verify or continue its changes locally.

Pull requests run archive checksum verification, ShellCheck, shell syntax checks, and mocked build and launcher checks. Release packaging runs separately for a version tag and attaches `cage-xtmapper-<tag>.tar` to a draft release for that tag. It does not replace an asset with the same name.

### Install the built binary and the script to /usr/local/bin.  
Run from within the cage-xtmapper directory after building:

    cd build/installed/usr/local/bin/
    sudo install -Dm755 ./cage_xtmapper /usr/local/bin/
    sudo install -Dm755 ./cage_xtmapper.sh /usr/local/bin/

