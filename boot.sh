#!/bin/bash

set -Eeufo pipefail

debug=0
cpus="$(nproc)"
memory="$(( $(sysctl hw.memsize | cut -d ' ' -f 2) / (1024 * 1024) ))"
login=0
drive_opt="-d"
root_opt="rw"

while [[ $# -gt 0 ]]; do
	case "$1" in
		--debug)
			debug=1
			shift
			;;
		-c|--cpus)
			shift
			cpus="$1"
			shift
			;;
		-m|--memory)
			shift
			memory="$1"
			shift
			;;
		-l|--login)
			login=1
			shift
			;;
		-r|--readonly)
			drive_opt="-c"
			root_opt="ro"
			shift
			;;
		*)
			break
			;;
	esac
done

img="$(realpath $1)"
shift

if [ "$debug" = 1 ]; then
	set -x
fi

tmp=$(mktemp -d -t vfboot)
cd "$tmp"

function cleanup {
	rm -rf "$tmp"
}
trap cleanup EXIT

$(brew --prefix e2fsprogs)/sbin/debugfs -R "cat /boot/Image" "$img" > kernel 2> debugfs_err
[ -s kernel ] || (cat debugfs_err >&2; exit 1)
rm debugfs_err

if [ "$login" = 0 ]; then
	(
		trap cleanup EXIT
		vftool -p "$cpus" -m "$memory" -k kernel -a "console=hvc0 root=/dev/vda $root_opt systemd.mask=getty.target" "$drive_opt" "$img" -t 0 "$@"
	) 0<&- &> console &
	echo "$!" > PID
	disown
	trap - EXIT
else
	vftool -p "$cpus" -m "$memory" -k kernel -a "console=hvc0 root=/dev/vda $root_opt" "$drive_opt" "$img" "$@"
fi
