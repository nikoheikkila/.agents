---
description: Close out an implementation session and verify every gate, write the context summary, and commit.
disable-model-invocation: true
---

Complete the session:

1. Confirm the whole test pipeline is passing locally.
2. Confirm /review returned {"decision": "pass"} as output.
3. Confirm the remote pipeline is green — all prior acceptance tests must pass before pushing.
4. Write the context summary using the example below as a reference.
   This summary replaces the full session conversation in future contexts;
   keep it under 150 words.
5. Commit with a message referencing the scenario name
6. Push the commit and watch the remote pipeline run. If the remote pipeline fails, invoke `/fix` to fix it.
7. Reset context. The session summary is the only artifact that carries forward.
   The full conversation, implementation details, and review findings do not.

## Context Summary Example

```md
Session 1 implemented Plan 1 (client exceeds rate limit returns 429).

Files created:

- src/redis.ts - Redis client with connection pooling
- src/middleware/rate-limit.ts - middleware that checks request count
  against Redis and returns 429 with Retry-After header when exceeded

Tests added:

- src/middleware/rate-limit.test.ts - covers Scenario 1

All pipeline checks pass.
```
