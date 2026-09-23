---
description: Enter pipeline-restore mode and repair a red pipeline with minimum context. Use when a test, build, or pipeline stage fails mid-session and the pipeline must go green before new work.
argument-hint: "[failing-stage-or-test]"
allowed-tools: Read, Bash(git diff:*), Agent(orchestrator)
---

Enter pipeline-restore mode. Load minimum context only.

Failure to restore: $ARGUMENTS

1. Identify the failure: which stage failed, which test, which error message.
2. Delegate to the `orchestrator` subagent in pipeline-restore mode, passing only the
   failure identified above. The orchestrator owns the restore-mode rules and routing
   to `implementation`; do not assemble that context here and do not invoke
   `implementation` directly.
3. Run `/review` on the fix. Pass only the fix diff, not the restore session history.
4. Confirm the pipeline is green. Exit restore mode and return to normal session flow.
