---
description: Start or resume a BDD implementation session. Use when the user asks to start or resume a session, begin the next scenario, or kick off the agentic-CD loop.
argument-hint: "[scenario-name-or-number]"
disable-model-invocation: true
allowed-tools: Read, Grep, Glob, Agent(orchestrator)
---

Start or resume a BDD implementation session for: $ARGUMENTS

Delegate to the `orchestrator` subagent. Pass it only:

- The scenario to implement this session - not the full scenario list
- The feature description
- The prior session summary, if one exists

The orchestrator owns context assembly, the context hygiene test, and routing to
`implementation`. Do not assemble that context here and do not invoke `implementation`
directly.

Present the orchestrator's assembled context to the user for confirmation before
implementation begins.
