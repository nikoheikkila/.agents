# Specification Artifacts

Definitions, templates, and a worked example. The source is the MinimumCD
[Agent Delivery Contract](https://beyond.minimumcd.org/docs/agentic-cd/specification/first-class-artifacts/).

## Contents

1. Artifacts, owners, and authority
2. The `specs/<slug>.md` template, with the TDD cycle plan
3. The bugfix template
4. The `feature/<slug>.feature` template
5. Worked example: rate limiting `/api/search`

## 1. Artifacts, owners, and authority

| Priority | Artifact             | What it is                                                                 | Owner                           |
| -------- | -------------------- | -------------------------------------------------------------------------- | ------------------------------- |
| 1        | Intent description   | A self-contained problem statement: what the change does and why, with a hypothesis. Never how. | Human. The agent critiques it but never writes it. |
| 2        | User-facing behavior | One observable outcome from the user's point of view, written as one BDD scenario. It is the ATDD acceptance test. | Human picks the scenario. The agent may draft candidates. |
| 3        | Feature description  | The constraint architecture: Musts, Must Nots, Preferences, and Escalation Triggers. Non-functional requirements go here as constraints. | Engineering. |
| 4        | Acceptance criteria  | A done definition (observable outcomes) plus an evaluation design (test cases with known-good outputs). Derived from 2 (functional) and 3 (non-functional). | Human defines. The agent may write the test code. |
| 5        | System constraints   | Global rules that apply to every change, such as security, performance, architecture, and operations. They live in the repo, not in each spec. | Organization. |
| 6        | Implementation       | The code. Lowest authority: when it conflicts with anything above, the code changes. | Agent or human. |

Acceptance criteria answer "does the code work?" and run in the pipeline on every commit.
The hypothesis asks "did the change achieve its purpose?" and is checked with production
data after deployment. A change can pass every criterion and still refute its hypothesis.
That is still a useful result, because it feeds the next intent.

## 2. `specs/<slug>.md` template

Leave out a section's placeholder text once the section is filled. Keep `[assumed]` markers
until the human confirms or replaces each one.

```markdown
# Specification: <slice name>

Status: draft | ready | done
Type: feature
Issue: #<n> (omit when there is none)
Feature file: feature/<slug>.feature

## 1. Intent Description

<What the change should accomplish and why, in the human's words. Self-contained: no
links that are needed to understand the problem.>

**Hypothesis:** We believe <change> will result in <measurable outcome> because <reason>.
Validated after deployment by <metric / data source> over <time window>.

## 2. User-Facing Behavior

See `feature/<slug>.feature`. <The scenario name, so a reader knows what the acceptance test pins down.>

## 3. Feature Description

<Where the change fits: the components it touches and its integration points.>

### Musts
- ...

### Must Nots
- ...

### Preferences
- ...

### Escalation Triggers
- If <condition>, stop and ask <the decision needed>.

## 4. Acceptance Criteria

### Done definition
1. <Observable outcome an outsider could verify>

### Evaluation design
**Test Case 1 (<name>):** <input/setup>. Result: <known-good output>.

## 5. TDD Cycle Plan

The scenario is the ATDD outer loop: one acceptance test, written first and committed with a
strict expected-to-fail marker. The cycles are the inner loop that makes it pass.
`/start-session` runs the steps (`A`, then cycles `1` to `n`) in chunks of at most three,
and commits each chunk. Six cycles at most.

### Acceptance test

- Drives: <the outermost layer the repo tests at, such as the HTTP API through the test client>
- Substitutes: <test doubles at the edge, or "none">
- Closes: Done definition <n>; Test Case <n>

### Cycle 1: <unit behaviour in a few words>

- Unit: <module, class, or function>. Touches: <files>
- Example: <input> → <expected output>
- Closes: Done definition <n>; Test Case <n> (omit when none)

<For a zero-cycle plan, replace the cycles with a `### Cycles` heading and the line "None:
Green works directly against the acceptance test.">

## Later slices

- <Deferred slice>: <one line>

## Open questions

- <Deferred finding or accepted risk, and who decided>

## Decision log

- <date> <decision>: <accepted/rejected/changed>. <one-line reason>
```

## 3. Bugfix template

A bugfix restores behaviour the system was already meant to have, so it skips the
hypothesis, the constraint architecture, and the cycle plan. The regression scenario is
the acceptance test, Green works directly against it, and the fix lands in one chunk.
Use the same `specs/<slug>.md` path and a `fix-` slug prefix.

```markdown
# Specification: <what is broken, in the user's words>

Status: draft | ready | done
Type: bugfix
Issue: #<n> (omit when there is none)
Feature file: feature/<slug>.feature

## 1. Intent Description

**Observed:** <what happens today, with the exact input or steps>
**Expected:** <what should happen instead>
**Impact:** <who is affected and how badly; one line>

## 2. User-Facing Behavior

See `feature/<slug>.feature`: one regression scenario that fails today. When the bug sits
on a boundary and the neighbouring value must keep working, make it a Scenario Outline
with a row for each side.

## 3. Constraints

<Only the Musts or Must Nots this fix could plausibly break, such as "must not change the
public API". Omit the section when there are none.>

## 4. Acceptance Criteria

1. <The regression scenario passes.>
2. <The existing suite stays green.>

## Decision log

- <date> <decision>
```

## 4. `feature/<slug>.feature` template

One scenario per file, and each `Then` must be observable by the user or caller. Use a
`Scenario Outline` with `Examples` for boundary values of the same behaviour. The `gherkin`
skill has the full language and style rules.

```gherkin
Feature: <slice name>
  <One-sentence intent summary>

  Scenario: <behavior in plain words>
    Given <precondition>
    When <action>
    Then <observable outcome>
```

## 5. Worked example: rate limiting `/api/search`

**Intent**

> We are receiving complaints about slow response times during peak hours. Analysis shows
> that a small number of clients are making thousands of requests per minute. We need to
> limit each authenticated client to 100 requests per minute on the /api/search endpoint.
> Requests that exceed the limit should receive a 429 response with a Retry-After header.
>
> **Hypothesis:** We believe rate limiting will reduce p99 latency for well-behaved clients
> by 40% because abusive clients currently consume 60% of search capacity.

**Scenario**

```gherkin
Scenario: Client exceeds rate limit
  Given an authenticated client
  And the client has made 100 requests in the current minute
  When the client makes another request to /api/search
  Then the response status is 429
  And the response includes a Retry-After header
  And the Retry-After value indicates when the limit resets
```

The human also drafted "Client within rate limit", which shows the remaining quota in
response headers. That is a different behaviour, so it went under _Later slices_ as the
next spec.

**Feature description**

- Musts: middleware sits between authentication and the search handler. State is kept in
  Redis, shared across instances. The limit is read from config, not hardcoded. Works with
  3-12 instances. Configurable per endpoint.
- Must Nots: no more than 5 ms added latency. No new external dependencies (a Redis client
  is already in use).
- Preferences: the middleware pattern over decorators. A sliding window over a fixed
  window.
- Escalation triggers: if Redis is unavailable, stop and ask whether to fail open or fail
  closed. If the auth middleware does not expose the client ID, stop and ask rather than
  modifying the auth layer.

**Acceptance criteria**

1. The 101st request in one minute gets a 429 with a Retry-After header that says when
   the limit resets.
2. Requests up to the 100th in the same minute are processed normally.
3. After the window expires, the limited client is served again.
4. Another client is unaffected by one client's limit.
5. The middleware adds less than 5 ms to p99 latency.

Evaluation design: Limit Reached (100 requests made → the 101st gets 429 and
`Retry-After: 20` when 20 s of the window remain), Under Limit (99 made → the 100th gets
200), Window Reset (the request after the window → 200), Per-Client Isolation (A over its
limit, B → 200), Latency Budget (< 5 ms).

**TDD cycle plan**

- Acceptance test: drives `/api/search` through the app's HTTP test client, with the real
  middleware chain and the Redis test instance. Closes criterion 1 and Limit Reached.
- Cycle 1, _Count requests per client_: `RequestCounter` over Redis. Example: client A
  increments three times and B once → A = 3, B = 1. Closes criterion 4 and Per-Client
  Isolation. It goes first because it meets Redis.
- Cycle 2, _Expire counts with the window_: `RequestCounter`. Example: 100 requests at
  12:00:30, read at 12:01:31 → 0. Closes criterion 3 and Window Reset.
- Cycle 3, _Decide allow or deny_: `RateLimiter.check(client, now)`. Example: count 99 →
  allowed; count 100 with 20 s of the window left → denied, retry after 20. Closes
  criterion 2 and Under Limit.
- Cycle 4, _Reject with 429_: the middleware, registered between authentication and the
  search handler. Example: a denied check → 429 with `Retry-After: 20`. This cycle makes
  the acceptance test pass. Closes criterion 5 and Latency Budget.

Why this passes the gate: every criterion is observable from outside the code. The
escalation triggers name the two decisions the human had not yet made. The hypothesis
names a metric (p99 latency for well-behaved clients) that exists after deployment. The
spec holds one scenario, and the remaining-quota behaviour waits for its own spec. Each
cycle builds on the one before it, the first meets Redis, and the last wires the
middleware in, which is the first point at which a client can be rejected. Until then,
every chunk lands with the acceptance test marked expected-to-fail.
