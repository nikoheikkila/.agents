#!/usr/bin/env bash
# Session ledger for the agentic-CD loop: one append-only log per spec slug.
#
#   ledger.sh add <slug> <kind> <text...>   append one line
#   ledger.sh show <slug> [kind]            print the log, or only the lines of one kind
#   ledger.sh find                          print the slug of the newest log for the current branch
#
# Kinds: spec, issue, branch, chunk, review, risk, defer, commit, push, summary.
#
# The log lives in $(git rev-parse --git-dir)/agentic, so it survives /clear and a new
# conversation but never shows up in git status, a review diff, or a commit. Each worktree
# has its own git dir, so parallel sessions do not share a ledger.
set -euo pipefail

usage() {
	echo "usage: ledger.sh add <slug> <kind> <text...> | show <slug> [kind] | find" >&2
	exit 2
}

dir="$(git rev-parse --absolute-git-dir)/agentic"
mkdir -p "$dir"

check_slug() {
	case "$1" in
	'' | *[!A-Za-z0-9._-]*) echo "invalid slug: $1" >&2 && exit 2 ;;
	esac
}

cmd=${1:-}
[ $# -gt 0 ] && shift

case "$cmd" in
add)
	[ $# -ge 3 ] || usage
	check_slug "$1"
	slug=$1 kind=$2
	shift 2
	text=$*
	printf '%s [%s] %s\n' "$(date -u +%Y-%m-%dT%H:%MZ)" "$kind" "${text//$'\n'/ }" >>"$dir/$slug.log"
	;;
show)
	[ $# -ge 1 ] || usage
	check_slug "$1"
	log="$dir/$1.log"
	[ -f "$log" ] || { echo "no ledger for $1" >&2 && exit 1; }
	if [ -n "${2:-}" ]; then
		grep -F "[$2] " "$log" || true
	else
		cat "$log"
	fi
	;;
find)
	branch=$(git rev-parse --abbrev-ref HEAD)
	newest=""
	for log in "$dir"/*.log; do
		[ -f "$log" ] || continue
		cut -d" " -f2- "$log" | grep -qxF "[branch] $branch" || continue
		if [ -z "$newest" ] || [ "$log" -nt "$newest" ]; then
			newest=$log
		fi
	done
	[ -n "$newest" ] || { echo "no ledger for branch $branch" >&2 && exit 1; }
	basename "$newest" .log
	;;
*) usage ;;
esac
