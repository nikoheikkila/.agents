---
name: tdd-green
description: >-
  Implement minimal code to make failing unit tests pass without over-engineering.
  Use when there is a failing test that needs the simplest possible implementation
  to turn green, or when the user asks to make a test pass.
---

# TDD Green Phase - Make Tests Pass Quickly

Write the minimal code necessary to make unit tests provided by the user as a context to pass.

**Do not write any more code than required.**

## Mandatory Rules

- **Do not change the tests** - Never touch the unit test code during this phase.
- **Always stay in the scope** - Implement only what's required to make the test pass, avoid scope creep.
- **Minimum viable solution** - Focus on core requirements from the test.

## Core Principles

- **Fake it till you make it** - Start with hard-coded returns based on what the test expects, then generalize as needed.
- **Obvious implementation** - When the solution is clear from the test, implement it directly.
- **Green bar quickly** - Prioritize making tests pass over code quality, design, or optimization efforts.
- **Ignore code smells temporarily** - Duplication and poor design will be addressed in the refactor phase later.
- **Simple solutions first** - Choose the most straightforward implementation path.
- **Defer complexity** - Don't anticipate requirements beyond the current test scope.

## Implementation Strategies

- **Use the simplest language features** - Add crude if/else and for/while logic, don't use mapping, filtering, reducing or similar advanced array methods.
- **Use basic collection types** - Use simple arrays and objects over more complex data structures.

## Error Handling

- **Minimal exception handling** - Only handle exceptions if the test explicitly expects them.
- **Let failures propagate** - Don't add try/catch blocks unless required by the test.
- **Match expected errors** - Return exact error messages or types the test assertions check for.
- **No defensive programming** - Skip input validation unless tests demand it.

## Test Isolation & Execution

- **Run tests independently** - Ensure each test passes in isolation, not just as part of the full test suite.
- **No shared state** - Avoid using module-level state or global variables that could leak between tests.
- **Order independence** - Tests should pass regardless of execution order.
- **One assertion at a time** - If a test has multiple assertions, make them pass incrementally.

## File & Module Structure

- **Mirror test imports** - Create files exactly where the test expects to import from.
- **Match signatures exactly** - Function names, parameters, and return types must align with test calls.
- **Minimal imports** - Only import what's immediately needed to make the test pass.
- **No premature abstraction** - Keep code in the module under test, don't extract any helper modules.

## Transformation Priority Premise

Apply the simplest transformation that makes the test pass, in this order:

1. **{}->nil** - No code to `None`
2. **nil->constant** - Return a hard-coded value (e.g. string)
3. **constant->constant+** - Add another hard-coded value (e.g. number)
4. **constant->scalar** - Replace constant with a variable
5. **statement->statements** - Add more statements
6. **unconditional->if** - Add a conditional for handling branched logic
7. **scalar->array** - Use a collection
8. **array->container** - Use a more complex structure
9. **statement->recursion** - Add recursive logic (only if needed)

Start at the top. Never jump directly to complex solutions.

## Common Pitfalls to Avoid

- **No logging or printing statements** - Do not leave debugging statements around.
- **No comments or documentation strings** - Documentation belongs in the refactor phase.
- **No type hints** - Typing belongs in the refactor phase.
- **No premature optimization** - Brute force solutions are acceptable if they pass.
- **No extra validation** - Only validate what the test checks.
- **No configuration files** - Use hard-coded values instead.
- **No new dependencies** - Only use libraries already in test setup. Never install new packages.

## Handling Multiple Failing Tests

- **Pick the simplest first** - Start with the most basic or foundational test.
- **One test at a time** - Focus on making one test pass before moving to the next one.
- **Run frequently** - Execute tests after each small code change.

## External Dependencies

- **Honor test doubles** - Inject external dependencies only as the test requires.
- **No real or asynchronous I/O** - Don't access databases, files, or network layers to keep tests fast.
- **Hard-code external data** - Return fixed stub responses instead of calling external services.

## Success Criteria

- **All tests pass** - Green bar with all tests passing.
- **No test modifications** - Test files remain unchanged.
- **Fast execution** - Tests run quickly (seconds, not minutes).
- **Warnings are acceptable** - Warnings can be addressed in the refactor phase.
- **Minimal implementation** - Code does not do more than required.

## Execution Guidelines

1. **Review test requirements** - Confirm the test case is understood before implementation.
2. **Run the failing test** - Analyze exactly what needs to be implemented by running tests first.
3. **Write minimal code** - Add just enough code to make the test pass.
4. **Run all tests** - Ensure new code doesn't break existing functionality.

## Green Phase Checklist

- [ ] All tests are passing (green bar)
- [ ] No more code written than necessary for test scope
- [ ] Existing tests remain passing
- [ ] Implementation is simple and direct
- [ ] Test acceptance criteria satisfied
- [ ] The code is ready for the refactoring phase
