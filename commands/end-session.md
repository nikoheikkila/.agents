---
description: Close out a BDD session - verify every gate, write the context summary, and commit. Use when the user asks to end the session, close out, or commit the finished scenario.
disable-model-invocation: true
allowed-tools: Bash(git status:*), Bash(git add:*), Bash(git commit:*), Bash(git log:*)
---

Complete the session:

1. Confirm the pre-commit hook passed (lint, type-check, secret-scan, SAST)
2. Confirm /review returned {"decision": "pass"}
3. Confirm the pipeline is green (all prior acceptance tests pass)
4. Write the context summary using the format from Small-Batch Sessions.
   This summary replaces the full session conversation in future contexts;
   keep it under 150 words.
5. Commit with a message referencing the scenario name
6. Reset context. The session summary is the only artifact that carries forward.
   The full conversation, implementation details, and review findings do not.
