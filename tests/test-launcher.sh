#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
launcher=$repo/cage_xtmapper.sh
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin"

cat >"$tmp/bin/cage_xtmapper" <<'MOCK'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$MOCK_LOG/cage.log"
printf 'ui stream\n'
exit "${MOCK_CAGE_STATUS:-0}"
MOCK
cat >"$tmp/bin/sudo" <<'MOCK'
#!/usr/bin/env bash
exec "$@"
MOCK
cat >"$tmp/bin/waydroid" <<'MOCK'
#!/usr/bin/env bash
printf 'waydroid %s\n' "$*" >>"$MOCK_LOG/waydroid.log"
case "$1 $2" in
    'session stop'|'container start') exit 0 ;;
    'shell getprop')
        case $3 in
            sys.boot_completed) printf '%s\r\n' "${MOCK_BOOT_STATUS:-1}" ;;
            ro.product.cpu.abi) printf 'x86_64\r\n' ;;
        esac
        ;;
    'shell pm')
        case $4 in
            xtr.keymapper.debug)
                [[ ${MOCK_DEBUG_APK:-0} == 1 ]] && printf 'package:/data/app/debug/base.apk\r\n'
                ;;
            xtr.keymapper)
                [[ ${MOCK_RELEASE_APK:-1} == 1 ]] && printf 'package:/data/app/xt mapper/base.apk\r\n'
                ;;
        esac
        ;;
    'shell --')
        printf '%s\n' "$5" >"$MOCK_LOG/remote-command"
        cat >"$MOCK_LOG/remote-stdin"
        ;;
    *) exit 1 ;;
esac
MOCK
cat >"$tmp/bin/adb" <<'MOCK'
#!/usr/bin/env bash
printf 'adb %s\n' "$*" >>"$MOCK_LOG/adb.log"
if [[ $1 == wait-for-device ]]; then exit 0; fi
if [[ $1 == shell && $2 == getprop ]]; then
    [[ $3 == sys.boot_completed ]] && printf '%s\r\n' "${MOCK_BOOT_STATUS:-1}" || printf 'x86_64\r\n'
elif [[ $1 == shell && $2 == pm ]]; then
    case $4 in
            xtr.keymapper.debug)
                [[ ${MOCK_DEBUG_APK:-0} == 1 ]] && printf 'package:/data/app/debug/base.apk\r\n'
                ;;
            xtr.keymapper)
                [[ ${MOCK_RELEASE_APK:-1} == 1 ]] && printf 'package:/data/app/xt mapper/base.apk\r\n'
                ;;
        esac
elif [[ $1 == shell ]]; then
    printf '%s\n' "$2" >"$MOCK_LOG/remote-command"
    cat >"$MOCK_LOG/remote-stdin"
fi
MOCK
chmod +x "$tmp/bin/"*
export PATH="$tmp/bin:$PATH" MOCK_LOG="$tmp"

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

"$launcher" --help >"$tmp/help"
grep -q -- '--refresh-mhz' "$tmp/help" || fail 'help omitted options'
[[ ! -e $tmp/cage.log ]] || fail 'help invoked launcher commands'

for option in --window-width --window-height --refresh-mhz; do
    if "$launcher" "$option" >/dev/null 2>&1; then fail "$option accepted a missing value"; fi
    if "$launcher" "$option" nope >/dev/null 2>&1; then fail "$option accepted nonnumeric input"; fi
    if "$launcher" "$option" 0 >/dev/null 2>&1; then fail "$option accepted zero"; fi
done
if "$launcher" --not-an-option >/dev/null 2>&1; then fail 'accepted unknown option'; fi

"$launcher" --adb --xtmapper-args 'arg with spaces' "quote'and;touch /tmp/launcher-injected" >"$tmp/output"
grep -q "'arg with spaces'" "$tmp/remote-command" || fail 'remote argument with spaces was split'
grep -q "quote'\\\\''and;touch /tmp/launcher-injected" "$tmp/remote-command" || fail 'remote shell metacharacters were not quoted'
[[ $(cat "$tmp/remote-stdin") == 'ui stream' ]] || fail 'launcher output was not streamed to remote service stdin'
[[ ! -e /tmp/launcher-injected ]] || fail 'remote argument caused local shell injection'

rm -f "$tmp/remote-command"
if MOCK_BOOT_STATUS=10 XTMAPPER_BOOT_WAIT_SECONDS=2 "$launcher" --adb >/dev/null 2>"$tmp/boot-error"; then
    fail 'boot state other than 1 was accepted'
fi
grep -q 'did not finish booting' "$tmp/boot-error" || fail 'boot timeout error was not reported'
[[ ! -e $tmp/remote-command ]] || fail 'remote service launched before Android boot completed'

rm -f "$tmp/remote-command" "$tmp/remote-stdin"
"$launcher" --xtmapper-args 'waydroid arg' >/dev/null
grep -q "'waydroid arg'" "$tmp/remote-command" || fail 'Waydroid remote argument was not quoted'
grep -q "BOOTCLASSPATH=\\\$BOOTCLASSPATH:" "$tmp/remote-command" || fail 'Waydroid boot class path was not preserved'
[[ $(cat "$tmp/remote-stdin") == 'ui stream' ]] || fail 'Waydroid input stream was not preserved'

rm -f "$tmp/remote-command"
MOCK_DEBUG_APK=1 "$launcher" --adb >/dev/null
grep -q '/data/app/debug/base.apk' "$tmp/remote-command" || fail 'debug package was not preferred when installed'

rm -f "$tmp/remote-command"
if MOCK_DEBUG_APK=0 MOCK_RELEASE_APK=0 "$launcher" --adb >/dev/null 2>"$tmp/package-error"; then
    fail 'launcher succeeded without an installed XtMapper package'
fi
grep -q 'no installation of XtMapper' "$tmp/package-error" || fail 'missing package error was not reported'
[[ ! -e $tmp/remote-command ]] || fail 'remote service launched without an APK'

mkdir -p "$tmp/no-adb" "$tmp/no-waydroid"
if PATH=/usr/bin:/bin bash "$launcher" --adb >/dev/null 2>"$tmp/command-error"; then
    fail 'launcher succeeded without cage_xtmapper in PATH'
fi
grep -q 'cage_xtmapper was not found' "$tmp/command-error" || fail 'missing launcher command error was not reported'
ln -s "$tmp/bin/cage_xtmapper" "$tmp/no-adb/cage_xtmapper"
if PATH="$tmp/no-adb" /bin/bash "$launcher" --adb >/dev/null 2>"$tmp/adb-error"; then
    fail 'adb transport succeeded without adb'
fi
grep -q 'adb was not found' "$tmp/adb-error" || fail 'missing adb error was not reported'
ln -s "$tmp/bin/cage_xtmapper" "$tmp/no-waydroid/cage_xtmapper"
ln -s "$tmp/bin/sudo" "$tmp/no-waydroid/sudo"
if PATH="$tmp/no-waydroid" /bin/bash "$launcher" >/dev/null 2>"$tmp/waydroid-error"; then
    fail 'Waydroid transport succeeded without waydroid'
fi
grep -q 'waydroid was not found' "$tmp/waydroid-error" || fail 'missing Waydroid error was not reported'

rm -f "$tmp/remote-command"
if MOCK_DEBUG_APK=0 MOCK_RELEASE_APK=0 "$launcher" >/dev/null 2>"$tmp/waydroid-package-error"; then
    fail 'Waydroid transport succeeded without an installed XtMapper package'
fi
grep -q 'no installation of XtMapper' "$tmp/waydroid-package-error" || fail 'Waydroid missing package error was not reported'
[[ ! -e $tmp/remote-command ]] || fail 'Waydroid remote service launched without an APK'

if XTMAPPER_BOOT_WAIT_SECONDS=0 "$launcher" --help >/dev/null 2>"$tmp/wait-error"; then
    fail 'invalid boot timeout was accepted'
fi
grep -q 'XTMAPPER_BOOT_WAIT_SECONDS' "$tmp/wait-error" || fail 'invalid boot timeout error was not reported'
if MOCK_CAGE_STATUS=9 "$launcher" --adb >/dev/null 2>&1; then
    fail 'cage_xtmapper pipeline failure was hidden'
fi

printf 'launcher tests passed\n'
