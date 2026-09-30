#!/usr/bin/env bash
# Prepare the diff for one pass of the pre-commit review gate.
#
#   review-diff.sh            full staged diff (first pass)
#   review-diff.sh --delta    only what changed in the index since the previous pass
#
# The diff goes to a file, never to stdout: a feature-sized diff is too big to paste into a
# subagent prompt, and reviewers can Read a path. Lockfiles are left out because they are
# machine-written and only add noise; their names still show up in the stat.
#
# Output: three lines on stdout (mode, diff path, line count); the stat summary goes to stderr.
# State lives in $(git rev-parse --git-dir)/review so it never reaches the working tree.
set -euo pipefail

mode=full
if [ "${1:-}" = "--delta" ]; then
	mode=delta
elif [ -n "${1:-}" ]; then
	echo "usage: review-diff.sh [--delta]" >&2
	exit 2
fi

git rev-parse --git-dir >/dev/null

if git diff --cached --quiet; then
	echo "nothing staged" >&2
	exit 1
fi

if ! git diff --quiet; then
	echo "warning: unstaged changes exist; the review only sees what is staged" >&2
fi

state="$(git rev-parse --git-dir)/review"
mkdir -p "$state"

tree=$(git write-tree)
out="${TMPDIR:-/tmp}/review-$(basename "$(git rev-parse --show-toplevel)")-$mode.diff"

excludes=(
	':!*.lock' ':!*.lockb' ':!bun.lock' ':!package-lock.json' ':!pnpm-lock.yaml' ':!yarn.lock'
	':!Cargo.lock' ':!go.sum' ':!poetry.lock' ':!uv.lock'
)

if [ "$mode" = "delta" ] && [ -f "$state/last-tree" ]; then
	last=$(cat "$state/last-tree")
	git diff-tree -p --no-commit-id "$last" "$tree" -- . "${excludes[@]}" >"$out"
	git diff-tree --stat --no-commit-id "$last" "$tree" >&2
else
	if [ "$mode" = "delta" ]; then
		echo "no previous pass recorded; falling back to the full diff" >&2
		mode=full
	fi
	git diff --cached -- . "${excludes[@]}" >"$out"
	git diff --cached --stat >&2
fi

echo "$tree" >"$state/last-tree"

echo "mode=$mode"
echo "path=$out"
echo "lines=$(wc -l <"$out" | tr -d ' ')"
