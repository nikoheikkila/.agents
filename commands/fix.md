---
description: Enter pipeline-restore mode and repair a red pipeline with minimum context. Use when the remote CI pipeline fails after a push, when /end-session reports a red run, or when a test, build, or pipeline stage fails mid-session for a reason outside the current chunk and must go green before new work.
argument-hint: "[run URL | run id | failing command | failing test]"
allowed-tools: Read, Grep, Glob, Skill(review), Agent(orchestrator), Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git add:*), Bash(git commit:*), Bash(git push:*), Bash(git rev-parse:*), Bash(git remote get-url:*), Bash(gh run list:*), Bash(gh run view:*), Bash(gh run watch:*), Bash(gh run rerun:*), Bash(*/scripts/ledger.sh:*), Bash(*/scripts/review-diff.sh:*)
---

Enter pipeline-restore mode. Load minimum context only. Failure to restore: $ARGUMENTS

You own the restore loop. The `orchestrator` owns routing the fix to a phase agent; do not
invoke `tdd-green` or `general-purpose` directly. The scripts are in
`~/.claude/skills/review/scripts/`. If `ledger.sh find` names a session, record each step
in it.

1. **Identify the failure.** Resolve the run from the argument:
   - **A workflow run URL** (`https://github.com/<owner>/<repo>/actions/runs/<run id>`,
     optionally followed by `/job/<job id>` or `/attempts/<n>`): take the run id, and the
     job id when present. If `<owner>/<repo>` is not this repository's `origin`
     (`git remote get-url origin`), stop and say so; a fix belongs in the repository
     whose pipeline failed. If the run's head branch (`gh run view <id> --json headBranch`)
     is not the current branch, stop and ask whether to switch to it
   - **A run id**: use it as given
   - **Nothing**: find the latest failed run with
     `gh run list --branch <current branch> -L 5`

   Save the failed steps' log to a file instead of reading it whole:
   `gh run view <id> --log-failed > "${TMPDIR:-/tmp}/fix-<id>.log"`, or with
   `--job <job id>` in place of `<id>` when the URL named a job. Read the last 80 lines and
   grep for the first error. For a local failure, rerun the named command the same way.
   Name the stage, the failing command, and the first error line.
2. **Classify it** as exactly one of:
   - `test`: a failing assertion
   - `build`: a compile, type, or bundling error in the code
   - `lint`: a formatting or lint rule
   - `config`: a workflow file, a build or dependency manifest, or an environment variable
     the pipeline itself sets
   - `environment`: a missing secret or permission, a runner, network, or quota problem,
     or an external service
   - `flaky`: the same commit passed before, or the error is a timeout with no code change
3. **`environment` and `flaky` don't go to an agent.** For `flaky`, rerun the failed jobs
   once with `gh run rerun <id> --failed` and `gh run watch <id> --exit-status`. If it
   passes, record the flake as a `defer` line so it reaches the pull request, and stop. For `environment`, or a flake
   that fails again, stop and ask the user one question with a recommended default. No
   code change fixes a missing secret.
4. **Delegate the rest** to the `orchestrator` in pipeline-restore mode, passing only the
   class, the failing command, at most 20 lines of the error, and the files the error
   names. Verify its checkpoint with `git status --short` and the failing command.
5. **Mid-session, before any push**: if the failure is local and the current chunk has
   staged work that is not committed yet, stop here and return to `/start-session`. That
   chunk's gate reviews the fix together with the chunk.
6. **Review and commit.** Invoke the `review` skill on the fix alone, not on the restore
   session history. When it passes and `review-diff.sh --check-pass` matches, commit as
   `fix(ci): <what was broken>` with the attribution trailer exactly as the system prompt
   gives it. Record the `commit` line.
7. **Push and watch.** `git push`, then find the new run for `git rev-parse HEAD` and
   `gh run watch <id> --exit-status`. Record a `push` line with the result.
8. **Stop after two attempts.** If the second fix still leaves the pipeline red, stop and
   report to the user what you tried and the current error. Do not loop again.

When the pipeline is green, exit restore mode and say which command resumes the flow:
`/start-session` if the spec still has scenarios left, otherwise `/end-session`.
