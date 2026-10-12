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
        [[ $4 == xtr.keymapper ]] && printf 'package:/data/app/xt mapper/base.apk\r\n'
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
    [[ $4 == xtr.keymapper ]] && printf 'package:/data/app/xt mapper/base.apk\r\n'
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
[[ $(cat "$tmp/remote-stdin") == 'ui stream' ]] || fail 'Waydroid input stream was not preserved'
if MOCK_CAGE_STATUS=9 "$launcher" --adb >/dev/null 2>&1; then
    fail 'cage_xtmapper pipeline failure was hidden'
fi

printf 'launcher tests passed\n'
