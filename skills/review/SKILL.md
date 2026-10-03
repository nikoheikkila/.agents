---
name: review
description: Run the pre-commit review gate on the staged diff. Use when the user asks to review staged changes, run the review gate, or check whether changes are ready to commit, and when the TDD cycle reports it is done.
allowed-tools: Bash(git diff:*), Bash(git status:*), Bash(*/scripts/review-diff.sh:*), Agent(review-orchestrator)
---

Run the pre-commit review gate. The gate is cheap only if it converges, so it runs in
rounds with a fixed bar: round 1 reviews everything, later rounds review only what the
fixes changed, and only findings with a concrete failure scenario block.

1. Prepare the diff with `scripts/review-diff.sh` from this skill's directory (the harness
   names that directory when it loads the skill; run the script by its absolute path).
   Round 1, or any time no earlier round exists:

   ```bash
   <skill directory>/scripts/review-diff.sh
   ```

   Every later round, after fixes are staged:

   ```bash
   <skill directory>/scripts/review-diff.sh --delta
   ```

   The script writes the diff to a file (lockfiles excluded), records the index tree so
   the next round can diff against it, and prints `mode`, `path`, and `lines`. If it
   reports nothing staged, stop and say so. If `git status --short` shows an unstaged
   change to a file you mean to commit (`MM`), stage it first; reviewers only see the index.

2. Assemble the review orchestrator's context in this order:
   a. Feature description [stable within this feature - often cached]
   b. Current plan [changes per session]
   c. Accepted-risk list: concerns the user or an earlier round already decided to live
      with, one line each. Start it from anything the user has said is out of scope
   d. `mode`, and for a `delta` round the previous round's blocking findings
   e. The diff: the file path from step 1 (or the text itself if it is under ~300 lines)
3. Spawn the `review-orchestrator` subagent with only this assembled context.
   Do not pass the full session conversation or TDD agent history.
4. `review-orchestrator` returns JSON. Parse the JSON directly; do not re-summarize
   its findings in prose.
5. If `decision` is `pass`, sort the `advisory` findings into two groups:
   - **Fix now**: cheap and inside the change's own scope. Docs or instructions that the
     diff made stale, dead code or parameters the diff left behind, and a missing test for
     behaviour the change states. Users asked for these to be fixed after nearly every gate,
     so fix them by default. Route them through the `orchestrator` in one fix round before
     the commit, then run one `--delta` round. If the repository's instructions say
     otherwise, follow them
   - **Defer**: hardening, design opinions, or anything outside the change's scope. List
     these once, as a short list for the pull request description or a follow-up issue
   Tell the user which group each advisory went into, in one line each.
6. If `decision` is `block`, triage the `blocking` findings before routing anything:
   - Check each against the code or the platform's documented behaviour. A finding whose
     `failure_scenario` does not hold is dropped and added to the accepted-risk list
   - A finding that needs a product decision (naming, scope, a trade-off the user has not
     made) goes to the user as one batched question with a recommended default, not to the
     TDD agents
   - Pass the rest, grouped by file and only the findings, to the `orchestrator` subagent
     for routing back to the TDD phase agents. One fix round per gate round, never one per
     finding
   Then stage the fixes and go back to step 1 with `--delta`.
7. Stop after round 3. If round 3 still blocks, do not loop again: report the remaining
   blocking findings to the user and let them decide. Three blocked rounds in a row mean
   the fixes are going in without a check against the real runtime (production build,
   end-to-end run), or the findings need a decision only the user can make.
8. Do not proceed to commit until the gate returns {"decision": "pass"}.
