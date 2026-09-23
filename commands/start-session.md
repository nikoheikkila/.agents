---
description: Start or resume an implementation session.
disable-model-invocation: true
allowed-tools: Read, Grep, Glob, Agent(orchestrator)
---

Start or resume an implementation session from a session plan.

Delegate to the `orchestrator` subagent. Pass it only:

- The plan to implement in this session
- The prior session summary, if one exists

The orchestrator owns context assembly, the context hygiene test, and routing to
`implementation`. Do not assemble that context here and do not invoke `implementation`
directly.

Present the orchestrator's assembled context to the user for confirmation before
implementation begins.
