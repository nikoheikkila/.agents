---
name: gherkin
description: Write, rewrite, and critique Gherkin (BDD) scenarios so that each one reads as a clear, declarative, independently runnable example of one behaviour. Use whenever user-facing behaviour is being drafted as Given/When/Then, including stage 2 and bugfix regression scenarios of the `specify` skill; when the user asks to write, fix, tidy, review, or lint a `.feature` file, a Scenario, a Scenario Outline, a Background, or Examples table; when they ask whether a scenario is "good Gherkin", too long, too imperative, or should be split; and when acceptance criteria or a ticket need converting to Given/When/Then. Covers only the Gherkin language and scenario style. Not for deciding which behaviours a change needs (specify), writing step definitions or test code from a feature file (tdd:red), or configuring a BDD framework.
---

# Gherkin

Write Gherkin that a person who has never seen the feature can read and understand, and
that an implementer can automate without guessing. This skill covers the language: how a
scenario is shaped, how steps are phrased, and which keyword fits which job. It does not
decide _which_ behaviours to specify. When the `specify` skill is running, it owns that
decision and the critique cycle, and this skill owns how each scenario is written.

The guidance follows Andy Knight's [Automation Panda BDD series](https://automationpanda.com/bdd/).
For keyword syntax (tables, doc strings, `Rule`, tags, formatting), read
`references/keywords.md`. For a full before/after rewrite of a bad scenario, read
`references/rewrites.md`.

## The Two Rules Everything Else Serves

1. **The Golden Rule: write for a reader who does not know the feature.** A scenario is a
   specification first and a test second. If a product owner, a new teammate, or an agent
   with no other context cannot tell what behaviour it pins down, the scenario has failed.
2. **The Cardinal Rule: one scenario, one behaviour.** A scenario that walks through
   several behaviours is a procedure, not a specification. It fails for many reasons, takes
   longer to triage, and leaves gaps between the behaviours it touches. If you can't name
   the behaviour in a short title, it is probably more than one.

## Shape of a Scenario

- **Given → When → Then, once each, in that order.** Given sets the starting state, When
  performs the one action under test, and Then checks the outcome. `And` and `But` continue
  whichever step type came before them. Gherkin doesn't enforce the order, but a scenario
  that goes back to Given after a Then, or has a second When/Then pair, almost always holds
  a second behaviour. Split it. Don't relabel a step to get the order right, such as turning
  an action into a Given.
- **A second When/Then pair is a smell, not a syntax error.** One action can take two
  steps, for example submitting a form and then confirming a modal. In that case use
  `When ... And ...` with one Then block. A long end-to-end journey is rarely the right
  thing for a spec. Write the small scenarios first.
- **Each scenario starts from its own state.** A scenario must not depend on another
  scenario having run first. If the image search scenario needs search results to exist,
  write `Given search results for "panda" are shown` and don't rely on the search scenario
  having run first. The step definition can do the setup behind the scenes.
- **Keep scenarios under 10 steps.** Single digits is the target. A longer scenario is
  either imperative (see below) or covers more than one behaviour.
- **`Or` keyword does not exist.** Steps run in sequence. A step that means "either of these" is a
  Scenario Outline with one row per alternative.

## Phrasing Steps

- **Declarative, not imperative.** Describe intent and outcomes, not the clicks, keystrokes,
  URLs, selectors, waits, SQL, or HTTP mechanics that get there. Imperative steps break with
  every UI change and hide the behaviour under the procedure. `When the user searches for
"panda"`, not eight steps that scroll, click, type each letter, and press Enter. Name the
  mechanism only when it _is_ the behaviour. A scenario about an API's status codes may say
  `the response status is 429`. A scenario about checkout should not mention `POST /cart`.
- **Third person, every step, every scenario.** Write `the user`, `the admin`, `the
client`, `the system`, or a named persona. Don't write `I`. First person ties a step to an
  unstated speaker with unstated permissions. Steps are reused across files, and mixed
  points of view make them conflict. If the project already writes everything in first
  person consistently, follow it. A mix of the two is always wrong.
- **Present tense, all steps.** `Given the cart contains 3 items` / `When the user checks
out` / `Then the order confirmation is shown`. Present tense is short and timeless.
  Avoid `should`, `will`, and past-tense actions. `Then the response status is 429` states a
  fact the test checks, and `should be` only hedges it.
- **Givens are states, not actions.** `Given the user is logged in`, not `Given the user
logs in`. An action verb in a Given usually means the action belongs in When, or that the
  Given is imperative.
- **Whole sentences with a subject and a predicate.** Avoid fragments like
  `And video links for "panda"`. A fragment reads ambiguously and gets misused when the step
  is reused. Don't pack several actions or checks into one step with "and". Use another
  `And` step instead.
- **Every Then is observable from outside.** The user, the caller, or another system must
  be able to see it. `Then it works`, `Then the data is saved`, or `Then the cache is
updated` are not observable. Say what the outside world sees: what is displayed, what is
  returned, and what a later request finds.
- **Put parameters in double quotes.** `When the user searches for "panda"`. Quotes make
  the variable part of a step easy to spot, and that helps step reuse.
- **One vocabulary.** Name each domain concept the same way in every step and every file
  (`order`, never `order` in one place and `purchase` in another). When `specify` is
  running, the terms must also match the intent and feature description.

## Titles

A scenario title is a one-line statement of the behaviour. Titles show up in test reports,
so a reader should understand a failure from the title alone.

- Say _what_ happens, not _why_. Leave out `because`, `since`, and `so`. Put the reason in
  a comment if it matters.
- Leave out `verify`, `should`, `assert`, and `test that`. They add nothing to every title,
  and they put the focus on the check instead of the behaviour.
- `and` or `or` in a title signals two behaviours, or an outline in disguise.
- A title that is hard to write means the scenario is not focused yet. Fix the scenario.

| Weak                                                              | Strong                                  |
| ----------------------------------------------------------------- | --------------------------------------- |
| Verify the user can change their address on the profile page      | Profile page address change             |
| The goodbye page should be displayed after a successful logout    | Logout displays the goodbye page        |
| User logs in, opens profile, and sees name, address, phone, email | The profile page shows personal details |

## Data in Scenarios

- **Use concrete, realistic values that carry meaning.** For example, `"500kb-sheet.xlsx"`
  for a size boundary, or `100 requests in the current minute` for a rate limit. Avoid
  `foo`, `test`, or `lorem`, unless the behaviour is about invalid input. Include only the
  data that the behaviour depends on. Leave everything else to the step definitions.
- **Name long or volatile values.** `Given the user is on their profile page`, not a
  URL. `And links related to "panda" are shown`, not a hard-coded list of live search
  results, which fails when the data changes and not when the behaviour breaks.
- **Make time relative.** Write `the "to" date is three days from today`, not
  `2026-10-20`.
- **Environment and secrets never go in steps.** Base URLs, browsers, hosts, usernames,
  and passwords come from configuration. A tag can select a configured account.

## Choosing the Right Keyword

Full syntax is in `references/keywords.md`. In short:

- **Background**: only for Given steps that every scenario in the file shares, and only a
  few of them. It runs before each scenario. If one scenario doesn't need it, it doesn't
  belong in the Background. A long Background hides the starting state from the reader.
- **Scenario Outline + Examples**: for one behaviour that holds across a few
  _equivalence classes_, such as each side of a boundary. Every row must cover a case that
  the other rows don't. Two rows from the same class add run time and no information. When
  the rows behave the same, a plain Scenario with one good example is clearer. A wide
  table (many columns) usually means the scenario is imperative, or that two behaviours
  share one outline. Collapse related fields into a named class (`the "<address-type>"
address`), or split the outline.
- **Data table** on a step: for a list or record that one step needs, as an alternative to
  a chain of `And` steps that each add one item.
- **Doc string** (`"""`): for multi-line text a step needs verbatim, such as an email body
  or a JSON payload. Use it only when the exact text is the behaviour.
- **Rule**: groups the scenarios that illustrate one business rule inside a feature. Use it
  when a feature file has several distinct rules. Leave it out for a small slice with one
  rule.
- **Tags** and **comments**: for filtering runs, linking issue IDs, and recording the
  occasional reason. They don't replace clear steps.

## Feature Files

- One `Feature` per file, named after the customer need it serves, not after a screen or a
  ticket. The free-text description under `Feature:` holds the one-line intent or user
  story.
- Keep a file to about a dozen scenarios. A larger file is usually two features.
- Formatting: indent with two spaces under each header. Capitalize keywords and the first
  word of titles, but not the rest of the step. Don't end steps with periods. Put one blank
  line between scenarios and no blank lines between steps. Align table pipes. Keep lines
  under about 120 characters. Spell correctly, because the file is documentation.

## Workflow

### Drafting from Intent or Acceptance Criteria

1. Name each behaviour in one short title before you write any steps. Each title is one
   scenario. If you can't title it, it isn't one behaviour yet.
2. For each title, write the single When first: the one action whose affect you are
   pinning down. Then write the Then outcomes a reader can observe. Last, write the
   smallest set of Givens that makes the outcome inevitable.
3. Replace mechanics with intent, check person, tense, and vocabulary, and move shared
   Givens into a Background only if every scenario uses them.
4. Collapse near-duplicate scenarios into an outline only when the rows are distinct
   equivalence classes.
5. Run the checklist below before you show the result.

### Critiquing Existing Scenarios

Run the checklist and report findings, not a silent rewrite. The scenarios' author has to
see what changed and why. Group the findings by severity. Problems that change meaning or
coverage come first: Cardinal Rule violations, difficult to observe Then's, hidden dependencies,
and an imperative procedure that hides the behaviour. Mechanical style problems come
second: tense, person, formatting, and titles. Batch the style problems into one,
so they don't bury the problems that matter.

Inside `specify`, use its numbered finding format and tags. A Cardinal Rule violation is
`split`. An imperative, ambiguous, or a difficult to observe step is `vague-scenario`. An
inconsistent noun is `terminology`. A scenario that depends on another scenario is
`assumption`. The style batch is one `vague-scenario` finding. When the agent drafts
scenarios under `specify`, apply the style rules directly, because the draft is the agent's
own. When the human wrote the scenarios, propose changes and don't rewrite them unasked.

### Checklist

- [ ] Each scenario has one behaviour, a short title, and one When/Then pair, in G-W-T order.
- [ ] No scenario depends on another scenario's side effects.
- [ ] Fewer than 10 steps per scenario. Declarative, with no clicks, selectors, or URLs, and
      no endpoints or SQL unless that layer is the behaviour.
- [ ] Third person and present tense throughout. Givens are states. No `should` or `will`.
- [ ] Every Then is observable by the user or caller.
- [ ] Values are concrete and meaningful, time is relative, and there is no config or
      secrets.
- [ ] The Background holds only Givens that every scenario shares.
- [ ] Each Examples row is a distinct equivalence class, and the table is narrow.
- [ ] Each concept has one name, and parameters are in double quotes.
- [ ] Formatting: two-space indent, no trailing periods, aligned pipes, one feature per file.
