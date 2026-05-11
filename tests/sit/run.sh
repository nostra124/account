#!/bin/sh
# Drive the depends-script SIT matrix across container images.
#
# For each (image × depends-name) pair, run the inner runner.sh inside
# a fresh container with the repo bind-mounted read-only. The depends
# scripts only ever write to /usr/local/bin (sudo shim) and the package
# manager's own state — both inside the container's writable layer.
#
# Soft-skips when no container engine is available so `make check-sit`
# stays green on dev machines without podman/docker.
#
# Env knobs:
#   SIT_ENGINE  force "podman" or "docker"
#   SIT_IMAGES  override the image list (whitespace-separated)
#   SIT_NAMES   override the depends-name list (whitespace-separated)
set -eu

REPO=$(cd "$(dirname "$0")/../.." && pwd)

ENGINE=${SIT_ENGINE:-}
if [ -z "$ENGINE" ]; then
	for c in podman docker; do
		if command -v "$c" >/dev/null 2>&1; then ENGINE=$c; break; fi
	done
fi
[ -n "$ENGINE" ] || {
	echo "SIT: no container engine (set SIT_ENGINE or install podman/docker); skipping"
	exit 0
}

IMAGES=${SIT_IMAGES:-"
	ubuntu:latest
	debian:stable-slim
	fedora:latest
	archlinux:latest
	alpine:latest
"}

NAMES=${SIT_NAMES:-"gpg openssh rpk"}

fail=0
total=0
for image in $IMAGES; do
	for name in $NAMES; do
		total=$((total + 1))
		printf '::: %-22s %s\n' "$image" "depends/$name"
		if ! "$ENGINE" run --rm \
			-v "$REPO":/work:ro \
			-w /work \
			-e HOME=/root \
			"$image" sh /work/tests/sit/runner.sh "$name"; then
			echo "::: FAIL $image depends/$name"
			fail=$((fail + 1))
		fi
	done
done

if [ "$fail" -ne 0 ]; then
	echo "SIT: $fail / $total failures"
	exit 1
fi
echo "SIT: $total / $total ok"
