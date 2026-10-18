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
To use Cage's DRM backend, start `cage_xtmapper.sh` from a TTY. The maintained Cage fork removes session-dependent seat setup; to change that behavior, edit `seat.c` in the Cage fork, commit it, update the submodule pin, and rebuild.

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
    
# Build from source

Three branches are maintained:

- `v0.3.0` builds Cage 0.3.0 with wlroots 0.20.2. Ubuntu 26.04 is the supported CI and release build baseline for this branch. Ubuntu 24.04 compatibility is not guaranteed; use the older branch appropriate for your distribution. It needs Wayland 1.24+, wayland-protocols 1.47+, libdrm 2.4.129+, libxkbcommon 1.8+, and Pixman 0.46+. Use it for distributions whose system packages meet these versions; the build also includes pinned fallback sources for these libraries.
- `v0.2.0` builds Cage 0.2.0 with wlroots 0.18.3 for distributions whose system libraries cannot support v0.3.0. See the [v0.2.0 compatibility and build instructions](https://github.com/Xtr126/cage-xtmapper/blob/v0.2.0/README.md).
- `v0.1.5` builds Cage 0.1.5 with wlroots 0.17.x.

Choose the branch that matches the distribution you need to support.

    git clone --recurse-submodules -b <branch> https://github.com/Xtr126/cage-xtmapper
    cd cage-xtmapper
    ./build.sh

See [BUILDING.md](BUILDING.md) for dependency setup, installation, debug builds, and details about the pinned source inputs. For contribution and backport guidance, see [CONTRIBUTING.md](CONTRIBUTING.md); contributor credits and provenance are listed in [CONTRIBUTORS.md](CONTRIBUTORS.md).
