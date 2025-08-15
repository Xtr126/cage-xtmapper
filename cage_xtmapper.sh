#!/bin/bash

while [ $# -gt 0 ]; do
    case "$1" in
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

waydroid session stop

export XTMAPPER_WIDTH=${XTMAPPER_WIDTH:-1280}
export XTMAPPER_HEIGHT=${XTMAPPER_HEIGHT:-720}
BOOTCLASSPATH=/apex/com.android.art/javalib/core-oj.jar:/apex/com.android.art/javalib/core-libart.jar:/apex/com.android.art/javalib/okhttp.jar:/apex/com.android.art/javalib/bouncycastle.jar:/apex/com.android.art/javalib/apache-xml.jar:/system/framework/framework.jar:/system/framework/framework-graphics.jar:/system/framework/ext.jar:/system/framework/telephony-common.jar:/system/framework/voip-common.jar:/system/framework/ims-common.jar:/apex/com.android.i18n/javalib/core-icu4j.jar:/apex/com.android.adservices/javalib/framework-adservices.jar:/apex/com.android.adservices/javalib/framework-sdksandbox.jar:/apex/com.android.appsearch/javalib/framework-appsearch.jar:/apex/com.android.btservices/javalib/framework-bluetooth.jar:/apex/com.android.conscrypt/javalib/conscrypt.jar:/apex/com.android.ipsec/javalib/android.net.ipsec.ike.jar:/apex/com.android.media/javalib/updatable-media.jar:/apex/com.android.mediaprovider/javalib/framework-mediaprovider.jar:/apex/com.android.ondevicepersonalization/javalib/framework-ondevicepersonalization.jar:/apex/com.android.os.statsd/javalib/framework-statsd.jar:/apex/com.android.permission/javalib/framework-permission.jar:/apex/com.android.permission/javalib/framework-permission-s.jar:/apex/com.android.scheduling/javalib/framework-scheduling.jar:/apex/com.android.sdkext/javalib/framework-sdkextensions.jar:/apex/com.android.tethering/javalib/framework-connectivity.jar:/apex/com.android.tethering/javalib/framework-connectivity-t.jar:/apex/com.android.tethering/javalib/framework-tethering.jar:/apex/com.android.uwb/javalib/framework-uwb.jar:/apex/com.android.wifi/javalib/framework-wifi.jar

sudo waydroid container start

if [ "$use_adb" != 1 ]; then
    cage_xtmapper waydroid show-full-ui | (
        while [[ -z $(sudo waydroid shell getprop sys.boot_completed) ]]; do
            sleep 1;
        done;

        ABI=$(sudo waydroid shell getprop ro.product.cpu.abi | tr -d '\r')

        for pkg in "xtr.keymapper.debug" "xtr.keymapper"; do
            APK_PATH=$(sudo waydroid shell pm path "$pkg" 2>/dev/null | cut -d ':' -f 2 | tr -d '\r')
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

        exec sudo waydroid shell -- sh -c "exec env BOOTCLASSPATH=\$BOOTCLASSPATH:$BOOTCLASSPATH /system/bin/app_process \
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
