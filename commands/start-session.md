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

Present the orchestrator's assembled context to the user for confirmation before
implementation begins. Put the orchestrator's `questions` in that same message as one
batch, each with its recommended default and any feasibility risk it found, so the user
answers once instead of once per surprise.

After the user confirms, tell the orchestrator that the scope is confirmed and let it
run. It returns a checkpoint after at most three TDD cycles: verify the checkpoint
yourself (`git status --short`, the test command) and start the next chunk with the
checkpoint as the prior session summary. If a run ends with a plan instead of finished
work, resend the confirmation and tell it to dispatch `tdd-red` now; do not re-explain
the scope.
