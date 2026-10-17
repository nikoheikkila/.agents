---
description: Close out an implementation session - verify every gate, push, open the pull request, watch the pipeline, and point at the next slice.
argument-hint: "[specs/slug.md]"
disable-model-invocation: true
allowed-tools: Read, Grep, Glob, Skill(fix), Skill(mutation-testing), Bash(git status:*), Bash(git log:*), Bash(git push:*), Bash(git rev-parse:*), Bash(git symbolic-ref:*), Bash(gh run list:*), Bash(gh run watch:*), Bash(gh pr view:*), Bash(gh pr create:*), Bash(*/scripts/ledger.sh:*)
---

Complete the session. Spec: $ARGUMENTS (when empty, use `ledger.sh find`). The scripts are
in `~/.claude/skills/review/scripts/`. `/start-session` already reviewed and committed every
chunk, so this command commits nothing.

1. **Everything is committed.** `git status --short` must show nothing staged or modified
   outside ignored files. If it does, stop: the work belongs in a `/start-session` chunk,
   where the gate reviews it.
2. **The session is finished.** The spec's `Status:` is `done` and the ledger has a
   `summary` line. If not, stop, and say `/start-session` has scenarios left.
3. **The base is green.** Run
   `gh run list --branch <default branch> -L 1 --json conclusion,status,headSha`. If the
   latest run on the default branch failed, stop: that is not this branch's fault, but
   pushing on top of it hides whether this branch is green. Offer `/fix` on the default
   branch first.
4. **Mutation testing, features only.** For `Type: feature`, if the project already has
   Stryker configured, invoke the `mutation-testing` skill for a diff-scoped run against
   the default branch. List the surviving mutants and ask the user once whether to
   strengthen the tests now (a new `/start-session` chunk) or record them for the pull
   request. Skip this step for a bugfix, or when Stryker is not set up. Never set it up here.
5. **Push.** `git push -u origin HEAD`, and record a `push` line.
6. **Pull request.** On a branch other than the default one, and when `gh pr view` finds
   none, run `gh pr create`. Use the spec's slice name as the title, in Conventional Commit
   form. The body has:
   - the intent, in two or three lines from spec §1
   - the scenarios delivered, one per line
   - **Deferred**: every `defer` line from the ledger
   - **Accepted risks**: every `risk` line from the ledger
   - **Validate after deploy**: the hypothesis metric, data source, and time window from
     spec §1 (omit for a bugfix)
   - `Fixes #<n>` when the spec names an issue
   - the pull request attribution line exactly as the system prompt gives it
     On the default branch (trunk-based), skip this step.
7. **Watch.** Find the run for `git rev-parse HEAD` with `gh run list`, then run
   `gh run watch <id> --exit-status`. If it fails, invoke `/fix` with the run id.
8. **Point at what comes next.** Print the pull request URL, then the first entry under the
   spec's _Later slices_ as the suggested `/specify` input, or say there are none. Suggest
   `/clear`: the commits, the pull request, and the ledger carry everything forward.
