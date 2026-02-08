# Usage
Download pre-built binaries from releases or build from source (recommended) as explained below.

Run the [cage_xtmapper.sh](./cage_xtmapper.sh) script as the regular user:  

    cage_xtmapper.sh


# Features
### Change refresh rate or FPS of waydroid
https://xtr126.github.io/XtMapper-docs/waydroid/2-fps/
### Touchpad input
https://xtr126.github.io/XtMapper-docs/waydroid/3-touchpad/
### Customize window
https://xtr126.github.io/XtMapper-docs/waydroid/4-window-customization/
### How to fullscreen cage-xtmapper
https://xtr126.github.io/XtMapper-docs/waydroid/5-fullscreen/
### Disable colored logcat output in the terminal
https://xtr126.github.io/XtMapper-docs/waydroid/6-disable-logging/
### SteamOS session/ Bazzite steam gaming mode
In desktop mode, go to Start menu > System, then right click on Konsole/Terminal and add to steam. Now you can launch Terminal or Konsole in Steam and run cage_xtmapper.sh.
### Passthrough mouse input to waydroid instead of to XtMapper
Use F10 or any other key defined in  [togglekey.h](https://github.com/Xtr126/cage/blob/master/togglekey.h) to toggle between XtMapper or Waydroid handling mouse input.  
### Fix invisible cursor isssue
Enable cursor on subsurface if cursor is invisible:
  
    waydroid prop set persist.waydroid.cursor_on_subsurface true
Note: With cage v0.1.5 there is a two cursors on-screen issue.

# Download and install
To download and install from [pre-builts](https://github.com/Xtr126/cage-xtmapper/releases), paste the following into a terminal.

### Step 1
Download v0.2.0 - For modern distros with wlroots v0.18 or newer - Ubuntu 25.04 (plucky), Debian Sid, Arch, Fedora, Alpine

    curl -fOL --retry 3 --retry-delay 3  "https://github.com/Xtr126/cage-xtmapper/releases/latest/download/cage-xtmapper-v0.2.0.tar"

Download v0.1.5 - For slightly older distros with wlroots v0.17.x - Ubuntu 24.04 (noble), Debian 13 (Trixie)

    curl -fOL --retry 3 --retry-delay 3  "https://github.com/Xtr126/cage-xtmapper/releases/latest/download/cage-xtmapper-v0.1.5.tar"

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
Two branches are maintained.  
v0.2.0 - For modern distros with wlroots v0.18 or newer - Ubuntu 25.04 (plucky), Debian Sid, Arch, Fedora, Alpine   
v0.1.5 - For slightly older distros with wlroots v0.17.x - Ubuntu 24.04 (noble), Debian 13 (Trixie)

Replace `<branch>` below with either v0.2.0 or v0.1.5

    git clone https://github.com/Xtr126/cage-xtmapper -b <branch>
    cd cage-xtmapper
    ./build.sh
If build fails, check if upstream cage and wlroots source code can build normally on your system:  
Cage: https://github.com/cage-kiosk/cage  
wlroots: https://gitlab.freedesktop.org/wlroots

### Install the built binary and the script to /usr/local/bin.  
Run from within the cage-xtmapper directory after building:

    cd build/installed/usr/local/bin/
    sudo install -Dm755 ./cage_xtmapper /usr/local/bin/
    sudo install -Dm755 ./cage_xtmapper.sh /usr/local/bin/

