---
name: review
description: Run the pre-commit review gate on the staged diff. Use when the user asks to review staged changes, run the review gate, or check whether changes are ready to commit, and when the TDD cycle reports it is done.
allowed-tools: Read, Grep, Glob, Bash(git diff:*), Bash(git status:*), Bash(git add:*), Bash(*/scripts/review-diff.sh:*), Bash(*/scripts/ledger.sh:*), Agent(review-orchestrator), Agent(orchestrator)
---

Run the pre-commit review gate. The gate is cheap only if it converges, so it runs in
rounds with a fixed bar: round 1 reviews everything, later rounds review only what the
fixes changed, and only findings with a concrete failure scenario block.

Both scripts live in this skill's `scripts/` directory (the harness names that directory
when it loads the skill; run them by their absolute path). `ledger.sh` holds the session
state across `/clear`. Find the session with `ledger.sh find`. If there is none, this is an
ad hoc review: take the context from the conversation and skip every ledger step below.

1. Prepare the diff. Round 1, or any time no earlier round exists:

   ```bash
   <skill directory>/scripts/review-diff.sh
   ```

   Every later round, after fixes are staged:

   ```bash
   <skill directory>/scripts/review-diff.sh --delta
   ```

   The script writes the diff to a file (lockfiles excluded), records the index tree and
   HEAD so the next round can diff against it, and prints `mode`, `path`, and `lines`. A
   `--delta` after a commit falls back to `full` by itself. If it reports nothing staged,
   stop and say so. If `git status --short` shows an unstaged change to a file you mean to
   commit (`MM`), stage it first; reviewers only see the index.

2. Assemble the review orchestrator's context in this order:
   a. Feature description: §3 of the spec named by `ledger.sh show <slug> spec`
      [stable within this feature - often cached]
   b. Current plan: the spec's feature file and the scenarios in the last `chunk` line
      [changes per session]
   c. Accepted-risk list: `ledger.sh show <slug> risk`, plus anything the user has said is
      out of scope, one line each
   d. `mode`, and for a `delta` round the previous round's blocking findings
   e. The diff: the file path from step 1 (or the text itself if it is under ~300 lines)
3. Spawn the `review-orchestrator` subagent with only this assembled context.
   Do not pass the full session conversation or TDD agent history.
4. `review-orchestrator` returns JSON. Parse the JSON directly; do not re-summarize
   its findings in prose. Record one `review` line: round number, mode, decision, and the
   count of blocking and advisory findings.
5. If `decision` is `pass`, sort the `advisory` findings into two groups:
   - **Fix now**: cheap and inside the change's own scope. Docs or instructions that the
     diff made stale, dead code or parameters the diff left behind, and a missing test for
     behaviour the change states. Users asked for these to be fixed after nearly every gate,
     so fix them by default. Route them through the `orchestrator` in one fix round before
     the commit, then run one `--delta` round. If the repository's instructions say
     otherwise, follow them
   - **Defer**: hardening, design opinions, or anything outside the change's scope. Record
     each as a `defer` line; `/end-session` puts them in the pull request description
   Tell the user which group each advisory went into, in one line each.
6. If `decision` is `block`, triage the `blocking` findings before routing anything:
   - Check each against the code or the platform's documented behaviour. A finding whose
     `failure_scenario` does not hold is dropped and recorded as a `risk` line
   - A finding that needs a product decision (naming, scope, a trade-off the user has not
     made) goes to the user as one batched question with a recommended default, not to the
     TDD agents. Record a decision to live with it as a `risk` line
   - Pass the rest, grouped by file and only the findings, to the `orchestrator` subagent
     for routing back to the TDD phase agents. One fix round per gate round, never one per
     finding
   Then stage the fixes and go back to step 1 with `--delta`.
7. Stop after round 3. If round 3 still blocks, do not loop again: report the remaining
   blocking findings to the user and let them decide. Three blocked rounds in a row mean
   the fixes are going in without a check against the real runtime (production build,
   end-to-end run), or the findings need a decision only the user can make.
8. When the final round passes and no fix-now round is pending, run
   `review-diff.sh --mark-pass`. That records the exact tree the gate passed; the caller
   commits only if `review-diff.sh --check-pass` still matches. You do not commit.
