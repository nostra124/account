#!/bin/sh
# Post a failed CI job's log tail to the PR as a comment, so an
# agent reviewing the PR can read the failure context via the
# GitHub API without needing workflow-log download access.
#
# Invoked from a GitHub Actions step under `if: failure()`. Args:
#   $1   path to the captured log file (tee'd from the test step)
#   $2   human-readable job label (e.g. "unit (macos)")
#
# Environment expected from the workflow:
#   GH_TOKEN              GitHub token with `pull-requests: write`
#   PR_NUMBER             PR number (caller passes via env)
#   GITHUB_SERVER_URL, GITHUB_REPOSITORY, GITHUB_RUN_ID, GITHUB_SHA
#
# Behaviour:
#   - Skips silently when not in a pull_request context (no PR_NUMBER).
#   - Tails the log to the last 200 lines so the comment fits.
#   - Includes a stable marker so multiple comments per run are
#     identifiable in the PR feed.
set -eu

LOG=${1:?missing log file path}
LABEL=${2:?missing job label}

if [ -z "${PR_NUMBER:-}" ]; then
	echo "ci-post-failure: not a pull_request event; skipping" >&2
	exit 0
fi

if [ ! -f "$LOG" ]; then
	echo "ci-post-failure: log file '$LOG' missing; posting placeholder" >&2
	{
		printf '<!-- ci-failure: %s -->\n' "$LABEL"
		printf '## CI failure: `%s`\n\n' "$LABEL"
		printf 'No log file was captured. See the workflow run:\n'
		printf '%s/%s/actions/runs/%s\n' \
			"$GITHUB_SERVER_URL" "$GITHUB_REPOSITORY" "$GITHUB_RUN_ID"
	} | gh pr comment "$PR_NUMBER" --body-file -
	exit 0
fi

JOB_URL="${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}"
SHA_SHORT=$(printf '%s' "${GITHUB_SHA:-unknown}" | cut -c1-7)

{
	printf '<!-- ci-failure: %s -->\n' "$LABEL"
	printf '## CI failure: `%s`\n\n' "$LABEL"
	printf '[Workflow run](%s) — commit `%s`\n\n' "$JOB_URL" "$SHA_SHORT"
	printf '<details><summary>Last 200 lines of test output</summary>\n\n'
	printf '\n```\n'
	tail -200 "$LOG"
	printf '\n```\n\n'
	printf '</details>\n'
} | gh pr comment "$PR_NUMBER" --body-file -
