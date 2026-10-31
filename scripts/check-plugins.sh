#!/usr/bin/env bash
# Validate every plugin under plugins/ against both clients that install it:
# Claude Code (`claude plugin validate`) and Copilot CLI (skill loader errors).
set -euo pipefail

cd "$(dirname "$0")/.."
status=0

claude plugin validate . >/dev/null || { echo "✘ marketplace: claude plugin validate failed"; status=1; }

for dir in plugins/*/; do
  dir=${dir%/}
  if ! out=$(claude plugin validate "$dir" 2>&1); then
    echo "✘ $dir: claude plugin validate failed"; echo "$out" | tail -20; status=1
  fi
  out=$(copilot --plugin-dir "$dir" skill list 2>&1)
  if grep -q 'failed to load' <<<"$out"; then
    echo "✘ $dir: Copilot failed to load skills"; sed -n '/failed to load/,$p' <<<"$out"; status=1
  fi
  [ "$status" -eq 0 ] && echo "✔ $dir"
done

exit "$status"
