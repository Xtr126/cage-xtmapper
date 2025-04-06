#!/bin/bash
while [ $# -gt 0 ]; do
    case "$1" in
    --user)
        shift
        user="$1"
        ;;
    --window-width)
        shift
        XTMAPPER_WIDTH="$1"
        ;;
    --window-height)
        shift
        XTMAPPER_HEIGHT="$1"
        ;;
    --window-no-title-bar)
        export WLR_NO_DECORATION=1
        ;;

    --adb)
        use_adb=1
        ;;
    *)
	echo "Invalid argument"
        exit 1
	;;
    esac
    shift
done

if [ "$use_adb" != 1 ]; then
    if [ "$(id -u)" != "0" ]; then
        echo "This script requires root access to access waydroid shell."
        exit 1
    fi

    if [[ -z "$user" ]]; then
        echo "User not specified."
        exit 1
    fi
    waydroid container stop
else
    sudo waydroid container stop
fi

export XTMAPPER_WIDTH=${XTMAPPER_WIDTH:-1280}
export XTMAPPER_HEIGHT=${XTMAPPER_HEIGHT:-720}

systemctl restart waydroid-container.service

if [ "$use_adb" != 1 ]; then
    su "$user" --command "cage_xtmapper waydroid show-full-ui" | (
        while [[ -z $(waydroid shell getprop sys.boot_completed) ]]; do
            sleep 1;
        done;

        ABI=$(waydroid shell getprop ro.product.cpu.abi | tr -d '\r')

        for pkg in "xtr.keymapper.debug" "xtr.keymapper"; do
            APK_PATH=$(waydroid shell pm path "$pkg" 2>/dev/null | cut -d ':' -f 2 | tr -d '\r')
            if [ -n "$APK_PATH" ]; then
                APK_DIR=$(dirname "$APK_PATH")
                NATIVE_LIB_PATH="$APK_DIR/lib/$ABI"
                SELECTED_PKG="$pkg"
                break
            fi
        done

        if [ -z "$APK_PATH" ]; then
            echo "Error: No installation of XtMapper was found!"
            exit 1
        fi

        exec waydroid shell -- sh -c "exec /system/bin/app_process \
            -Djava.library.path="$NATIVE_LIB_PATH" \
            -Djava.class.path="$APK_PATH" \
            / xtr.keymapper.server.RemoteServiceShell \
            --wayland-client"

    )
else
    cage_xtmapper waydroid show-full-ui | (
        while [[ -z $(adb wait-for-device shell getprop sys.boot_completed) ]]; do
            sleep 1;
        done;

        ABI=$(adb shell getprop ro.product.cpu.abi | tr -d '\r')

        for pkg in "xtr.keymapper.debug" "xtr.keymapper"; do
            APK_PATH=$(adb shell pm path "$pkg" 2>/dev/null | cut -d ':' -f 2 | tr -d '\r')
            if [ -n "$APK_PATH" ]; then
                APK_DIR=$(dirname "$APK_PATH")
                NATIVE_LIB_PATH="$APK_DIR/lib/$ABI"
                SELECTED_PKG="$pkg"
                break
            fi
        done

        if [ -z "$APK_PATH" ]; then
            echo "Error: No installation of XtMapper was found!"
            exit 1
        fi

        CMD="/system/bin/app_process \\
            -Djava.library.path=\"$NATIVE_LIB_PATH\" \\
            -Djava.class.path=\"$APK_PATH\" \\
            / xtr.keymapper.server.RemoteServiceShell \\
            --wayland-client"

        exec adb shell "$CMD"
    )
fi
