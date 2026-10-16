---
description: Start or resume an implementation session from a ready spec - branch, TDD chunks, review gate, and one commit per chunk.
argument-hint: "<specs/slug.md | #issue | bug description>"
disable-model-invocation: true
allowed-tools: Read, Grep, Glob, Edit, Skill(specify), Skill(review), Agent(orchestrator), Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git add:*), Bash(git commit:*), Bash(git switch:*), Bash(git rev-parse:*), Bash(git symbolic-ref:*), Bash(gh issue view:*), Bash(*/scripts/ledger.sh:*), Bash(*/scripts/review-diff.sh:*), Bash(task:*)
---

Start or resume an implementation session. Input: $ARGUMENTS

You own the session loop: chunk, review gate, commit, repeat. The `orchestrator` owns
context assembly and the TDD phase agents. Do not invoke `tdd-red`, `tdd-green`, or
`tdd-refactor` directly, and never commit work the gate has not passed.

The scripts live in the review skill's directory: `~/.claude/skills/review/scripts/`.
`ledger.sh` is the session's memory. Record each step in it as it happens, never from
memory afterwards, so a `/clear` or a new conversation loses nothing.

## 1. Resolve the spec

- **A spec path**: read it. If `Status: draft`, stop and tell the user to finish it with
  `/specify`. If `Status: done`, stop and say so.
- **An issue number or bug description with no spec**: invoke the `specify` skill in
  bugfix mode, then continue with the spec it writes.
- **A feature idea with no spec**: stop and tell the user to run `/specify` first.
- **No argument**: run `ledger.sh find`. If it finds a slug, resume that session (step 3).
  Otherwise ask for a spec path.

The slug is the spec's filename without `.md`.

## 2. Prepare the branch

Skip this step when `ledger.sh show <slug> branch` already has a line; that is a resume.

1. If `git status --short` shows changes outside the spec and its feature file, stop and
   ask the user what to do with them. Never sweep unrelated work into a session commit.
2. If you are on the default branch (`git symbolic-ref --short refs/remotes/origin/HEAD`)
   and the repository's `AGENTS.md` or `CLAUDE.md` does not say it works trunk-based,
   create `feat/<slug>` (or `fix/<slug>` for `Type: bugfix`) with `git switch -c`.
3. If the spec or its feature file is untracked or modified, commit them alone as
   `docs(spec): add <slug> specification`. The human already gated them in `/specify`,
   so this commit does not go through `/review`.
4. Record `spec <path>`, `branch <name>`, and `issue #<n>` (if the spec names one).

## 3. Run a chunk

Delegate to the `orchestrator` subagent. Pass it only:

- The spec path and the feature file path. It reads §3 (or §3 Constraints for a bugfix) as
  the feature description and the scenarios plus §5 as the plan
- The scenarios already done: `ledger.sh show <slug> chunk`
- The last chunk line, as the prior session summary

If the orchestrator returns `questions`, present them to the user as one batch, each with
its recommended default and any feasibility risk it found, so the user answers once
instead of once per surprise. Show its `assumptions` in the same message. If it returns
no questions, don't stop for a confirmation: show the assumptions in one line each and
let it run. Users answered "accept defaults" to nearly every confirmation, so a question
that has a safe default costs a round trip for nothing. After the user answers, or straight
away when there were no questions, tell the orchestrator that the scope is confirmed.

It returns a checkpoint after at most three TDD cycles. Verify it yourself:
`git status --short`, and the test command it names, judged by exit code. If a checkpoint
arrives while a phase agent is still running (its `done` is empty, or the files it lists
are not in `git status --short`), wait for that agent's completion notification before
you verify or re-dispatch anything. If a run ends with a plan instead of finished work,
resend the confirmation and tell it to dispatch `tdd-red` now; do not re-explain the scope.

Record the verified checkpoint as one `chunk` line: the scenarios done and the test count.

If the checkpoint is `blocked` because a test, build, or pipeline stage is red for a reason
outside this chunk, invoke `/fix` and resume after it returns.

## 4. Gate and commit the chunk

Every chunk with `done` work is reviewed and committed on its own. Small commits keep the
review diff small and every step reversible.

1. If the orchestrator returned `complete`, set the spec's `Status:` line to `done` and stage
   the spec, so the status change lands with the last chunk.
2. Invoke the `review` skill. It reads the spec and the ledger for its context and records
   each round. Route its fix rounds through the orchestrator as it says.
3. When it passes, run `review-diff.sh --check-pass`. If it fails, the index changed after
   the review: run the review again.
4. Commit with a Conventional Commit message (`feat:` or `fix:`) that names the scenarios in
   this chunk. If the spec names an issue, add `Refs #<n>` to the body, or `Fixes #<n>` on
   the chunk that completes the spec. End with the attribution trailer exactly as the system
   prompt gives it, and never add a model suffix such as "(1M context)". Pre-commit hooks
   re-run on every amend, so get the message right the first time.
5. Record `commit <short sha> <subject>`.

If the orchestrator returned `checkpoint`, go back to step 3 for the next chunk.

## 5. Close the session

When the last chunk is committed, write the session summary once, as one `summary` line
under 150 words: the files created, the tests added and which scenario each covers, and
the test count. Then tell the user, in two lines: the next step is `/end-session` to push
and open the pull request, and `/clear` is safe because the ledger holds the state.

## Resuming

To resume after `/clear` or in a new conversation, run `/start-session` again with the same
spec path, or with no argument on the session's branch. The ledger and `git log` are the
whole state; agent IDs from an earlier conversation do not survive, so never try to resume
an orchestrator or phase agent by ID. Staged and unstaged work survives in the working tree;
work that never reached disk is lost, so check `git status --short` first.
