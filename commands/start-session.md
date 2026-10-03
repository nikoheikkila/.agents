---
description: Start or resume an implementation session.
disable-model-invocation: true
allowed-tools: Read, Grep, Glob, Bash(git status:*), Agent(orchestrator)
---

Start or resume an implementation session from a session plan.

Delegate to the `orchestrator` subagent. Pass it only:

- The plan to implement in this session
- The prior session summary, if one exists

The orchestrator owns context assembly, the context hygiene test, and routing to
the TDD phase agents. Do not assemble that context here and do not invoke `tdd-red`,
`tdd-green`, or `tdd-refactor` directly.

If the orchestrator returns `questions`, present them to the user as one batch, each
with its recommended default and any feasibility risk it found, so the user answers once
instead of once per surprise. Show its `assumptions` in the same message. If it returns
no questions, don't stop for a confirmation: show the assumptions in one line each and
let it run. Users answered "accept defaults" to nearly every confirmation, so a question
that has a safe default costs a round trip for nothing.

After the user answers, or straight away when there were no questions, tell the
orchestrator that the scope is confirmed and let it run. It returns a checkpoint after at most three TDD cycles: verify the checkpoint
yourself (`git status --short`, the test command) and start the next chunk with the
checkpoint as the prior session summary. If a run ends with a plan instead of finished
work, resend the confirmation and tell it to dispatch `tdd-red` now; do not re-explain
the scope. If a checkpoint arrives while a phase agent is still running (its `done` is
empty, or the files it lists are not in `git status --short`), wait for that agent's
completion notification before you verify or re-dispatch anything.

To resume after `/clear` or in a new conversation, pass the last checkpoint JSON and the
plan as the prior session summary. Agent IDs from an earlier conversation do not
survive, so never try to resume an orchestrator or phase agent by ID. Work that never
reached disk is lost: check `git status --short` first.
