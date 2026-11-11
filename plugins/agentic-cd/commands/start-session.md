---
description: Start or resume an implementation session from a ready spec - branch, TDD chunks, review gate, and one commit per chunk.
argument-hint: "<specs/slug.md | #issue | bug description>"
disable-model-invocation: true
allowed-tools: Read, Grep, Glob, Edit, Skill(agentic-cd:specify), Skill(agentic-cd:review), Agent(agentic-cd:orchestrator), SendMessage, TaskStop, Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git add:*), Bash(git commit:*), Bash(git switch:*), Bash(git rev-parse:*), Bash(git symbolic-ref:*), Bash(gh issue view:*), Bash(*/scripts/ledger.sh *), Bash(*/scripts/review-diff.sh*), Bash(task:*)
---

Start or resume an implementation session. Input: $ARGUMENTS

You own the session loop: chunk, review gate, commit, repeat. The `orchestrator` owns
context assembly and routes each step to `software-engineer`. Do not invoke `software-engineer` directly,
and never commit work the gate has not passed.

The scripts live in the review skill's directory: `${CLAUDE_PLUGIN_ROOT}/skills/review/scripts/` (if that variable is not expanded, `../skills/review/scripts/` relative to this file).
`ledger.sh` is the session's memory. Record each step in it as it happens, never from
memory afterwards, so a `/clear` or a new conversation loses nothing.

## 1. Resolve the Spec

- **A spec path**: read it. If `Status: draft`, stop and tell the user to finish it with
  `/specify`. If `Status: done`, stop and say so. If the feature file holds more than one
  scenario, or a `Type: feature` spec has no `## 5. TDD Cycle Plan`, stop and tell the
  user to run `/specify` on the spec to re-slice it. Never pick the scenario or invent
  the cycles yourself: the human approves both in the spec.
- **An issue number or bug description with no spec**: invoke the `specify` skill in
  bugfix mode, then continue with the spec it writes.
- **A feature idea with no spec**: stop and tell the user to run `/specify` first.
- **No argument**: run `ledger.sh find`. If it finds a slug, resume that session (step 3).
  Otherwise ask for a spec path.

The slug is the spec's filename without `.md`. The plan's steps are `A`, the acceptance
test for the one scenario, and then the `### Cycle <n>` headings under §5, in order. A
bugfix spec, or a plan whose cycles are "None", has only `A`, and Green works directly
against it.

## 2. Prepare the Branch

Skip this step when `ledger.sh show <slug> branch` already has a line; that is a resume.

1. If `git status --short` shows changes outside the spec and its feature file, stop and
   ask the user what to do with them. Never sweep unrelated work into a session commit.
2. If you are on the default branch (`git symbolic-ref --short refs/remotes/origin/HEAD`),
   keep working there. Do not switch to a new branch.
3. If the spec or its feature file is untracked or modified, commit them alone as
   `docs(spec): add <slug> specification`. The human already gated them in `/specify`,
   so this commit does not go through `/review`.
4. Record `spec <path>`, `branch <name>`, and `issue #<n>` (if the spec names one).

## 3. Run the Next Chunk

A chunk is the next one to three steps, in plan order, that no line in
`ledger.sh show <slug> chunk` lists as done. Delegate that chunk to a new `orchestrator`
subagent. Pass it only:

- The spec path and the feature file path. It reads §3 (or §3 Constraints for a bugfix) as
  the feature description
- The chunk as the whole plan for this run: the step ids, the §5 entry for each step,
  whether the plan has cycles, and whether the chunk ends with the plan's last cycle. Tell
  it not to start any step outside the chunk
- The acceptance test's path and run command, from `ledger.sh show <slug> acceptance`,
  once step `A` is done
- Every line of `ledger.sh show <slug> answer`, as answers it applies and does not ask
  again
- The last chunk line, as the prior session summary

If the orchestrator returns `questions`, present them to the user as one batch, each with
its recommended default and any feasibility risk it found, so the user answers once
instead of once per surprise. Show its `assumptions` in the same message. If it returns
no questions, don't stop for a confirmation: show the assumptions in one line each and
let it run. Users answered "accept defaults" to nearly every confirmation, so a question
that has a safe default costs a round trip for nothing.

Then resume the same orchestrator (`SendMessage` to its agent ID); it already holds the
chunk's context. When the user has answered, record each answer as one `answer` line,
`<question> → <answer>`, and put every answer in the resume message verbatim, after its
question, followed by the scope confirmation. A resume that says only "confirmed" leaves
the orchestrator on its own defaults, and the user's answers are lost. When there were no
questions, send the confirmation alone.

It returns a checkpoint after at most three steps. If the checkpoint arrives while a phase
agent is still running (its `done` is empty, or the files it lists are not in
`git status --short`), wait for that agent's completion notification before you verify or
re-dispatch anything. If a run ends with a plan instead of finished work, resume it with
the same answers and the confirmation, and tell it to dispatch `software-engineer` now; do not
re-explain the scope.

Check the report against the files before you record anything. A checkpoint is a claim,
and only the working tree confirms it:

- `git_status` matches your own `git status --short`, path for path
- every test that `done` claims exists in the file it names: grep the file for the test's
  name
- `acceptance.test` exists, and its expected-to-fail marker is in the file for a
  `checkpoint` and gone from it for `complete`: grep for the marker
- the test command passes, judged by its exit code, and the test count it prints matches
  the count in `done`
- for `complete`, the acceptance test's `run` command passes as well

When a check fails, resume the orchestrator with the failed checks, one line each, and
check its next report the same way. Do not fix the files yourself.

Record the verified checkpoint as one `chunk` line that lists only the steps in `done`:
`<steps> of <last step>: <cycle titles>; <test count> tests`, for example
`A,1,2 of 4: …`. Steps the chunk did not finish are simply left out, and the next chunk
picks them up. When the checkpoint first reports the acceptance test, also record
`acceptance <path> <run command>`. If it reports cycles left as not needed, because the
acceptance test passed early, list them in the `chunk` line as `skipped` and tell the
user in one line.

If the checkpoint is `blocked` because a test, build, or pipeline stage is red for a reason
outside this chunk, invoke `/fix` and resume after it returns. If it is `blocked` because
the acceptance test still fails after the last planned cycle, stop and show the user its
failure line. The cycle plan needs another cycle, and `/specify` adds it.

## 4. Gate and Commit the Chunk

Every chunk with `done` work is reviewed and committed on its own. Small commits keep the
review diff small and every step reversible.

1. If the orchestrator returned `complete`, meaning the acceptance test passes with its
   expected-to-fail marker removed, set the spec's `Status:` line to `done`. Stage the spec,
   so the status change lands with the last chunk.
2. Invoke the `review` skill. It reads the spec and the ledger for its context and records
   each round. Route its fix rounds through the orchestrator as it says.
3. When it passes, run `review-diff.sh --check-pass`. If it fails, the index changed after
   the review: run the review again.
4. Commit with a Conventional Commit message (`feat:` or `fix:`) that names the cycles in
   this chunk, or names the scenario if this chunk makes the acceptance test pass. If the
   spec names an issue, add `Refs #<n>` to the body, or `Fixes #<n>` on the chunk that
   completes the spec. End with the attribution trailer exactly as the system
   prompt gives it, and never add a model suffix such as "(1M context)". Pre-commit hooks
   re-run on every amend, so get the message right the first time.
5. Record `commit <short sha> <subject>`.
6. Stop the chunk's orchestrators (`TaskStop`): every one this chunk started or resumed,
   including any the `review` skill used for a fix round, even one that looks finished.
   Then run `git status --short`. A change that shows up now is late work from an agent
   that was still running: stop and show it to the user, and do not fold it into the next
   chunk.

Never resume an orchestrator after its chunk is committed. A finished one carries the whole
chunk's history into the next, and one that is still running keeps editing the tree after
the commit, so its edits reach the next chunk's diff without the review that covered them.
If the orchestrator returned `checkpoint`, go back to step 3 and start a new one for the
next chunk.

## 5. Close the Session

When the last chunk is committed, write the session summary once, as one `summary` line
under 150 words: the files created, the acceptance test and the unit test each cycle
added, and the test count. Then tell the user, in two lines: the next step is `/end-session` to push
and open the pull request, and `/clear` is safe because the ledger holds the state.

## Resuming

To resume after `/clear` or in a new conversation, run `/start-session` again with the same
spec path, or with no argument on the session's branch. The ledger and `git log` are the
whole state; agent IDs from an earlier conversation do not survive, so never try to resume
an orchestrator or phase agent by ID. The user's answers survive as `answer` lines, and
step 3 passes them to the new orchestrator. Staged and unstaged work survives in the
working tree; work that never reached disk is lost, so check `git status --short` first.
