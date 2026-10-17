# Gherkin Keyword Reference

Language facts come from the [Cucumber Gherkin reference](https://cucumber.io/docs/gherkin/reference/).
The usage guidance comes from Automation Panda's
[Gherkin Language](https://automationpanda.com/2017/01/26/bdd-101-the-gherkin-language/),
[Gherkin by Example](https://automationpanda.com/2017/01/27/bdd-101-gherkin-by-example/), and
[Writing Good Gherkin](https://automationpanda.com/2017/01/30/bdd-101-writing-good-gherkin/).

## Contents

1. Feature
2. Rule
3. Background
4. Scenario (Example)
5. Steps: Given, When, Then, And, But, `*`
6. Scenario Outline (Scenario Template) and Examples
7. Data tables
8. Doc strings
9. Tags
10. Comments
11. Formatting
12. A complete file

## 1. Feature

The first keyword in the file, and there is one per file. The title is one line. The free
text after it is a description that the parser ignores, and it holds the intent or user
story.

```gherkin
Feature: Search rate limit
  Authenticated clients get at most 100 search requests per minute, so one client can't
  slow search down for everyone else.
```

A feature is a customer need, such as "Search rate limit". It is not a screen
("Search page") or a single action ("Click search"). Creating something and reading it
back belong in the same feature, because reading is how creation is verified.

## 2. Rule

Gherkin 6 and later. It is optional, and it groups the scenarios that illustrate one
business rule. A `Rule` may have its own Background, which runs after the feature's
Background.

```gherkin
Feature: Search rate limit

  Rule: A client over its limit is refused until the window resets

    Scenario: The 101st request in a minute is refused
      ...

  Rule: Each client's limit is independent

    Scenario: A limited client does not affect another client
      ...
```

Use `Rule` when a feature has two or more distinct rules and the grouping helps the reader.
Leave it out for a feature with a single rule. Check that the project's runner supports it,
because older runners reject the keyword.

## 3. Background

Steps that run before **each** scenario in the feature (or in the `Rule`), not once per
file. A Background has no title and appears once per feature or rule.

```gherkin
Background:
  Given the client "acme" is authenticated
```

Put only Given steps in it, keep it to a few lines, and include a step only when every
scenario below it needs that step. A reader should be able to keep the Background in mind
while reading any scenario.

## 4. Scenario (Example)

`Scenario` and `Example` are synonyms. A scenario is one concrete example of one
behaviour, and it runs independently of the others.

## 5. Steps

| Keyword | Job                                                  | Phrasing                                                    |
| ------- | ---------------------------------------------------- | ----------------------------------------------------------- |
| `Given` | Starting state before the action                     | A state: `Given the cart contains 3 items`                  |
| `When`  | The one action under test                            | An action by a named actor: `When the user checks out`      |
| `Then`  | The observable outcome of that action                | A fact: `Then the order confirmation is shown`              |
| `And`   | Continues the previous step type                     | Same rules as the step type it continues                    |
| `But`   | Same as `And`, but reads as a contrast               | `But the related results do not include "pandemonium"`      |
| `*`     | Bullet-style step, which takes the previous step type | Rare in specifications. Prefer the explicit keyword         |

The parser matches a step to its definition by text, not by keyword. The keyword is for the
human reader, so use it honestly.

## 6. Scenario Outline and Examples

`Scenario Outline` (also written `Scenario Template`) runs once per Examples row, with each
`<placeholder>` replaced by that row's value. An outline may have several `Examples`
blocks, each with its own name and tags, to group the classes.

```gherkin
Scenario Outline: Requests are refused only once the limit is reached
  Given the client has made <made> requests in the current minute
  When the client makes another search request
  Then the response status is <status>

  Examples: Under the limit
    | made | status |
    | 0    | 200    |
    | 99   | 200    |

  Examples: At the limit
    | made | status |
    | 100  | 429    |
```

Each row should be a different equivalence class. Here, 99 and 100 sit on either side of
the boundary, and 0 is the empty case. Adding 50 would add a test run and no information.
Several outlines in one file are fine. If the rows grow to a dozen, or the columns to more
than a few, Gherkin is the wrong place for that data.

## 7. Data tables

A table attached to one step and passed to its definition. The first row is usually the
header. Escape a literal pipe as `\|`.

```gherkin
Given the catalog contains these products
  | name        | price |
  | Panda plush | 19.90 |
  | Bamboo mug  | 12.50 |
```

An Examples table repeats the whole scenario. A data table gives one step a data
structure. Don't confuse the two.

## 8. Doc strings

Multi-line text passed to one step as a single string, delimited by `"""` (or by three
backticks). You can add a content type: `"""json`.

```gherkin
Then the confirmation email body is
  """
  Thanks for your order, Ada.
  Your 3 items ship within 2 working days.
  """
```

Use a doc string only when the exact text is the behaviour. Otherwise, state the property
that matters: `Then the confirmation email names the shipping time`.

## 9. Tags

Tags start with `@`, go on the line above `Feature`, `Rule`, `Scenario`, `Scenario Outline`,
or `Examples`, and are inherited downwards. Use them to filter runs and to attach hooks. Keep
the set small and standard, lowercase, and hyphenated: `@smoke`, `@issue-123`, `@wip`. Avoid
near-duplicates like `@automated` and `@automation`. A tag may select configuration, such as
`@admin-account`, which keeps credentials out of steps.

## 10. Comments

A comment is a whole line starting with `#`, and the parser ignores it. Use comments
sparingly, because steps and titles should explain themselves. A comment is a good place
for the _reason_ a scenario exists, which doesn't belong in its title.

## 11. Formatting

- Indent two spaces per level: `Feature` > `Rule` > `Background`/`Scenario` > steps >
  tables and doc strings.
- Capitalize keywords and the first word of titles. Step text stays lowercase except for
  proper nouns.
- Put no trailing punctuation on steps, and use single spaces between words.
- Put one blank line between scenarios and between Examples blocks. Put no blank lines
  between steps.
- Pad table cells so the pipes line up.
- Keep lines under about 120 characters.
- Name files in kebab case after the feature: `search-rate-limit.feature`.
- Also follow the project's existing feature files. Consistency within a repo beats any
  outside style.

## 12. A complete file

```gherkin
@search
Feature: Search rate limit
  Authenticated clients get at most 100 search requests per minute, so one client can't
  slow search down for everyone else.

  Background:
    Given the client "acme" is authenticated

  Scenario: A client under the limit is served and sees its remaining quota
    Given "acme" has made 50 search requests in the current minute
    When "acme" makes a search request
    Then the search results are returned
    And the remaining quota header shows 49

  Scenario: A client at the limit is refused with a retry time
    Given "acme" has made 100 search requests in the current minute
    When "acme" makes a search request
    Then the response status is 429
    And the Retry-After header gives the seconds until the window resets

  Scenario: A limited client does not affect other clients
    Given "acme" has made 100 search requests in the current minute
    And the client "globex" is authenticated
    When "globex" makes a search request
    Then the search results are returned
```

The first title contains "and", but it describes one outcome with two observable parts
(served, and quota shown). It is not two behaviours. Use judgement with the "and" test:
it flags titles for a second look, and it doesn't ban the word.
