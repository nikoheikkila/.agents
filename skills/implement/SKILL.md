---
name: "implement"
description: "Implement the changes with parallel subagents after the plan has been accepted. Runs simplification, code
review, and security review after the task is done."
disable-model-invocation: true
arguments: [model, effort]
argument-hint: "[model] [effort]"
---

The user has accepted the plan output from Plan mode.
Your task is to dispatch parallel $model subagents with $effort effort level to implement the plan.

Run `/simplify`, `/code-review`, and `/security-review` skills once ready. Consider all the findings from review rounds
and ask user before discarding a finding.
