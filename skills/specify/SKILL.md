---
name: specify
description: Interactively co-write the specification for the next small change before any code exists - intent description with a testable hypothesis, BDD scenarios, feature description (musts, must nots, preferences, escalation triggers), and acceptance criteria with evaluation design - then validate the set and write it out for the orchestrator. Use when the user asks to specify, spec out, write a spec or requirements for, or define acceptance criteria for a feature or change; when they want Gherkin or BDD scenarios drafted from an idea; when they want an intent, user story, or hypothesis sharpened or critiqued; when they have a vague idea and want to be interviewed before building; and when they ask whether a spec is consistent or ready for implementation. Also use for a bug report, defect, or issue that needs a regression scenario before it is fixed, and before `/start-session` or the orchestrator on any change that has no spec. Not for implementing code, writing tests from an existing feature file (tdd:red), or reviewing a diff (review).
---

# Specify

Help a human write the specification for **one** small change, following
[Agent-Assisted Specification](https://beyond.minimumcd.org/docs/agentic-cd/specification/agent-assisted-specification/)
and the [Agent Delivery Contract](https://beyond.minimumcd.org/docs/agentic-cd/specification/first-class-artifacts/).
The result is four artifacts that an autonomous implementer can use as pipeline inputs:
intent description, user-facing behavior, feature description, and acceptance criteria.

Read `references/artifacts.md` before you draft or write any artifact. It has the
definition, owner, and template for each one, plus a complete worked example.

## Ground rules

These rules separate agent-assisted specification from "the agent wrote me a spec".
Every rule below depends on them.

1. **The human owns the spec. You critique and refine it.** Every stage runs the same cycle:
   *human drafts → agent critiques → human decides → agent refines*. Raise problems as
   numbered findings. The human accepts, rejects, or changes each one, and you fold in only
   the decisions they made. Don't quietly swap their wording for yours. Never invent their
   numbers, thresholds, or hypothesis. If one is missing, ask for it. The value of a spec
   is that it says what *they* want, so a polished spec built on your guesses is worse than
   a rough spec built on theirs.
2. **Specify one thin vertical slice.** That means a single behavior that can ship on its
   own, not a feature set. If specifying it would take the human more than about 15
   minutes, the change is too big. Propose a split into slices that each deliver
   independently, let the human pick one, and record the others under *Later slices*. A
   detailed spec for months of work adds risk instead of removing it.
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
   - existing `specs/` and `feature/` directories (and any other spec convention)
   - system-wide constraints in `AGENTS.md`, `CLAUDE.md`, or the docs
   - the code areas the change names

   Don't explore broadly. Don't ask what you could learn by reading a file.
2. Pick a mode and say in one sentence which one you picked, so the human can redirect:
   - **Critique mode**: the human already has a draft of something (an intent, a story,
     scenarios, a ticket). Start at the earliest stage that is missing or weakest.
   - **Discovery loop**: the human has only a vague idea, or says they don't know where to
     start. Interview them first, and don't critique yet.
   - **Validation gate**: all four artifacts already exist. Go straight to the gate.
   - **Bugfix mode**: the input is a bug report, a defect, or an issue describing behaviour
     the system was already meant to have. Use the short path below, not the four stages.
3. Before you go deep, check scope against ground rule 2. Splitting is cheapest now.

## Bugfix mode

A bugfix should take the human about five minutes to specify, not fifteen. It uses the
bugfix template in `references/artifacts.md`: observed, expected, impact, one regression
scenario, and a done definition. There is no hypothesis, constraint architecture, or task
decomposition.

1. If the input is an issue number, read it (`gh issue view <n>`) and record `Issue: #<n>`.
2. Draft the observed, expected, and impact lines from the report. Mark anything the
   report does not say as `[assumed]`.
3. Draft one regression scenario whose `Then` fails today. Add a second scenario only when
   the bug sits on a boundary and the neighbouring value must keep working.
4. Run one critique round, capped at three findings: is the expected behaviour actually
   agreed, is the regression scenario observable, and could the fix break a Must Not.
5. Run the gate with only the Clarity, Testability, Scope, and Self-containment checks.

If the "bug" turns out to be new behaviour nobody agreed on, say so and switch to critique
mode. A feature disguised as a bugfix skips the hypothesis and the constraints it needs.

## Critique mode

Work through the stages in order. Each stage ends when the human approves that artifact.
Don't move on while a finding is unresolved, unless the human explicitly defers it; log
deferred findings under *Open questions*.

Use this format for findings, so the human can answer by number:

```
1. [ambiguity] "Fast results" - fast for whom, measured where? Two implementers could pick
   different targets and both claim success. Suggest: name a percentile and a threshold.
2. [split] Export and scheduled email are two deliverable slices. Suggest: specify export first.
```

The tags are `ambiguity`, `assumption`, `missing`, `edge-case`, `split`, `hypothesis`,
`vague-scenario`, `conflict`, and `terminology`. Finish with one line asking which findings
they accept, reject, or want to change. Then show the refined artifact.

### 1. Intent description

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

### 2. User-facing behavior (BDD scenarios)

You draft this artifact; the human curates it. Once the intent is approved:

1. Generate Gherkin scenarios covering the primary success path, key error paths, and edge
   cases. Give each scenario one line on why it matters.
2. Ask the human what is missing. Then hunt for gaps yourself: boundary conditions,
   concurrent access, failure modes, and interactions with existing behavior.
3. Challenge vague scenarios. Flag any scenario that two implementations could both pass
   while showing users different behavior. Every `Then` must be something the user or the
   caller can observe, not internal state.

The human decides which scenarios stay. Your job is to make sure they considered more
scenarios than they would have alone.

### 3. Feature description (constraint architecture)

Ask for a short description of the current architecture, or read the relevant code if you
are in the repository. Then suggest what the human should decide and record:

- where the change fits, which components it touches, its integration points, and its
  dependencies
- **Musts** and **Must Nots**: the hard boundaries
- **Preferences**: soft defaults that the implementer may trade off
- **Escalation triggers**: conditions under which the implementer must stop and ask. Good
  candidates are decisions you noticed the human has not made yet, such as fail open or
  fail closed, or what to do if an upstream service does not expose a field.
- **Non-functional requirements** stated as constraints: latency, throughput, security,
  resource usage, and operations. For each one, explain why it matters for *this* change.
  These feed the acceptance criteria.

Reference the global system constraints you found in step 1 of "Start"; don't copy them.
The human makes the architectural decisions and sets the thresholds.

### 4. Acceptance criteria

- **Done definition**: observable outcomes that someone who has never seen the code could
  verify. Functional criteria come from the scenarios. Non-functional criteria come from
  the feature description.
- **Evaluation design**: test cases with known-good outputs (input → expected result),
  including the empty and failure cases.
- **Consistency**: check the criteria against the intent, scenarios, and feature
  description, and raise contradictions or gaps as findings.

Then add a short **task decomposition**. List the modules or tasks with explicit inputs and
outputs, each under about two hours of work. A single task is fine for a small slice.

## Discovery loop

Use this when there is nothing to critique yet. You act as a principal architect who
interviews the human to draw out context they didn't know was missing. Don't write any of
the spec until phase 3.

1. **Framing**: ask the human for the *outcome* they want, not the application they
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

## Decision log

Long conversations lose decisions in the middle of the context. As soon as the slice has a
name, create `specs/<slug>.md` with `Status: draft` and a `## Decision log` section. Tell
the human the path the first time. Append one line per decision as it is made (accepted
finding, rejected finding, chosen threshold, deferred question), and fill in each artifact
section once the human approves it. The log is your source when you redraft. Don't rely on
memory of the conversation.

## Validation gate

Before anyone generates a test or writes code, review all four artifacts together. Each
one can look fine alone and still contradict the others. Report each check as `pass` or
with numbered findings:

| Check           | Question                                                                         |
| --------------- | -------------------------------------------------------------------------------- |
| Clarity         | Could two developers read the intent differently?                                |
| Testability     | Does every scenario have a clear, observable outcome?                            |
| Scope           | Does the feature description constrain the work to what the intent needs, without over-engineering? |
| Terminology     | Is each concept named the same way in all four artifacts?                        |
| Completeness    | Does the intent imply any behavior that has no scenario?                         |
| Conflict        | Does anything in one artifact contradict another?                                |
| Hypothesis      | Is there a way to validate it after deployment, using data that will exist?      |
| Self-containment | Could an agent implement from these documents alone, with no questions?         |

The human gates on this review. Resolve each finding through the critique cycle; the
lower-authority artifact changes by default. A finding the human explicitly chooses to live
with goes under *Open questions* as an accepted risk. Don't mark the spec ready, and don't
write the feature file, while a finding is still open. A conflict caught here costs minutes.
The same conflict caught during implementation costs a session.

## Output and hand-off

When the gate passes:

1. Finalize `specs/<slug>.md` from the template, and set `Status: ready`.
2. Write `feature/<slug>.feature` with the approved scenarios. This is the file `tdd:red`
   reads. The spec links to it and does not repeat it, so the two can't drift apart.
3. If the project already uses a different convention (`features/`, `docs/specs/`, and so
   on), follow it and tell the human.

Finish with a short message that gives the two paths, the deferred *Later slices*, and the
next step: `/start-session specs/<slug>.md`. That command commits the spec, creates the
branch, and runs the orchestrator with the spec as its feature description and the scenarios
as its plan. Don't start implementation or test generation yourself unless the human asks.
