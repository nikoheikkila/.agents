#!/usr/bin/env bash
# Prepare the diff for one pass of the pre-commit review gate, and record its verdict.
#
#   review-diff.sh               full staged diff (first pass)
#   review-diff.sh --delta       only what changed in the index since the previous pass
#   review-diff.sh --mark-pass   record the current index tree as the one the gate passed
#   review-diff.sh --check-pass  exit 0 only if the index is exactly the tree the gate passed
#
# The diff goes to a file, never to stdout: a feature-sized diff is too big to paste into a
# subagent prompt, and reviewers can Read a path. Lockfiles are left out because they are
# machine-written and only add noise; their names still show up in the stat.
#
# Output: three lines on stdout (mode, diff path, line count); the stat summary goes to stderr.
# State lives in $(git rev-parse --git-dir)/review so it never reaches the working tree.
set -euo pipefail

usage() {
	echo "usage: review-diff.sh [--delta | --mark-pass | --check-pass]" >&2
	exit 2
}

case "${1:-}" in
"") mode="full" ;;
--delta) mode="delta" ;;
--mark-pass) mode="mark-pass" ;;
--check-pass) mode="check-pass" ;;
*) usage ;;
esac

gitdir=$(git rev-parse --absolute-git-dir)
state="$gitdir/review"
mkdir -p "$state"

if git diff --cached --quiet; then
	echo "nothing staged" >&2
	exit 1
fi

tree=$(git write-tree)
head=$(git rev-parse --verify --quiet HEAD || echo none)

case "$mode" in
mark-pass)
	echo "$tree" >"$state/passed-tree"
	echo "passed=$tree"
	exit 0
	;;
check-pass)
	if [ -f "$state/passed-tree" ] && [ "$(cat "$state/passed-tree")" = "$tree" ]; then
		echo "pass matches the index"
		exit 0
	fi
	echo "the index differs from the tree the gate passed; run the review again" >&2
	exit 1
	;;
esac

if ! git diff --quiet; then
	echo "warning: unstaged changes exist; the review only sees what is staged" >&2
fi

# A new round invalidates any earlier pass.
rm -f "$state/passed-tree"

excludes=(
	':!*.lock' ':!*.lockb' ':!bun.lock' ':!package-lock.json' ':!pnpm-lock.yaml' ':!yarn.lock'
	':!Cargo.lock' ':!go.sum' ':!poetry.lock' ':!uv.lock'
)

# A delta is only meaningful against a pass on the same HEAD; after a commit, start over.
if [ "$mode" = "delta" ] && ! { [ -f "$state/last-tree" ] && [ "$(cat "$state/last-head" 2>/dev/null)" = "$head" ]; }; then
	echo "no previous pass on this HEAD; falling back to the full diff" >&2
	mode="full"
fi

# Worktrees of the same repo can share a basename, so the git dir disambiguates the path.
id=$(printf '%s' "$gitdir" | git hash-object --stdin | cut -c1-8)
out="${TMPDIR:-/tmp}/review-$(basename "$(git rev-parse --show-toplevel)")-$id-$mode.diff"

if [ "$mode" = "delta" ]; then
	last=$(cat "$state/last-tree")
	git diff-tree -p --no-commit-id "$last" "$tree" -- . "${excludes[@]}" >"$out"
	git diff-tree --stat --no-commit-id "$last" "$tree" >&2
else
	git diff --cached -- . "${excludes[@]}" >"$out"
	git diff --cached --stat >&2
fi

echo "$tree" >"$state/last-tree"
echo "$head" >"$state/last-head"

echo "mode=$mode"
echo "path=$out"
echo "lines=$(wc -l <"$out" | tr -d ' ')"
