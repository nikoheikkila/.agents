# Worked Rewrites

Each rewrite shows a common failure, names what is wrong, and gives the fixed form. They are
adapted from Automation Panda's
[Writing Good Gherkin](https://automationpanda.com/2017/01/30/bdd-101-writing-good-gherkin/),
[multiple When-Then pairs](https://automationpanda.com/2018/02/03/are-gherkin-scenarios-with-multiple-when-then-pairs-okay/),
and [#GivenWhenThenWithStyle](https://automationpanda.com/2021/03/08/solving-how-to-write-good-ui-interaction-tests-givenwhenthenwithstyle/).

## 1. A procedure with two behaviours

```gherkin
Scenario: Google search
  Given I open a web browser
  And I navigate to "https://www.google.com/"
  When I enter "panda" into the search bar
  Then links related to "panda" should be shown on the results page
  When I click on the "Images" link at the top of the results page
  Then images related to "panda" should be shown on the results page
```

The problems:

- There are two When/Then pairs, so there are two behaviours (search and image search).
- The steps are in first person.
- `should` hedges the outcomes.
- A URL and browser setup appear in the steps.

```gherkin
Scenario: Search from the search bar
  Given the Google home page is displayed
  When the user searches for "panda"
  Then links related to "panda" are shown

Scenario: Image search
  Given search results for "panda" are shown
  When the user switches to image results
  Then images related to "panda" are shown
```

The second scenario declares its own starting state, so it does not depend on the first
scenario having run.

## 2. Imperative UI steps

```gherkin
When the user scrolls the mouse to the search bar
And the user clicks the search bar
And the user types the letter "p"
And the user types the letter "a"
And the user types the letter "n"
And the user types the letter "d"
And the user types the letter "a"
And the user presses the ENTER key
```

This becomes one declarative step: `When the user searches for "panda"`. The step definition
owns the keystrokes, and a UI redesign changes only the definition, not the specification.

## 3. Mixed tense and fragments

```gherkin
Given the user navigated to the Google home page
When the user entered "panda" at the search bar
Then links related to "panda" will be shown on the results page
And image links for "panda"
```

```gherkin
Given the Google home page is displayed
When the user searches for "panda"
Then links related to "panda" are shown
And image links related to "panda" are shown
```

## 4. An "Or" step and a redundant outline

```gherkin
When the player pushes the "A" button
Or the player pushes the "B" button
Then the character jumps
```

Gherkin has no `Or`. Use an outline, with one row per alternative that actually differs:

```gherkin
Scenario Outline: Either action button makes the character jump
  When the player pushes the "<button>" button
  Then the character jumps

  Examples:
    | button |
    | A      |
    | B      |
```

If the input set grows to rows like `panda`, `koala`, `wombat`, and `sloth` that all
exercise the same code path, drop back to a single Scenario with one representative value.

## 5. A wide Examples table

```gherkin
Examples:
  | street       | line2    | city     | region | postcode | country |
  | 1 Main St    |          | Helsinki |        | 00100    | FI      |
  | 2 Side Rd    | Flat 3   | London   |        | SW1A 1AA | GB      |
  | 3 Elm Ave    |          | Austin   | TX     | 73301    | US      |
```

The reader doesn't need every field. What matters is the class of address:

```gherkin
When the user enters a "<address-type>" address
...
Examples:
  | address-type |
  | basic        |
  | two-line     |
  | with-region  |
```

The step definition maps each class to concrete data.

## 6. An unobservable Then and volatile data

```gherkin
Then the order is saved in the orders table
And the results are "Panda Express", "giant panda", "panda videos"
```

The first step checks internal state. The second fails whenever live data changes, even
when the behaviour still works.

```gherkin
Then the order appears in the user's order history
And links related to "panda" are shown
```

## 7. A bloated Background

```gherkin
Background:
  Given the user "ada" exists
  And "ada" is logged in
  And "ada" has a saved payment card
  And the catalog contains 20 products
  And the "SPRING" discount code is active
```

If only one scenario uses the discount code and two use the payment card, those steps
belong in those scenarios. Keep the Background to what every scenario needs, here
`Given "ada" is logged in`, so a reader can see each scenario's real starting state.

## 8. A regression scenario for a bug

Bug: "Exporting a report with an empty date range crashes with a 500."

```gherkin
Scenario: Exporting with an empty date range explains the problem
  Given the user is viewing the sales report
  And no date range is selected
  When the user exports the report
  Then the user is told to choose a date range
  And no file is downloaded
```

The Then states the expected behaviour that fails today. It does not state the crash
("no 500 error"), because a 400 with no message would satisfy that and still be wrong.
