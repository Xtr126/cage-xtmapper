
## Build 
**Cage dependencies**  
- [Arch](https://github.com/cage-kiosk/cage/blob/eaeab71ffa3ab5884df09c5664c00e368ca2585e/.github/workflows/main.yml#L32) `pacman -Syu xcb-util-wm seatd git clang meson libinput libdrm mesa libxkbcommon wayland wayland-protocols xorg-server-xwayland scdoc hwdata`  
- [Alpine](https://github.com/cage-kiosk/cage/blob/eaeab71ffa3ab5884df09c5664c00e368ca2585e/.github/workflows/main.yml#L26) `apk add build-base xcb-util-wm-dev libseat-dev clang git eudev-dev mesa-dev libdrm-dev libinput-dev libxkbcommon-dev pixman-dev wayland-dev meson wayland-protocols xwayland-dev scdoc-doc hwdata`
- Fedora `dnf install gcc gnupg2 meson libwayland-server libxkbcommon-devel libdisplay-info libliftoff hwdata lcms2 libdrm libinput libseat vulkan libwayland-client pixman-devel wayland-devel wayland-protocols-devel libdrm-devel libxcb-devel xcb-util-renderutil-devel seatd libseat-devel systemd-devel git patch`
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

## Usage
Install the previously built binaries and the script to /usr/local/bin.  
Run from within the cage-xtmapper directory:

    cd build/installed/usr/local/bin/
    sudo install -Dm755 ./cage_xtmapper /usr/local/bin/
    sudo install -Dm755 ./cage_xtmapper.sh /usr/local/bin/
Run the [cage_xtmapper.sh](./cage_xtmapper.sh) script.  

    sudo -E cage_xtmapper.sh --user $(whoami) --window-width 1280 --window-height 720 --window-no-title-bar
Enable cursor on subsurface if cursor is invisible:
  
    waydroid prop set persist.waydroid.cursor_on_subsurface true
- wlroots x11 and wayland backends were modified to use a custom resolution set by the `XTMAPPER_WIDTH` and `XTMAPPER_HEIGHT` environment variables.  
- Wayland only - Hide window title bar when `WLR_NO_DECORATION=1` or `--window-no-title-bar` is set.  
- Use F10 or any other key defined in  [togglekey.h](https://github.com/Xtr126/cage/blob/master/togglekey.h) to toggle between XtMapper or Waydroid handling mouse input.
- Direct touchmap mode feature doesn't work, but you can use a simple udev hack:  
We actually have to change `ID_INPUT_TOUCHPAD` to `ID_INPUT_TOUCHSCREEN`. So the following command would do that easily:
```bash
 sudo find /run/udev -type f -exec sed -i 's/ID_INPUT_TOUCHPAD/ID_INPUT_TOUCHSCREEN/g' {} \;
```
To revert:
```bash
 sudo find /run/udev -type f -exec sed -i 's/ID_INPUT_TOUCHSCREEN/ID_INPUT_TOUCHPAD/g' {} \;
```
Works fine on plasma 6.1.5 and Arch Linux.  
Also recommend enabling "Touch points" from System Settings > Window Management > Desktop effects to visualize touches.
