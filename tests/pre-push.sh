#!/bin/sh
# Pre-push test runner. Selects test layers based on environment:
#   - Unit (bats)       — always, when bats is on PATH
#   - SIT (containers)  — only if podman or docker is on PATH
#   - PIT (perf/integ.) — only if tests/pit/ exists AND a container engine is on PATH
#
# Exit codes:
#   0   every layer that ran succeeded (skipped layers don't fail)
#   1   one or more layers reported a failure
#   2   internal error (missing dir, etc.)
#
# Soft-skips on missing prerequisites are deliberate: the same
# script runs in three environments (cloud sandbox, desktop, CI)
# and each has a different available toolset. Where a layer's
# prerequisite IS present, a failure in that layer fails the
# script — never silent.
set -u

REPO=$(cd "$(dirname "$0")/.." && pwd)
cd "$REPO" || exit 2

fail=0
ran=""

# --- Unit ----------------------------------------------------------------
if command -v bats >/dev/null 2>&1; then
	echo "==> pre-push: unit tests (bats)"
	if bats tests/unit/*.bats; then
		ran="$ran unit"
	else
		echo "pre-push: unit tests FAILED" >&2
		fail=1
	fi
else
	echo "==> pre-push: skip unit (bats not on PATH)"
fi

# --- SIT / PIT — require a *functional* container engine ----------------
# `command -v` would say docker is present whenever the CLI is
# installed, but docker also needs a reachable daemon. We probe
# with `$ENGINE ps` (cheap, requires the daemon for docker; works
# offline for rootless podman). A non-functional engine is treated
# as "no engine available" so the layer soft-skips cleanly.
ENGINE=""
for c in podman docker; do
	if command -v "$c" >/dev/null 2>&1; then
		if "$c" ps >/dev/null 2>&1; then
			ENGINE=$c
			break
		else
			echo "==> pre-push: $c installed but not reachable (daemon down?)"
		fi
	fi
done

if [ -n "$ENGINE" ]; then
	echo "==> pre-push: SIT (engine=$ENGINE)"
	if SIT_ENGINE=$ENGINE tests/sit/run.sh; then
		ran="$ran sit"
	else
		echo "pre-push: SIT FAILED" >&2
		fail=1
	fi

	if [ -d tests/pit ]; then
		echo "==> pre-push: PIT"
		# Run *.sh and *.bats files under tests/pit/ — convention
		# matches tests/sit/. No assumption about which is present.
		pit_ran=0
		for t in tests/pit/run.sh tests/pit/*.bats; do
			[ -e "$t" ] || continue
			pit_ran=1
			case $t in
			*.sh)
				if ! sh "$t"; then
					echo "pre-push: PIT $t FAILED" >&2
					fail=1
				fi
				;;
			*.bats)
				if command -v bats >/dev/null 2>&1; then
					if ! bats "$t"; then
						echo "pre-push: PIT $t FAILED" >&2
						fail=1
					fi
				fi
				;;
			esac
		done
		[ "$pit_ran" -eq 1 ] && ran="$ran pit"
	fi
else
	echo "==> pre-push: skip SIT/PIT (no container engine on PATH)"
fi

# Failure must be reported before the "nothing ran" short-circuit:
# a layer can fail (fail=1) without contributing to `ran` (which
# only tracks successful layers). Reporting fail first ensures a
# failed layer never silently exits 0.
if [ "$fail" -ne 0 ]; then
	echo "==> pre-push: FAILED (layers run:$ran)" >&2
	exit 1
fi

if [ -z "$ran" ]; then
	echo "==> pre-push: nothing ran (no bats, no container engine)" >&2
	echo "==> pre-push: install bats and/or podman to enable local pre-push checks." >&2
	exit 0
fi

echo "==> pre-push: OK (layers run:$ran)"
