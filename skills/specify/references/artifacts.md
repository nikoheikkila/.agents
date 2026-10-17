# Specification Artifacts

Definitions, templates, and a worked example. The source is the MinimumCD
[Agent Delivery Contract](https://beyond.minimumcd.org/docs/agentic-cd/specification/first-class-artifacts/).

## Contents

1. Artifacts, owners, and authority
2. The `specs/<slug>.md` template
3. The bugfix template
4. The `feature/<slug>.feature` template
5. Worked example: rate limiting `/api/search`

## 1. Artifacts, owners, and authority

| Priority | Artifact             | What it is                                                                 | Owner                           |
| -------- | -------------------- | -------------------------------------------------------------------------- | ------------------------------- |
| 1        | Intent description   | A self-contained problem statement: what the change does and why, with a hypothesis. Never how. | Human. The agent critiques it but never writes it. |
| 2        | User-facing behavior | Observable outcomes from the user's point of view, written as BDD scenarios. | Human picks the scenarios. The agent may draft them. |
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

See `feature/<slug>.feature`. <One line per scenario name, so a reader can scan coverage.>

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

## 5. Task Decomposition

**<Module or task>**: Input: ... Output: ... (under about two hours)

## Later slices

- <Deferred slice>: <one line>

## Open questions

- <Deferred finding or accepted risk, and who decided>

## Decision log

- <date> <decision>: <accepted/rejected/changed>. <one-line reason>
```

## 3. Bugfix template

A bugfix restores behaviour the system was already meant to have, so it skips the
hypothesis, the constraint architecture, and the task decomposition. The regression
scenario is the whole plan. Use the same `specs/<slug>.md` path and a `fix-` slug prefix.

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

See `feature/<slug>.feature`: one regression scenario that fails today. Add a second
scenario only when the bug sits on a boundary and the neighbouring value must keep working.

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

Each `Then` must be observable by the user or caller. Use `Background` for shared
preconditions, and `Scenario Outline` with `Examples` for boundary values. The `gherkin`
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

**Scenarios**

```gherkin
Scenario: Client exceeds rate limit
  Given an authenticated client
  And the client has made 100 requests in the current minute
  When the client makes another request to /api/search
  Then the response status is 429
  And the response includes a Retry-After header
  And the Retry-After value indicates when the limit resets

Scenario: Client within rate limit
  Given an authenticated client
  And the client has made 50 requests in the current minute
  When the client makes a request to /api/search
  Then the request is processed normally
  And the response includes rate limit headers showing remaining quota
```

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

1. 100 requests in one minute get normal responses, with headers showing the remaining
   quota.
2. The 101st request in the same minute gets a 429 with a Retry-After header.
3. After the window expires, the limited client can make requests normally again.
4. Another client is unaffected by one client's limit.
5. The middleware adds less than 5 ms to p99 latency.

Evaluation design: Happy Path (50 requests → all 200, remaining count goes down), Limit
Exceeded (the 101st request → 429), Window Reset (the request after the window → 200),
Per-Client Isolation (A over its limit, B → 200), Latency Budget (< 5 ms).

Why this passes the gate: every criterion is observable from outside the code. The
escalation triggers name the two decisions the human had not yet made. The hypothesis
names a metric (p99 latency for well-behaved clients) that exists after deployment.
