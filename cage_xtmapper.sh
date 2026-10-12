#!/usr/bin/env bash

set -o pipefail

BOOT_WAIT_SECONDS=${XTMAPPER_BOOT_WAIT_SECONDS:-120}

usage() {
    cat <<'EOF'
Usage: cage_xtmapper.sh [options]

Options:
  --window-width PIXELS       Set output width (positive integer)
  --window-height PIXELS      Set output height (positive integer)
  --refresh-mhz MHZ           Set output refresh rate (positive integer)
  --print-output-info         Print output information and exit
  --window-show-title-bar      Show the window title bar
  --adb                        Use adb instead of Waydroid's sudo shell
  --xtmapper-args ARG...       Pass remaining arguments to XtMapper
  -h, --help                   Show this help
EOF
}

error() {
    printf 'Error: %s\n' "$*" >&2
}

if ! [[ $BOOT_WAIT_SECONDS =~ ^[1-9][0-9]*$ ]]; then
    error 'XTMAPPER_BOOT_WAIT_SECONDS must be a positive integer'
    exit 2
fi

valid_positive_integer() {
    [[ $1 =~ ^[0-9]+$ ]] && (( 10#$1 > 0 ))
}

shell_quote() {
    local value=$1
    value=${value//\'/\'\\\'\'}
    printf "'%s'" "$value"
}

# Steam gaming mode
if [[ -n ${GAMESCOPE_WAYLAND_DISPLAY:-} ]]; then
    unset DISPLAY
    export WAYLAND_DISPLAY="$GAMESCOPE_WAYLAND_DISPLAY"
fi

xtmapper_args=("--wayland-client")
export WLR_NO_DECORATION=1
use_adb=0

while (($#)); do
    case $1 in
        --window-width|--window-height|--refresh-mhz)
            option=$1
            shift
            if (($# == 0)) || [[ $1 == --* ]]; then
                error "$option requires a value"
                exit 2
            fi
            if ! valid_positive_integer "$1"; then
                error "$option must be a positive integer"
                exit 2
            fi
            case $option in
                --window-width) export XTMAPPER_WIDTH=$1 ;;
                --window-height) export XTMAPPER_HEIGHT=$1 ;;
                --refresh-mhz) export XTMAPPER_REFRESH=$1 ;;
            esac
            ;;
        --print-output-info)
            command -v cage_xtmapper >/dev/null || { error 'cage_xtmapper was not found in PATH'; exit 127; }
            XTMAPPER_WIDTH=1 XTMAPPER_HEIGHT=1 XTMAPPER_PRINT_OUTPUT_INFO=1 cage_xtmapper -- sleep 1
            exit $?
            ;;
        --window-show-title-bar) export WLR_NO_DECORATION=0 ;;
        --adb) use_adb=1 ;;
        --xtmapper-args)
            shift
            while (($#)); do
                xtmapper_args+=("$1")
                shift
            done
            break
            ;;
        -h|--help) usage; exit 0 ;;
        *) error "invalid argument: $1"; usage >&2; exit 2 ;;
    esac
    shift
done

if ! command -v cage_xtmapper >/dev/null 2>&1; then
    error 'cage_xtmapper was not found in PATH'
    exit 127
fi
if ((use_adb)); then
    command -v adb >/dev/null 2>&1 || { error 'adb was not found in PATH'; exit 127; }
else
    command -v sudo >/dev/null 2>&1 || { error 'sudo was not found in PATH'; exit 127; }
    command -v waydroid >/dev/null 2>&1 || { error 'waydroid was not found in PATH'; exit 127; }
fi

if ((!use_adb)); then
    if ! waydroid session stop; then
        error 'could not stop the Waydroid session'
        exit 1
    fi
    BOOTCLASSPATH=/apex/com.android.art/javalib/core-oj.jar:/apex/com.android.art/javalib/core-libart.jar:/apex/com.android.art/javalib/okhttp.jar:/apex/com.android.art/javalib/bouncycastle.jar:/apex/com.android.art/javalib/apache-xml.jar:/system/framework/framework.jar:/system/framework/framework-graphics.jar:/system/framework/ext.jar:/system/framework/telephony-common.jar:/system/framework/voip-common.jar:/system/framework/ims-common.jar:/apex/com.android.i18n/javalib/core-icu4j.jar:/apex/com.android.adservices/javalib/framework-adservices.jar:/apex/com.android.adservices/javalib/framework-sdksandbox.jar:/apex/com.android.btservices/javalib/framework-bluetooth.jar:/apex/com.android.conscrypt/javalib/conscrypt.jar:/apex/com.android.ipsec/javalib/android.net.ipsec.ike.jar:/apex/com.android.media/javalib/updatable-media.jar:/apex/com.android.mediaprovider/javalib/framework-mediaprovider.jar:/apex/com.android.ondevicepersonalization/javalib/framework-ondevicepersonalization.jar:/apex/com.android.os.statsd/javalib/framework-statsd.jar:/apex/com.android.permission/javalib/framework-permission.jar:/apex/com.android.permission/javalib/framework-permission-s.jar:/apex/com.android.scheduling/javalib/framework-scheduling.jar:/apex/com.android.sdkext/javalib/framework-sdkextensions.jar:/apex/com.android.tethering/javalib/framework-connectivity.jar:/apex/com.android.tethering/javalib/framework-connectivity-t.jar:/apex/com.android.uwb/javalib/framework-uwb.jar:/apex/com.android.wifi/javalib/framework-wifi.jar
    if ! sudo waydroid container start; then
        error 'could not start the Waydroid container'
        exit 1
    fi
fi

if ((use_adb)); then
    launch_ui() { cage_xtmapper -s -m last -- waydroid show-full-ui; }
    getprop() { adb shell getprop "$1"; }
    package_path() { adb shell pm path "$1" 2>/dev/null; }
    remote_shell() { adb shell "$1"; }
else
    launch_ui() { cage_xtmapper -s -m last -- waydroid show-full-ui; }
    getprop() { sudo waydroid shell getprop "$1"; }
    package_path() { sudo waydroid shell pm path "$1" 2>/dev/null; }
    remote_shell() { sudo waydroid shell -- sh -c "$1"; }
fi

launch_ui | (
    booted=0
    for ((second=0; second<BOOT_WAIT_SECONDS; second++)); do
        boot_state=$(getprop sys.boot_completed 2>/dev/null | tr -d '\r') || boot_state=
        if [[ $boot_state == 1 ]]; then
            booted=1
            break
        fi
        sleep 1
    done
    if ((!booted)); then
        error "Android did not finish booting within ${BOOT_WAIT_SECONDS} seconds"
        exit 1
    fi

    ABI=$(getprop ro.product.cpu.abi 2>/dev/null | tr -d '\r') || ABI=
    if [[ -z $ABI ]]; then
        error 'could not determine the Android CPU ABI'
        exit 1
    fi

    APK_PATH=
    for pkg in xtr.keymapper.debug xtr.keymapper; do
        APK_PATH=$(package_path "$pkg" | tr -d '\r' | sed -n 's/^package://p' | head -n 1)
        if [[ -n $APK_PATH ]]; then
            break
        fi
    done
    if [[ -z $APK_PATH ]]; then
        error 'no installation of XtMapper was found'
        exit 1
    fi

    APK_DIR=${APK_PATH%/*}
    NATIVE_LIB_PATH="$APK_DIR/lib/$ABI"
    if ((use_adb)); then
        remote_command="exec /system/bin/app_process -Djava.library.path=$(shell_quote "$NATIVE_LIB_PATH") -Djava.class.path=$(shell_quote "$APK_PATH") / xtr.keymapper.server.RemoteServiceShell"
    else
        remote_command="exec env BOOTCLASSPATH=\$BOOTCLASSPATH:$(shell_quote "$BOOTCLASSPATH") /system/bin/app_process -Djava.library.path=$(shell_quote "$NATIVE_LIB_PATH") -Djava.class.path=$(shell_quote "$APK_PATH") / xtr.keymapper.server.RemoteServiceShell"
    fi
    for arg in "${xtmapper_args[@]}"; do
        remote_command+=" $(shell_quote "$arg")"
    done
    remote_shell "$remote_command"
)
