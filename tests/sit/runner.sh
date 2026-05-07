#!/bin/sh
# Inner-container SIT runner: install one depends/<name> script in a
# fresh image, then assert the target tool is on PATH.
#
# Invoked by tests/sit/run.sh inside a podman/docker container with the
# repo bind-mounted at /work. Exits 0 on success, non-zero with a
# diagnostic on failure. Echoes "skip" lines when the tool is already
# present in the base image (the install path is then not exercised but
# the early-exit branch is).
set -eu

NAME=${1:?missing depends name}

# Prefer /work (container bind-mount) but fall back to the repo this
# runner ships in, so the same script drives both the linux container
# matrix (run.sh) and the macOS CI runner (no container).
if [ -x "/work/.rpk/depends/$NAME" ]; then
	SCRIPT="/work/.rpk/depends/$NAME"
else
	SCRIPT="$(cd "$(dirname "$0")/../.." && pwd)/.rpk/depends/$NAME"
fi

[ -x "$SCRIPT" ] || { echo "SIT: $SCRIPT not executable" >&2; exit 2; }

export DEBIAN_FRONTEND=noninteractive

# depends/rpk is verify-only: the binary is the package manager itself,
# so the script must reject "rpk absent" and accept "rpk present". We
# assert both halves rather than installing anything.
if [ "$NAME" = rpk ]; then
	mkdir -p "$HOME/.local/bin"
	rm -f "$HOME/.local/bin/rpk"
	if "$SCRIPT" 2>/dev/null; then
		echo "SIT: depends/rpk should fail when \$HOME/.local/bin/rpk is absent" >&2
		exit 1
	fi
	printf '#!/bin/sh\nexit 0\n' > "$HOME/.local/bin/rpk"
	chmod +x "$HOME/.local/bin/rpk"
	"$SCRIPT"
	echo "SIT: rpk ok (verify-only)"
	exit 0
fi

# All other depends scripts call sudo. Most container images run as
# root with no sudo binary; shim it so the install path executes
# without requiring the image to ship sudo.
if ! command -v sudo >/dev/null 2>&1; then
	[ "$(id -u)" -eq 0 ] || {
		echo "SIT: sudo missing and not root; cannot proceed" >&2
		exit 2
	}
	cat > /usr/local/bin/sudo <<'SUDO'
#!/bin/sh
exec "$@"
SUDO
	chmod +x /usr/local/bin/sudo
fi

# Refresh package metadata so first-use installs can resolve names.
# apt-get install / pacman -S / apk add do not implicitly fetch the
# index; the depends scripts intentionally don't do this either, since
# in a real deployment the index is already current.
if command -v apt-get >/dev/null 2>&1; then
	apt-get update -qq >/dev/null
elif command -v pacman >/dev/null 2>&1; then
	pacman -Sy --noconfirm >/dev/null
elif command -v apk >/dev/null 2>&1; then
	apk update >/dev/null
fi

# Map depends-name → command we can `command -v` to confirm install.
# openssh installs ssh, ssh-keygen, etc.; the script's own probe is
# ssh-keygen, so we mirror that here.
case "$NAME" in
	openssh) CHECK=ssh-keygen ;;
	*)       CHECK=$NAME ;;
esac

if command -v "$CHECK" >/dev/null 2>&1; then
	"$SCRIPT"
	echo "SIT: $NAME skip-install ($CHECK already in base image; early-exit path exercised)"
	exit 0
fi

"$SCRIPT"

command -v "$CHECK" >/dev/null 2>&1 || {
	echo "SIT: $CHECK still not on PATH after running depends/$NAME" >&2
	exit 1
}

echo "SIT: $NAME ok ($CHECK installed)"
