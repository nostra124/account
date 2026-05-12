#!/usr/bin/env bats
#
# Unit tests for bin/account — the foundation identity primitive
# (FEAT-022). This suite is the structural integrity of `account`'s
# public surface; per FEAT-005 the script's CLI is semver-pinned, so
# any rename / removal / signature change here must bump the major
# version in `command:version`.
#
# Coverage scope: every pure-bash subcommand whose happy path doesn't
# require gpg / ssh / fping / sudo, plus the error paths of the
# subcommands that *do* shell out (the early-validation `fatal` exits
# happen before any external call). Subcommands that genuinely need
# gpg / ssh / network are left to the SIT suite (FEAT-207 cross-pkg,
# and the per-script SIT once filed).
#
# Bug history: BUG-001 (fatal-without-exit-status) was discovered
# while writing this suite — fixed by defaulting `$2` in the helper.
# Tests below assert the corrected non-zero exit behaviour.
#
# Sandbox $HOME per test (rpk pattern) so the suite never touches the
# developer's real ~/.config/account or ~/.gnupg / ~/.ssh.

setup() {
	BATS_TMPDIR=${BATS_TMPDIR:-$(mktemp -d)}
	HOME="$(mktemp -d "$BATS_TMPDIR/home.XXXXXX")"
	# Reset every XDG_* var that could leak from the runner's
	# environment (GitHub Actions sets several) before pinning each
	# to a sandboxed sub-path of HOME.
	unset XDG_CACHE_HOME XDG_CONFIG_HOME XDG_DATA_HOME XDG_SHARE_HOME
	unset XDG_SOURCE_HOME XDG_BACKUP_HOME XDG_RUNTIME_DIR
	export HOME
	export XDG_CACHE_HOME="$HOME/.cache"
	export XDG_CONFIG_HOME="$HOME/.config"
	export XDG_DATA_HOME="$HOME/.local/var"
	export XDG_SHARE_HOME="$HOME/.local/share"
	export XDG_SOURCE_HOME="$HOME/.local/src"
	export XDG_BACKUP_HOME="$HOME/backups"
	export SELF_QUIET=1
	# FEAT-208: tell bin/account to honour the sandboxed $HOME even
	# under EUID==0 instead of re-deriving it via `sudo -i`. Without
	# this, 8 tests would have to `skip` whenever the suite runs
	# under root (container CI, devcontainers).
	export ACCOUNT_HOME_OVERRIDE=1
	export ACCOUNT_BIN="$BATS_TEST_DIRNAME/../../bin/account"
	SELF_CONFIG="$XDG_CONFIG_HOME/account"
	mkdir -p "$SELF_CONFIG/ssh" "$SELF_CONFIG/gpg" "$SELF_CONFIG/slaves"
}

teardown() {
	rm -rf "$HOME"
}

# ---------------------------------------------------------------------------
# Smoke
# ---------------------------------------------------------------------------

@test "account binary exists and is executable" {
	[ -x "$ACCOUNT_BIN" ]
}

@test "account version returns a non-empty string" {
	run "$ACCOUNT_BIN" version
	[ "$status" -eq 0 ]
	[ -n "$output" ]
}

@test "account help prints usage" {
	run "$ACCOUNT_BIN" help
	[ -n "$output" ]
}

@test "account with no args prints help" {
	run "$ACCOUNT_BIN"
	[ -n "$output" ]
}

@test "unknown subcommand exits non-zero with fatal message" {
	# Unknown-command dispatcher uses `fatal "msg"` (no -1) → exit 1.
	# See FEAT-211 note before the "Early-validation error paths"
	# section for the convention.
	run "$ACCOUNT_BIN" definitely-not-a-real-subcommand
	[ "$status" -eq 1 ]
	[[ "$output" == *"fatal"* ]]
	[[ "$output" == *"unknown command"* ]]
}

@test "help <unknown-command> reports it as not an account command" {
	run "$ACCOUNT_BIN" help definitely-not-a-real-subcommand
	[[ "$output" == *"is not an account command"* ]]
}

# ---------------------------------------------------------------------------
# Help surface — every documented command group should be discoverable
# ---------------------------------------------------------------------------

@test "help mentions local account commands group" {
	run "$ACCOUNT_BIN" help
	[[ "$output" == *"local account commands"* ]]
}

@test "help mentions gpg related commands group" {
	run "$ACCOUNT_BIN" help
	[[ "$output" == *"gpg related commands"* ]]
}

@test "help mentions ssh related commands group" {
	run "$ACCOUNT_BIN" help
	[[ "$output" == *"ssh related commands"* ]]
}

@test "help mentions remote-url (FEAT-044 endpoint resolver)" {
	run "$ACCOUNT_BIN" help
	[[ "$output" == *"remote-url"* ]]
}

# ---------------------------------------------------------------------------
# Identity primitives (no external calls beyond `whoami` / `hostname`)
# ---------------------------------------------------------------------------

@test "username returns current whoami" {
	run "$ACCOUNT_BIN" username
	[ "$status" -eq 0 ]
	[ "$output" = "$(whoami)" ]
}

@test "hostname returns lowercased fqdn" {
	run "$ACCOUNT_BIN" hostname
	[ "$status" -eq 0 ]
	[ "$output" = "$(hostname -f | tr '[:upper:]' '[:lower:]')" ]
}

@test "nodename returns lowercased short hostname" {
	run "$ACCOUNT_BIN" nodename
	[ "$status" -eq 0 ]
	[ "$output" = "$(hostname -s | tr '[:upper:]' '[:lower:]')" ]
}

@test "identity returns user@hostname" {
	run "$ACCOUNT_BIN" identity
	[ "$status" -eq 0 ]
	[ "$output" = "$(whoami)@$(hostname -f | tr '[:upper:]' '[:lower:]')" ]
}

@test "domainname returns lowercased domain part" {
	run "$ACCOUNT_BIN" domainname
	[ "$status" -eq 0 ]
	[ "$output" = "$(hostname -d | tr '[:upper:]' '[:lower:]')" ]
}

# ---------------------------------------------------------------------------
# XDG home resolvers (no-arg form).
#
# Under EUID==0, bin/account substitutes system paths (/var/cache,
# /etc, /var, /usr/local/share, /usr/local/src, /var/backups) instead
# of the XDG envvars. Each test asserts both branches so the suite
# pins behaviour under root and non-root identically.
# ---------------------------------------------------------------------------

@test "home (no arg) returns \$HOME" {
	run "$ACCOUNT_BIN" home
	[ "$status" -eq 0 ]
	[ "$output" = "$HOME" ]
}

@test "cache-home (no arg) honours XDG_CACHE_HOME" {
	run "$ACCOUNT_BIN" cache-home
	[ "$status" -eq 0 ]
	if [ "$EUID" -eq 0 ]; then
		[ "$output" = "/var/cache" ]
	else
		[ "$output" = "$XDG_CACHE_HOME" ]
	fi
}

@test "config-home (no arg) honours XDG_CONFIG_HOME" {
	run "$ACCOUNT_BIN" config-home
	[ "$status" -eq 0 ]
	if [ "$EUID" -eq 0 ]; then
		[ "$output" = "/etc" ]
	else
		[ "$output" = "$XDG_CONFIG_HOME" ]
	fi
}

@test "data-home (no arg) honours XDG_DATA_HOME" {
	run "$ACCOUNT_BIN" data-home
	[ "$status" -eq 0 ]
	if [ "$EUID" -eq 0 ]; then
		[ "$output" = "/var" ]
	else
		[ "$output" = "$XDG_DATA_HOME" ]
	fi
}

@test "share-home (no arg) honours XDG_SHARE_HOME" {
	run "$ACCOUNT_BIN" share-home
	[ "$status" -eq 0 ]
	if [ "$EUID" -eq 0 ]; then
		[ "$output" = "/usr/local/share" ]
	else
		[ "$output" = "$XDG_SHARE_HOME" ]
	fi
}

@test "source-home (no arg) honours XDG_SOURCE_HOME" {
	run "$ACCOUNT_BIN" source-home
	[ "$status" -eq 0 ]
	if [ "$EUID" -eq 0 ]; then
		[ "$output" = "/usr/local/src" ]
	else
		[ "$output" = "$XDG_SOURCE_HOME" ]
	fi
}

@test "backup-home (no arg) honours XDG_BACKUP_HOME" {
	run "$ACCOUNT_BIN" backup-home
	[ "$status" -eq 0 ]
	if [ "$EUID" -eq 0 ]; then
		[ "$output" = "/var/backups" ]
	else
		[ "$output" = "$XDG_BACKUP_HOME" ]
	fi
}

# ---------------------------------------------------------------------------
# remote-url — pure string mapping (FEAT-044). Sibling tools depend on
# these endpoint shapes; any change here is a contract change.
# ---------------------------------------------------------------------------

@test "remote-url default purpose is password-store" {
	run "$ACCOUNT_BIN" remote-url alice@example.com
	[ "$status" -eq 0 ]
	[ "$output" = "alice@example.com:~/.password-store" ]
}

@test "remote-url password-store purpose is explicit form" {
	run "$ACCOUNT_BIN" remote-url alice@example.com password-store
	[ "$output" = "alice@example.com:~/.password-store" ]
}

@test "remote-url cluster-config purpose maps to ~/.config/cluster" {
	run "$ACCOUNT_BIN" remote-url alice@example.com cluster-config
	[ "$output" = "alice@example.com:~/.config/cluster" ]
}

@test "remote-url bitcoin-wallet/<name> maps under wallets" {
	run "$ACCOUNT_BIN" remote-url alice@example.com bitcoin-wallet/savings
	[ "$output" = "alice@example.com:~/.config/bitcoin/wallets/savings" ]
}

@test "remote-url config/<sub> maps under .config/<sub>" {
	run "$ACCOUNT_BIN" remote-url alice@example.com config/repo
	[ "$output" = "alice@example.com:~/.config/repo" ]
}

@test "remote-url secret/<sub> maps under .config/secret/<sub>" {
	run "$ACCOUNT_BIN" remote-url alice@example.com secret/box
	[ "$output" = "alice@example.com:~/.config/secret/box" ]
}

@test "remote-url unknown purpose falls through to .config/<purpose>" {
	run "$ACCOUNT_BIN" remote-url alice@example.com somecustom
	[ "$output" = "alice@example.com:~/.config/somecustom" ]
}

@test "remote-url without account exits non-zero" {
	# remote-url uses `fatal "msg" -1` → bash truncates to exit 255.
	run "$ACCOUNT_BIN" remote-url
	[ "$status" -eq 255 ]
	[[ "$output" == *"please specify an account"* ]]
}

# ---------------------------------------------------------------------------
# Account inventory: list / has / has-gpg-key / has-ssh-key (file-backed)
# ---------------------------------------------------------------------------

@test "list returns empty when no accounts registered" {
	run "$ACCOUNT_BIN" list
	[ "$status" -eq 0 ]
	[ -z "$output" ]
}

@test "list returns registered account names without .pub suffix" {
	touch "$SELF_CONFIG/ssh/alice@example.com.pub"
	touch "$SELF_CONFIG/ssh/bob@example.com.pub"
	run "$ACCOUNT_BIN" list
	[ "$status" -eq 0 ]
	[[ "$output" == *"alice@example.com"* ]]
	[[ "$output" == *"bob@example.com"* ]]
	[[ "$output" != *".pub"* ]]
}

@test "has returns 0 when both gpg and ssh keys exist" {
	touch "$SELF_CONFIG/ssh/alice@example.com.pub"
	touch "$SELF_CONFIG/gpg/alice@example.com.pub"
	run "$ACCOUNT_BIN" has alice@example.com
	[ "$status" -eq 0 ]
}

@test "has returns non-zero when ssh key missing" {
	touch "$SELF_CONFIG/gpg/alice@example.com.pub"
	run "$ACCOUNT_BIN" has alice@example.com
	[ "$status" -ne 0 ]
}

@test "has returns non-zero when gpg key missing" {
	touch "$SELF_CONFIG/ssh/alice@example.com.pub"
	run "$ACCOUNT_BIN" has alice@example.com
	[ "$status" -ne 0 ]
}

@test "has lowercases the account argument" {
	touch "$SELF_CONFIG/ssh/alice@example.com.pub"
	touch "$SELF_CONFIG/gpg/alice@example.com.pub"
	run "$ACCOUNT_BIN" has Alice@Example.COM
	[ "$status" -eq 0 ]
}

@test "has without account argument exits non-zero with fatal" {
	run "$ACCOUNT_BIN" has
	[ "$status" -eq 1 ]
	[[ "$output" == *"please specify an account"* ]]
}

@test "has-gpg-key returns 0 only when gpg key exists" {
	run "$ACCOUNT_BIN" has-gpg-key alice@example.com
	[ "$status" -ne 0 ]
	touch "$SELF_CONFIG/gpg/alice@example.com.pub"
	run "$ACCOUNT_BIN" has-gpg-key alice@example.com
	[ "$status" -eq 0 ]
}

@test "has-ssh-key returns 0 only when ssh key exists" {
	run "$ACCOUNT_BIN" has-ssh-key alice@example.com
	[ "$status" -ne 0 ]
	touch "$SELF_CONFIG/ssh/alice@example.com.pub"
	run "$ACCOUNT_BIN" has-ssh-key alice@example.com
	[ "$status" -eq 0 ]
}

@test "remove deletes both gpg and ssh key files" {
	touch "$SELF_CONFIG/ssh/alice@example.com.pub"
	touch "$SELF_CONFIG/gpg/alice@example.com.pub"
	run "$ACCOUNT_BIN" remove alice@example.com
	[ "$status" -eq 0 ]
	[ ! -f "$SELF_CONFIG/ssh/alice@example.com.pub" ]
	[ ! -f "$SELF_CONFIG/gpg/alice@example.com.pub" ]
}

@test "remove of unknown account is a no-op (idempotent)" {
	run "$ACCOUNT_BIN" remove never-registered@example.com
	[ "$status" -eq 0 ]
}

@test "remove accepts multiple accounts in one call" {
	touch "$SELF_CONFIG/ssh/alice@example.com.pub"
	touch "$SELF_CONFIG/gpg/alice@example.com.pub"
	touch "$SELF_CONFIG/ssh/bob@example.com.pub"
	touch "$SELF_CONFIG/gpg/bob@example.com.pub"
	run "$ACCOUNT_BIN" remove alice@example.com bob@example.com
	[ "$status" -eq 0 ]
	[ ! -f "$SELF_CONFIG/ssh/alice@example.com.pub" ]
	[ ! -f "$SELF_CONFIG/gpg/alice@example.com.pub" ]
	[ ! -f "$SELF_CONFIG/ssh/bob@example.com.pub" ]
	[ ! -f "$SELF_CONFIG/gpg/bob@example.com.pub" ]
}

# ---------------------------------------------------------------------------
# Cached key export (file-backed, no external gpg/ssh call)
# ---------------------------------------------------------------------------

@test "ssh-export-public-key <key> returns cached key file" {
	echo "ssh-rsa AAAA alice@example.com" \
		> "$SELF_CONFIG/ssh/alice@example.com.pub"
	run "$ACCOUNT_BIN" ssh-export-public-key alice@example.com
	[ "$status" -eq 0 ]
	[ "$output" = "ssh-rsa AAAA alice@example.com" ]
}

@test "gpg-export-public-key <key> returns cached key file" {
	cat > "$SELF_CONFIG/gpg/alice@example.com.pub" <<-EOF
		-----BEGIN PGP PUBLIC KEY BLOCK-----
		stub-payload
		-----END PGP PUBLIC KEY BLOCK-----
	EOF
	run "$ACCOUNT_BIN" gpg-export-public-key alice@example.com
	[ "$status" -eq 0 ]
	[[ "$output" == *"BEGIN PGP PUBLIC KEY BLOCK"* ]]
	[[ "$output" == *"stub-payload"* ]]
}

# ---------------------------------------------------------------------------
# Slaves / master / hosts
# ---------------------------------------------------------------------------

@test "master returns empty when authorized_keys missing" {
	run "$ACCOUNT_BIN" master
	[ "$status" -eq 0 ]
	[ -z "$output" ]
}

@test "master returns key-comment from authorized_keys" {
	mkdir -p "$HOME/.ssh"
	echo "ssh-rsa AAAA bob@example.com" > "$HOME/.ssh/authorized_keys"
	run "$ACCOUNT_BIN" master
	[ "$status" -eq 0 ]
	[[ "$output" == *"bob@example.com"* ]]
}

# `sed 's/.* //g'` strips everything up to the last space. When the
# key line has no comment, the entire line collapses to itself (no
# space to anchor on); pin that behaviour so a future change to the
# parsing logic surfaces here.
@test "master with no-comment key line preserves the whole line" {
	mkdir -p "$HOME/.ssh"
	echo "ssh-rsa-no-spaces-here" > "$HOME/.ssh/authorized_keys"
	run "$ACCOUNT_BIN" master
	[ "$status" -eq 0 ]
	[[ "$output" == *"ssh-rsa-no-spaces-here"* ]]
}

@test "slaves returns contents of identity's slaves file" {
	identity="$($ACCOUNT_BIN identity)"
	echo "alice@example.com" > "$SELF_CONFIG/slaves/$identity"
	echo "bob@example.com"  >> "$SELF_CONFIG/slaves/$identity"
	run "$ACCOUNT_BIN" slaves
	[ "$status" -eq 0 ]
	[[ "$output" == *"alice@example.com"* ]]
	[[ "$output" == *"bob@example.com"* ]]
}

@test "slaves <account> returns that account's slaves file" {
	echo "carol@example.com" > "$SELF_CONFIG/slaves/alice@example.com"
	run "$ACCOUNT_BIN" slaves alice@example.com
	[ "$status" -eq 0 ]
	[[ "$output" == *"carol@example.com"* ]]
}

@test "slaves <account> with no file returns empty success" {
	run "$ACCOUNT_BIN" slaves never@example.com
	[ "$status" -eq 0 ]
	[ -z "$output" ]
}

# FEAT-214: `command:slaves` does NOT lowercase its argument while
# `command:has` does. Pin the asymmetry so any future change is
# deliberate. Resolution chosen: document, don't fix — slaves
# filenames are opaque identifiers passed verbatim from
# `command:identity` (which already lowercases via `hostname -f |
# tr '[:upper:]' '[:lower:]'`). Callers should always pass
# lowercase.
@test "slaves is case-sensitive (unlike has, FEAT-214)" {
	echo "carol@example.com" > "$SELF_CONFIG/slaves/alice@example.com"
	run "$ACCOUNT_BIN" slaves Alice@example.com
	[ "$status" -eq 0 ]
	[ -z "$output" ]
}

@test "hosts derives unique hostnames from slaves" {
	identity="$($ACCOUNT_BIN identity)"
	cat > "$SELF_CONFIG/slaves/$identity" <<-EOF
		alice@example.com
		bob@example.com
		carol@other.example
	EOF
	run "$ACCOUNT_BIN" hosts
	[ "$status" -eq 0 ]
	[[ "$output" == *"example.com"* ]]
	[[ "$output" == *"other.example"* ]]
}

# ---------------------------------------------------------------------------
# ssh-export-known-host — no-arg, no-key fallback
# ---------------------------------------------------------------------------

# When /etc/ssh/ssh_host_rsa_key.pub doesn't exist, the no-arg form
# emits an empty line and exits 0. Pin the contract for callers
# that pipe the output downstream.
@test "ssh-export-known-host (no arg) returns empty when host key absent" {
	# We cannot easily mask /etc/ssh from bin/account. The test
	# asserts success + a defined output shape and only digs into
	# the populated branch when the .pub is actually readable
	# (macOS GitHub runners can have the file present but
	# restricted, or absent entirely).
	run "$ACCOUNT_BIN" ssh-export-known-host
	[ "$status" -eq 0 ]
	if [ -r /etc/ssh/ssh_host_rsa_key.pub ]; then
		[[ "$output" == *"$(hostname -f | tr '[:upper:]' '[:lower:]')"* ]]
	else
		# Empty or just `hostname ` (with trailing space if the
		# script reached `cat` but it produced nothing). Both are
		# acceptable contracts for callers piping the output.
		[ -z "$output" ] || [[ "$output" == "$(hostname -f | tr '[:upper:]' '[:lower:]')"* ]]
	fi
}

# ---------------------------------------------------------------------------
# Platform detection (local form — reads /etc/os-release or uname)
# ---------------------------------------------------------------------------

@test "platform (no arg) returns a non-empty identifier" {
	run "$ACCOUNT_BIN" platform
	[ "$status" -eq 0 ]
	[ -n "$output" ]
}

# BUG-005 regression guard: the fallback branch outputs `unknown`
# (correctly spelled) — caught by `lint (typos)` in CI, but pinned
# here for local runs too.
@test "platform output never contains the 'unkown' typo" {
	run "$ACCOUNT_BIN" platform
	[[ "$output" != *"unkown"* ]]
}

# ---------------------------------------------------------------------------
# admin / root — exit-status semantics
# ---------------------------------------------------------------------------

@test "admin returns non-zero for non-root user without sudoers entry" {
	if [ "$EUID" -eq 0 ] || [ -e "/etc/sudoers.d/$(whoami)" ]; then
		skip "admin would succeed in this environment; skip the negative case"
	fi
	run "$ACCOUNT_BIN" admin
	[ "$status" -ne 0 ]
}

@test "root returns 0 iff EUID==0" {
	run "$ACCOUNT_BIN" root
	if [ "$EUID" -eq 0 ]; then
		[ "$status" -eq 0 ]
	else
		[ "$status" -ne 0 ]
	fi
}

# ---------------------------------------------------------------------------
# Early-validation error paths (no external calls reached)
#
# FEAT-211: fatal exit codes follow two conventions in bin/account:
#   - `fatal "msg"`    → exit 1   (default in fatal helper)
#   - `fatal "msg" -1` → exit 255 (bash truncates -1 to 8-bit)
# Each test below asserts the exact expected status so any future
# normalisation (e.g. dropping the `-1` arg) surfaces here.
# ---------------------------------------------------------------------------

@test "create-user without name exits fatal" {
	run "$ACCOUNT_BIN" create-user
	[ "$status" -eq 255 ]   # fatal "msg" -1
	[[ "$output" == *"Please specify a user name"* ]]
}

@test "delete-user without name exits fatal" {
	run "$ACCOUNT_BIN" delete-user
	[ "$status" -eq 255 ]   # fatal "msg" -1
	[[ "$output" == *"Please specify a user name"* ]]
}

@test "add-user without name exits fatal" {
	run "$ACCOUNT_BIN" add-user
	[ "$status" -eq 255 ]   # fatal "msg" -1
	[[ "$output" == *"Please specify a user name"* ]]
}

@test "add-user with name but no group exits fatal" {
	run "$ACCOUNT_BIN" add-user alice
	[ "$status" -eq 255 ]   # fatal "msg" -1
	[[ "$output" == *"Please specify a group name"* ]]
}

@test "gpg-import-public-key without key id exits non-zero" {
	run "$ACCOUNT_BIN" gpg-import-public-key
	[ "$status" -eq 1 ]     # fatal "msg" (no -1)
	[[ "$output" == *"please specify a key id"* ]]
}

@test "gpg-delete-key without key id exits non-zero" {
	run "$ACCOUNT_BIN" gpg-delete-key
	[ "$status" -eq 1 ]     # fatal "msg" (no -1)
	[[ "$output" == *"please specify a key id"* ]]
}

@test "ssh-import-public-key without key id exits non-zero" {
	run "$ACCOUNT_BIN" ssh-import-public-key
	[ "$status" -eq 1 ]     # fatal "msg" (no -1)
	[[ "$output" == *"please specify a key id"* ]]
}

@test "insert without account exits fatal" {
	run "$ACCOUNT_BIN" insert
	[ "$status" -eq 255 ]   # fatal "msg" -1
	[[ "$output" == *"please specify an account"* ]]
}

@test "put without filename exits non-zero" {
	run "$ACCOUNT_BIN" put
	[ "$status" -eq 1 ]     # fatal "msg" (no -1)
	[[ "$output" == *"please specify a file"* ]]
}

@test "put with non-existent file exits non-zero" {
	run "$ACCOUNT_BIN" put /nonexistent/path/to/file alice@example.com
	[ "$status" -eq 1 ]     # fatal "msg" (no -1)
	[[ "$output" == *"does not exist"* ]]
}

@test "set without filename exits non-zero" {
	run "$ACCOUNT_BIN" set
	[ "$status" -eq 1 ]     # fatal "msg" (no -1)
	[[ "$output" == *"please specify"* ]]
}

@test "get without filename exits non-zero" {
	run "$ACCOUNT_BIN" get
	[ "$status" -eq 1 ]     # fatal "msg" (no -1)
	[[ "$output" == *"please specify"* ]]
}

# ---------------------------------------------------------------------------
# FEAT-210: import-key happy paths (registry-write to $SELF_CONFIG).
# Sandbox-safe; the gpg branch tolerates the post-write `gpg --import`
# failing on stub key material since the assertion is on the file write.
# ---------------------------------------------------------------------------

@test "ssh-import-public-key writes the piped key to SELF_CONFIG/ssh/" {
	mkdir -p "$HOME/.ssh"
	echo "ssh-rsa AAAA alice@example.com" \
		| "$ACCOUNT_BIN" ssh-import-public-key alice@example.com
	[ -f "$SELF_CONFIG/ssh/alice@example.com.pub" ]
	grep -q "ssh-rsa AAAA" "$SELF_CONFIG/ssh/alice@example.com.pub"
}

@test "ssh-import-public-key appends to authorized_keys" {
	mkdir -p "$HOME/.ssh"
	echo "ssh-rsa AAAA alice@example.com" \
		| "$ACCOUNT_BIN" ssh-import-public-key alice@example.com
	grep -q "ssh-rsa AAAA" "$HOME/.ssh/authorized_keys"
}

@test "gpg-import-public-key writes the piped key to SELF_CONFIG/gpg/" {
	# bin/account calls `gpg --import` and `gpg --quick-sign-key`
	# after the registry-file write. The write succeeds regardless,
	# but the gpg invocations require gpg(1) on PATH — skip cleanly
	# on hosts (macOS GitHub runners can omit gnupg) where it isn't
	# installed.
	command -v gpg >/dev/null 2>&1 || skip "gpg not installed"
	export GNUPGHOME="$(mktemp -d "$BATS_TMPDIR/gnupg.XXXXXX")"
	# gpg --import on the stub payload will fail, but the file
	# write happens before that call. `|| true` accepts the
	# downstream failure; we only assert the registry-write step.
	echo "-----BEGIN PGP PUBLIC KEY BLOCK-----" \
		| "$ACCOUNT_BIN" gpg-import-public-key alice@example.com \
		2>/dev/null || true
	[ -f "$SELF_CONFIG/gpg/alice@example.com.pub" ]
	grep -q "BEGIN PGP PUBLIC KEY BLOCK" \
		"$SELF_CONFIG/gpg/alice@example.com.pub"
	rm -rf "$GNUPGHOME"
}

# ---------------------------------------------------------------------------
# FEAT-213: global flags.
# The getopts loop in bin/account accepts -d (debug) and -q (quiet);
# both should be tolerated before any subcommand without changing
# the subcommand's stdout output.
# ---------------------------------------------------------------------------

@test "-q flag is accepted and version still prints" {
	run "$ACCOUNT_BIN" -q version
	[ "$status" -eq 0 ]
	[ -n "$output" ]
}

@test "-d flag is accepted and version still prints" {
	run "$ACCOUNT_BIN" -d version
	[ "$status" -eq 0 ]
	# version output is mixed with set -vx trace under -d; the
	# version string still appears somewhere in $output.
	[[ "$output" == *"$("$ACCOUNT_BIN" version)"* ]]
}
