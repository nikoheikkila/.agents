---
description: Run the pre-commit review gate on the staged diff. Use when the user asks to review staged changes, run the review gate, or check whether changes are ready to commit, and when an implementation agent reports it is done.
allowed-tools: Bash(git diff:*), Agent(review-orchestrator)
---

Fetch the staged diff under review:

```bash
git diff --cached
```

Run the pre-commit review gate:

1. If the diff above is empty, stop and report that nothing is staged.
2. Assemble the review orchestrator's context in this order:
   a. Feature description [stable within this feature - often cached]
   b. Current plan [changes per session]
   c. The staged diff above [changes per call]
3. Spawn the `review-orchestrator` subagent with only this assembled context.
   Do not pass the full session conversation or implementation agent history.
4. `review-orchestrator` returns JSON. Parse the JSON directly; do not re-summarize
   its findings in prose.
5. If "decision" is "block", pass the findings array to the `orchestrator` subagent
   for routing back to `implementation`. Include only the findings, not the full
   review context.
6. Do not proceed to commit until `/review` returns {"decision": "pass"}.
