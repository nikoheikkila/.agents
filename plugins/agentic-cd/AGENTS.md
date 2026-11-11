# Agentic Continuous Delivery Plugin

One plugin holds the whole workflow: custom subagents, the commands `start-session`, `end-session`, `fix`, and
`reflect`, and the skills `specify`, `review`, `gherkin`, `mutation-testing` (called by `/end-session`), `tdd-red`,
`tdd-green`, and `tdd-refactor`.

Plugin components are namespaced, so reference them as `agentic-cd:<name>` wherever a mechanism needs an exact name:
`Agent(agentic-cd:orchestrator)` allowlists, `skills:`
frontmatter (`agentic-cd:tdd-red`), and `Skill(agentic-cd:review)` in `allowed-tools`. A bare name fails there. The
commands reach the scripts as `${CLAUDE_PLUGIN_ROOT}/skills/review/scripts/`, not through `~/.claude/skills`.
Edits are live only after push + marketplace update.

Seven subagents, shipped as plugin agents, adapted from the
[MinimumCD agentic-CD guide](https://beyond.minimumcd.org/docs/agentic-cd/architecture/agent-configuration/):
`orchestrator` runs the ATDD loop for a spec's one scenario and spawns `software-engineer` once per step: step `A`
writes the failing acceptance test under its strict marker, and each cycle is one Red-Green-Refactor round with its
own unit test.

The review gate is separate: `/review` invokes `review-orchestrator`, which fans out to `semantic-review`,
`security-review`, `performance-review`, and `concurrency-review`. The orchestrator never spawns the review
orchestrator and never commits. It returns a gate-ready checkpoint per chunk, and `/start-session` runs `/review`
and commits that chunk.

## The Review Gate

- **`block` needs a `failure_scenario`.** Every finding carries `severity: blocking | advisory`, and only a
  finding that names a concrete input or state and the wrong outcome in the code as written is `blocking`.
  `review-orchestrator` sets `decision` itself from the severities and ignores the `decision` an agent returned.
  Advisory findings never block. On a pass, the cheap in-scope ones (stale docs, dead code, a missing test for
  stated behaviour) get one fix round and a delta review before the commit. The rest go into the pull request
  description.
- **Rounds are full, then delta, at most three.** The skill's `scripts/review-diff.sh` writes the diff to a file (lockfiles
  excluded, because an 80 KB diff does not fit in a prompt) and records the index tree and HEAD; `--delta` produces
  only what the fixes changed, and falls back to a full diff once HEAD has moved. On a pass, `--mark-pass` records
  the passed tree, and the committer runs `--check-pass` so nothing staged after the review gets committed. Delta rounds check that each previous blocker closed and that the delta added nothing
  new. Round 3 still blocking goes to the user, not to a fourth round. A `review-orchestrator` that reports the
  review is not complete is resumed, never replaced: a second `--delta` on an unchanged index writes an empty diff.
- **The caller triages before routing.** Verify each blocking finding against the code or the platform docs, drop
  the ones whose scenario does not hold, and batch the ones that need a product decision into one question. The
  accepted-risk list travels with every round so a settled concern is not raised again.
- **Move the real-environment facts left.** The acceptance test crosses the real CI, service, or runtime boundary
  wherever the test setup allows, and the cycle plan puts the cycle that meets that boundary early. The orchestrator
  runs the production build and end-to-end command before it hands off to the gate.
- **An orchestrator run is a chunk, not a session.** At most three steps (the acceptance test or a TDD cycle) or one fix round per run, ending in
  a JSON checkpoint with `git_status` and `not_done`. The caller checks each claim in the checkpoint against the
  files, so a claim like "fixed" is only as good as the evidence attached to it. Each chunk is reviewed and committed
  on its own, and the caller then stops that chunk's orchestrators, so the next chunk starts a new one. The user's
  answers to an orchestrator's questions go into the ledger as `answer` lines and go into every resume message and
  every later chunk.

## The Session Loop

`/specify` (`/agentic-cd:specify`) writes `specs/<slug>.md` (`Type: feature | bugfix`, with a short bugfix mode) and the feature file.
A spec holds exactly one scenario, which becomes the ATDD acceptance test. A feature spec ends in a §5 TDD cycle
plan of at most six unit-level cycles, the last of which makes the acceptance test pass. Each step's `Tests` line
lists the affected tests, built with `grep`, and the orchestrator passes it to `software-engineer`.

A bugfix has no cycles, and
Green works directly against the regression test. The acceptance test is committed under a strict expected-to-fail
marker (`xfail(strict=True)`, `test.fails`), so every chunk lands green, and the marker trips when the behaviour is
done. `/start-session <spec>` commits the spec and works on the current branch (on the default branch it stays
trunk-based and creates none), then runs the steps (`A`, then cycles `1..n`) at most three per chunk (chunk → `/review` → commit), refuses a spec with
more than one scenario or no cycle plan, and sets the spec to `Status: done` when the acceptance test passes.

`/end-session` commits
nothing: it pushes, optionally opens the pull request from the ledger, and watches the run. `/fix` classifies a red run
(`test`, `build`, `lint`, `config`, `environment`, `flaky`), routes the first four through the orchestrator, and
reviews, commits, pushes, and watches the fix, at most twice.

Session state lives in `plugins/agentic-cd/skills/review/scripts/ledger.sh`: an append-only log per slug in
`$(git rev-parse --git-dir)/agentic/`, so it survives `/clear` without touching the working tree. The commands
reach both scripts as `${CLAUDE_PLUGIN_ROOT}/skills/review/scripts/`, so they work from the installed plugin cache
with no symlink.

## Permissions

A command's or skill's `allowed-tools` covers only the turn that invoked it. When the caller ends its turn while
a background subagent runs and a completion notification resumes it, or the user answers a question, the scripts
and `Skill(agentic-cd:review)` prompt again. For unattended sessions, allow them in settings:
`Bash(*/scripts/ledger.sh *)`, `Bash(*/scripts/review-diff.sh*)`, `Skill(agentic-cd:review)`.

Never write a leading-wildcard rule with the legacy `:*` suffix (`Bash(*/scripts/ledger.sh:*)`): it matches
nothing. Use a space (`ledger.sh *`), or no space when the script also runs bare (`review-diff.sh*`). The `auto`
permission mode hides a dead rule, so test one under `--permission-mode acceptEdits`.
