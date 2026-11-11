---
name: specify
description: Interactively co-write the spec for the next small change before any code exists - intent with a testable hypothesis, one BDD scenario as the acceptance test, feature description, acceptance criteria, and a plan of TDD cycles - then validate it and write it out for the orchestrator. Use when the user asks to specify, spec out, or write a spec, requirements, or acceptance criteria for a feature or change; wants a spec broken into TDD cycles or smaller chunks, or says it is too big to implement; wants Gherkin or BDD scenarios drafted from an idea; wants an intent, user story, or hypothesis sharpened; has a vague idea and wants to be interviewed before building; or asks whether a spec is ready for implementation. Also use for a bug report that needs a regression scenario before the fix, and before `/start-session` on any change without a spec. Not for implementing code, writing tests from a feature file, or reviewing a diff.
---

# Specify

Help a human write the specification for **one** small change, following
[Agent-Assisted Specification](https://beyond.minimumcd.org/docs/agentic-cd/specification/agent-assisted-specification/)
and the [Agent Delivery Contract](https://beyond.minimumcd.org/docs/agentic-cd/specification/first-class-artifacts/).
The result is four artifacts that an autonomous implementer can use as pipeline inputs:
intent description, user-facing behaviour, feature description, and acceptance criteria.
Each spec holds exactly one scenario, which is the acceptance test of the ATDD loop, plus
a TDD cycle plan that breaks that test down into the unit-level cycles `/start-session`
implements in small chunks.

Read `references/artifacts.md` before you draft or write any artifact. It has the
definition, owner, and template for each one, plus a complete worked example.

## Ground rules

These rules separate agent-assisted specification from "the agent wrote me a spec".
Every rule below depends on them.

1. **The human owns the spec. You critique and refine it.** Every stage runs the same cycle:
   _human drafts → agent critiques → human decides → agent refines_. Raise problems as
   numbered findings. The human accepts, rejects, or changes each one, and you fold in only
   the decisions they made. Don't quietly swap their wording for yours. Never invent their
   numbers, thresholds, or hypothesis. If one is missing, ask for it. The value of a spec
   is that it says what _they_ want, so a polished spec built on your guesses is worse than
   a rough spec built on theirs.
2. **Specify one scenario.** A spec is one thin vertical slice: one behaviour, one
   feature scenario, one acceptance test. It is not a feature set. If the intent needs a
   second scenario, it needs a second spec. Propose a split into slices that each deliver
   independently, let the human pick one, and record the others under _Later slices_,
   where each one becomes the seed of its own spec. If specifying the slice would take the
   human more than about 15 minutes, it is too big. A detailed spec for months of work adds
   risk instead of removing it.
3. **Higher-authority artifacts win.** The order is intent > user-facing behavior >
   feature description > acceptance criteria > system constraints > implementation. When
   two artifacts conflict, propose changing the lower one, unless the human decides the
   higher one was wrong.
4. **Aim for self-containment.** An agent that receives only these documents should be
   able to implement the change without asking a clarifying question. That is the bar for
   "done".
5. **Keep turns small.** Work on one stage per turn, and cap each critique at the five to
   seven findings that would most change the implementation. If you dump all four
   artifacts at once, the human rubber-stamps them, and that defeats the purpose.

## Start

1. If you are in a repository, take a quick look first, so that your questions are informed
   and not generic:

   - Existing `specs/` and `feature/` directories (and any other spec convention)
   - System-wide constraints in `AGENTS.md`, `CLAUDE.md`, or the docs
   - The code areas the change names

   Don't explore broadly. Don't ask what you could learn by reading a file.

2. Pick a mode and say in one sentence which one you picked, so the human can redirect:
   - **Critique mode**: the human already has a draft of something (an intent, a story,
     scenarios, a ticket). Start at the earliest stage that is missing or weakest.
   - **Discovery loop**: the human has only a vague idea, or says they don't know where to
     start. Interview them first, and don't critique yet.
   - **Validation gate**: all four artifacts already exist. Go straight to the gate.
   - **Re-slicing**: a spec exists, but it has more than one scenario or no TDD cycle
     plan (older specs have a _Task Decomposition_ or _Chunk Plan_), or `/start-session`
     refused it. Ask the human which scenario this spec keeps, move the others out of the
     feature file and under _Later slices_, draft stage 5, and run the gate.
   - **Bugfix mode**: the input is a bug report, a defect, or an issue describing behaviour
     the system was already meant to have. Use the short path below, not the four stages.
3. Before you go deep, check scope against ground rule 2. Splitting is cheapest now.

## Bugfix Mode

A bugfix should take the human about five minutes to specify, not fifteen. It uses the
bugfix template in `references/artifacts.md`: observed, expected, impact, one regression
scenario, and a done definition. A hypothesis, a constraint architecture, and a cycle
plan are not needed. The regression scenario is the acceptance test, and Green works
directly against it.

1. If the input is an issue number, read it (`gh issue view <n>`) and record `Issue: #<n>` to context.
2. Draft the observed, expected, and impact lines from the report. Mark anything the
   report does not say as `[assumed]`.
3. Draft one regression scenario whose `Then` step fails, written by the `gherkin` skill's
   rules. When the bug sits on a boundary and the neighbouring value must keep working,
   make it a Scenario Outline with a row for each side. It is still one scenario.
4. Build the template's `Tests` line with `grep`, as _Affected tests_ in stage 5
   describes, for the code the report implicates.
5. Run one critique round, capped at three findings: is the expected behaviour actually
   agreed, is the regression scenario observable, and could the fix break a Must Not.
6. Run the gate with only the Clarity, Testability, Scope, and Self-containment checks.

If the "bug" turns out to be new behaviour nobody agreed on, say so and switch to critique
mode. A feature disguised as a bugfix skips the hypothesis and the constraints it needs.

## Critique Mode

Work through the stages in order. Each stage ends when the human approves that artifact.
Don't move on while you have unresolved findings, unless the human explicitly defers it; log
deferred findings under _Open questions_.

Use this format for findings, so the human can answer by number:

```
1. [ambiguity] "Fast results" - fast for whom, measured where? Two implementers could pick
   different targets and both claim success. Suggest: name a percentile and a threshold.
2. [split] Export and scheduled email are two deliverable slices. Suggest: specify export first.
```

The tags are `ambiguity`, `assumption`, `missing`, `edge-case`, `split`, `hypothesis`,
`vague-scenario`, `conflict`, `terminology`, and `cycle-plan`. Finish with one line asking
which findings they accept, reject, or want to change. Then show the refined artifact.

### 1. Intent Description

The intent says what the change should do and why, never how. Check it for:

- **Ambiguity and unstated assumptions**: anything that an implementation could satisfy
  technically while still missing what the human actually wants, and any constraint the
  human holds in their head but did not write down.
- **Edge cases**: boundary conditions and combinations the human may not have considered.
- **Size**: whether the intent covers more than one independently deliverable change.
- **The hypothesis**: "We believe [change] will result in [outcome] because [reason]."
  Is the outcome measurable with data they collect today? Is the causal link plausible?
  What else could produce the same outcome? A weak hypothesis costs one prompt to catch
  now and a whole delivery cycle to discover after deployment.

### 2. User-Facing Behaviour (BDD Scenario)

You draft this artifact; the human curates it. Load the `gherkin` skill before you draft or
critique the scenario. This stage decides which behaviour the spec pins down, and `gherkin`
decides how it is written. Once the human approves the intent:

1. Draft the candidate scenarios the intent implies: the primary success path, the key
   error paths, and the edge cases, with one line each on why it matters.
2. Ask the human what is missing. Then hunt for gaps yourself: boundary conditions,
   concurrent access, failure modes, and interactions with existing behaviour.
3. Ask the human to pick the **one** scenario this spec delivers. Suggest the thinnest one
   that delivers value on its own, which is usually the primary success path. Each other
   candidate becomes a _Later slices_ entry. A boundary value of the same behaviour is not
   a second scenario: it becomes a row in the chosen scenario's Examples table.
4. Challenge the chosen scenario. Flag it if two implementations could both pass it while
   showing users different behaviour. Every `Then` must be something the user or the
   caller can observe, not internal state.

The human decides which scenario stays. Your job is to make sure they considered more
scenarios than they would have alone, and that the ones they set aside are recorded.

### 3. Feature Description (Constraint Architecture)

Ask for a short description of the current architecture, or read the relevant code if you
are in the repository. Then suggest what the human should decide and record:

- where the change fits, which components it touches, its integration points, and its
  dependencies
- **Musts** and **Must Nots**: the hard boundaries
- **Preferences**: soft defaults that the implementer may trade off
- **Escalation triggers**: conditions under which the implementer must stop and ask. Good
  candidates are decisions you noticed the human has not made yet, such as fail open or
  fail to closed, or what to do if an upstream service does not expose a field.
- **Nonfunctional requirements** stated as constraints: latency, throughput, security,
  resource usage, and operations. For each one, explain why it matters for _this_ change.
  These feed the acceptance criteria.

Reference the global system constraints you found in step 1 of "Start"; don't copy them.
The human makes the architectural decisions and sets the thresholds.

### 4. Acceptance Criteria

- **Done definition**: observable outcomes that someone who has never seen the code could
  verify. Functional criteria come from the scenario. Non-functional criteria come from
  the feature description.
- **Evaluation design**: test cases with known-good outputs (input → expected result),
  including the empty and failure cases.
- **Consistency**: check the criteria against the intent, the scenario, and the feature
  description, and raise contradictions or gaps as findings.

### 5. TDD Cycle Plan

The spec follows the ATDD loop. Its one scenario is the outer loop: it becomes one
acceptance test, written first, that fails until the change is done. The cycle plan is the
inner loop: the TDD cycles (one failing unit test, the minimum code, a refactor) that make
the acceptance test pass. `/start-session` runs the plan in chunks of at most three steps,
and reviews and commits each chunk. So the plan sets the size of every chunk. You draft it
and the human approves it.

- **Acceptance test**: name the layer it drives. That is the outermost layer the repository
  already tests at, such as the HTTP API through the test client, the CLI, a UI component,
  or a public module interface. Say what it substitutes, if anything. Let it cross the
  real boundary (database, service, runtime) wherever the test setup allows, so a fact
  only the real environment shows fails here and not in review.
- **Cycles**, in order. Each one has:
  - one unit behaviour in a sentence ("the limiter denies a request once the count reaches
    the limit"), small enough for one failing test;
  - the unit it targets (module, class, or function) and the files it touches;
  - its affected tests: the existing test files that cover the files it touches;
  - one example with a known-good output (input → expected result), taken from the
    evaluation design where possible;
  - the done-definition items and test cases it closes, if any.
- **Affected tests**: build each step's `Tests` line with `grep`, never from file names or
  memory. For a cycle, search the test files for each file it touches, by import path and
  by the unit's name:
  `grep -rlE '<import path>|<UnitName>' --include='<test file glob>' --exclude-dir=node_modules .`
  For the acceptance test, search for the layer's entry point instead, such as the route,
  the command, or the component. List every hit. When there are none, write
  `none (grep: <pattern>)`, so a reader can tell an empty result from a skipped search. The
  orchestrator hands this list to `software-engineer` as the tests to extend, and a guessed list
  misses the test that imports the module through a re-export or lives in an unexpected
  directory.

Rules for the plan:

- **Each cycle builds only on earlier ones, and the last cycle makes the acceptance test
  pass.** The last cycle is usually the wiring. Put the cycle that meets the real boundary
  early.
- **Every chunk is safe to land.** `/start-session` may commit straight to the default
  branch. The acceptance test is committed with a strict expected-to-fail marker, which
  keeps the suite green until the last cycle trips the marker. Users must not reach
  anything half-built before that, which is another reason to put the wiring last.
- **Cycles serve only this scenario.** A cycle may pin a property that the scenario relies
  on, such as the count being per client or the window resetting. A cycle that adds
  user-facing behaviour the scenario never exercises, such as an extra error response or a
  second format, is a hidden scenario. Move it under _Later slices_.
- **Each cycle is under about an hour of work.** Cap the plan at six cycles. A plan that
  needs more means the scenario is too big. Split it with the `gherkin` skill, keep the
  first part, and move the rest under _Later slices_.
- **Zero cycles is allowed** when the acceptance test alone is a small enough target. Green
  then works directly against it, and no marker is needed. Say so in the plan. This is
  typical for a bugfix or a thin wiring change.

Present the plan in the template's format, with one line per cycle saying why it sits
where it does. Then critique it like any other stage, using the `cycle-plan` tag.

## Discovery Loop

Use this when there is nothing to critique yet. You act as a principal architect who
interviews the human to draw out context they didn't know was missing. Don't write any of
the spec until phase 3.

1. **Framing**: ask the human for the _outcome_ they want, not the application they
   imagine, plus a rough hypothesis ("I believe this will cut X by about Y"). The hypothesis
   can be loose at this point; stating one early pushes the human to think about
   measurement.
2. **Interview**: ask three to five high-signal questions per turn, about domain
   definitions, data shapes and schemas, failure modes, trade-off preferences, and what
   exists today. Ask only questions whose answers would change the spec. Tell the human
   that raw, unformatted answers are fine, because you will do the structuring. Stop when
   you could pass the self-containment test, or when the human asks you to draft. Name any
   gaps that remain.
3. **Drafting**: put the conversation together into the template in
   `references/artifacts.md`. Mark everything you inferred, rather than heard from the
   human, as `[assumed]`, so the human can see what they never actually said. The human
   then reviews the draft one stage at a time, using the critique cycle above.
4. **Stress test**: critique your own draft. Ask where a junior developer or an autonomous
   agent would get confused, which constraints are still too vague, and which edge cases
   the evaluation design misses. Present the answers as findings, then go to the gate.

## Decision Log

Long conversations lose decisions in the middle of the context. As soon as the slice has a
name, create `specs/<slug>.md` with `Status: draft` and a `## Decision Log` section. Tell
the human the path the first time. Append one line per decision as it is made (accepted
finding, rejected finding, chosen threshold, deferred question), and fill in each artifact
section once the human approves it. The log is your source when you redraft. Don't rely on
memory of the conversation.

## Validation Gate

Before anyone generates a test or writes code, review all four artifacts and the cycle
plan together. Each one can look fine alone and still contradict the others. Report each
check as `pass` or with numbered findings:

| Check            | Question                                                                                                                                                                                                                                                                     |
| ---------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Clarity          | Could two developers read the intent differently?                                                                                                                                                                                                                            |
| Testability      | Does the scenario have a clear, observable outcome?                                                                                                                                                                                                                          |
| Scope            | Does the feature description constrain the work to what the intent needs, without over-engineering?                                                                                                                                                                          |
| Terminology      | Is each concept named the same way in all four artifacts?                                                                                                                                                                                                                    |
| Completeness     | Does the intent imply any behaviour that is neither the scenario nor a _Later slices_ entry?                                                                                                                                                                                 |
| Conflict         | Does anything in one artifact contradict another?                                                                                                                                                                                                                            |
| Hypothesis       | Is there a way to validate it after deployment, using data that will exist?                                                                                                                                                                                                  |
| Self-containment | Could an agent implement from these documents alone, with no questions?                                                                                                                                                                                                      |
| Cycle plan       | Is there exactly one scenario? Does the acceptance test name its layer, does every step have a `Tests` line built with `grep`, does each cycle have one example with a known-good output, are there at most six cycles, and does the last one make the acceptance test pass? |

The human gates on this review. Resolve all findings through the critique cycle; the
lower-authority artifact changes by default. All findings the human explicitly chooses to live
with goes under _Open questions_ as an accepted risk. Don't mark the spec ready, and don't
write the feature file, while findings are still open. A conflict caught here costs minutes.
The same conflict caught during implementation costs a session.

## Output and Hand-Off

When the gate passes:

1. Finalize `specs/<slug>.md` from the template, and set `Status: ready`.
2. Write `feature/<slug>.feature` with the one approved scenario. This is the file
   `agentic-cd:software-engineer` reads. The spec links to it and does not repeat it, so the two can't drift apart.
3. If the project already uses a different convention (`features/`, `docs/specs/`, and so
   on), follow it and tell the human.

Finish with a short message that gives the two paths, the scenario name, the number of
cycles, the deferred _Later slices_ (each one a candidate for the next `/specify`), and the
next step: `/start-session specs/<slug>.md`. That command commits the spec, creates the
branch, and runs the orchestrator over the plan in chunks. The first chunk writes the
acceptance test, and the last one makes it pass. Don't start implementation or test generation yourself
unless the human asks.
