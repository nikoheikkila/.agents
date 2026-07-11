---
name: tdd-red
description: >-
  Guide test-first development by writing failing unit tests from Gherkin (BDD) feature files
  that describe desired behaviour before any implementation exists. Use when starting a new
  TDD cycle, writing the first test for a feature, or when the user mentions writing a failing test.
---

# TDD Red Phase - Write Failing Tests First

Focus on writing clear, specific and failing unit tests from Gherkin (BDD) feature files that describe the desired behaviour before any implementation exists.

## Gherkin (BDD) Overview

Simple Gherkin example:

```bdd
Feature: Authentication

  Scenario: Successful login with valid credentials
    Given a user with username "user" and password "password"
    When the signs in with username "user" and password "password"
    Then the user should be signed in successfully
```

## Feature-to-Test Mapping

Translate above Gherkin scenario into a unit test. Note the newlines between Given, When, Then sections for clarity.

Example in TypeScript:

```ts
let userRepository: FakeUserRepository;
let client: Client;

test('signs in with valid credentials', () => {
    const user = new User("user", "password");
    userRepository.add(user);

    const response = await client.post("/login", {
      username: user.username,
      password: user.password
    });

    expect(response.status_code).toBe(HttpStatus.OK);
});
```

Example in Python:

```python
def test_successful_login(user_repository: FakeUserRepository, client: Client):
    user = User(username="user", password="password")
    user_repository.add(user)

    response = client.post("/login", data={
      "username": user.username,
      "password": user.password
    })

    assert response.status_code == HttpStatus.OK
```

## Feature Context Analysis

- **Fetch feature details** read and study the prompted files matching glob pattern `feature/*.feature` files comprehensively
- **Understand the full context** from feature scenario description, preconditions (Given), actions (When), and expected outcomes (Then)
- **Requirements extraction** - Parse the scenario acceptance criteria
- **Edge case identification** - Review feature scenarios for boundary conditions

## Core Principles

### Test-First Mindset

- **Write the test before the code** - Never write production code without a failing test.
- **One test at a time** - Focus on a single behaviour or requirement from the feature, never write more than one test at once.
- **Fail for the right reason** - Ensure tests fail due to a missing implementation, not syntax errors.
- **Be specific** - Tests should clearly express what behaviour is expected per feature requirements.

### Test Quality Standards

- **Descriptive test names** - Use clear, behaviour-focused test naming:

    ```ts
    describe('User', () => {
        test('can sign in with valid credentials', () => {
            // Test implementation here
        });
    });
    ```

- **Given-When-Then Pattern** - Structure tests with clear Given, When, Then sections without denoting these explicitly with comments. Use newlines to separate sections.
- **Assertion focus** - Each test should verify the specific outcomes from Then & And keywords.

### Test Library Patterns

- Use readable assertions with strict matching (e.g. `expect().toBe()` and `expect().toStrictEqual()`) as much as possible.
- Use custom fixture functions to provide faked test data
- Use `test.each` for generating data-driven tests.

### Test Isolation & Independence

- **Self-contained setup and teardown** - Each test manages its own state.
- **Avoid shared mutable state** - Never share data between tests.

### Mock/Stub Strategy

- **Prefer real objects when possible** - For side effect free logic, always use actual implementations.
- **Fake external dependencies only** - Substitute access to databases, APIs, file systems, and third-party services with faked test doubles.
- **Keep test doubles simple** - Only fake what's necessary for the test scenario. The less fake code needed, the better.

### Test Data Management

- **Fixture factories** - Use factory patterns for complex object creation from Given clauses.
- **Builder patterns** - Consider builders for objects with many optional fields.
- **Data proximity** - Keep test data close to tests for readability.
- **Shared fixtures** - Place common fixtures in own module such as `fixtures.ts` or `fixtures.py`.
- **Shared preconditions** - Convert Gherkin `Background` sections to fixture functions.

### Scenario Priority & Ordering

1. **Cover happy paths first** - Ensure successful scenarios from feature files come first.
2. **Error scenarios next** - Handle exception and error conditions.
3. **Edge cases last** - Cover boundary behaviors and unusual inputs.

### Scenario Outlines and Examples

- **Parametrized tests** - Map `Scenario Outline` with `Examples` to `test.each`.
- **Match placeholders** - Ensure parameter names match Given/When/Then variables.
- **Clear test IDs** - Use meaningful test IDs for each example case.

Example in TypeScript:

```ts
test.each([
    ["valid_user", "valid_pass", HttpStatus.OK],
    ["invalid_user", "wrong_pass", HttpStatus.UNAUTHORIZED],
])("login scenarios for %s", (username: string, password: string, expected: HttpStatus) => {
    // Implement test logic here
});
```

Example in Python:

```python
@pytest.mark.parametrize(("username", "password", "expected"), [
    ("valid_user", "valid_pass", HttpStatus.OK),
    ("invalid_user", "wrong_pass", HttpStatus.UNAUTHORIZED),
])
def test_login_scenarios(username: str, password: str, expected: HttpStatus):
    # Implement test logic here
```

### Error Message Quality

- **Clear failure messages** - Assertions should explain what specific behavior failed.
- **Reference requirements** - Error messages should cite feature file expectations.
- **Custom assertion messages** - Use `expect(fn).toThrow()` and `with pytest.raises()` for testing exceptions.

Example in TypeScript:

```ts
expect(() => authenticateUser("invalid_user", "wrong_pass")).toThrow("Invalid credentials provided");
```

Example in Python:

```python
with pytest.raises(AuthenticationError, match="Invalid credentials provided"):
    authenticate_user("invalid_user", "wrong_pass")
```

### Test Organization

- **File naming** - Use `feature_name.test.ts` or `test_<feature_name>.py` converting sentences to snake_case.
- **Group related scenarios** - Keep scenarios from same feature file together.

### Anti-Patterns to Avoid

- **Tests that pass immediately** - Defeats the Red phase purpose. Tests must always FAIL on first run.
- **Skipping verification** - Always run tests to confirm they fail for the correct reason.
- **Testing implementation details** - Focus on behavior, not internal implementation details.
- **Vague assertions** - Use specific checks with expected values.
- **Multiple behaviors per test** - One test should verify one scenario.
- **Hidden dependencies** - All test dependencies should be explicit.
- **Brittle tests** - Avoid tests that break when refactoring.

## Execution Guidelines

1. **Read Gherkin Feature Files** - Extract and retrieve full context from `feature/*.feature` files.
2. **Analyze requirements** - Break down the feature into testable behaviors.
3. **Confirm your plan with the user** - Ensure understanding of requirements and edge cases. Never start making changes without user confirmation.
4. **Write the simplest failing test** - Start with the most basic scenario from the feature. Write it under the test directory. Never write multiple tests at once.
5. **Verify the test fails** - Run the tests to confirm it fails for the expected reason. Missing test data or syntax errors are never an acceptable reason for failure, only assertion errors are acceptable.
6. **Link test to feature file** - Reference feature file name in test docstrings.

## Red Phase Checklist

- [ ] Gherkin feature file context retrieved and analyzed.
- [ ] Test clearly describes expected behaviour from feature requirements.
- [ ] Test fails for the right reason (assertion errors only, no compile errors).
- [ ] Test name references feature file name and describes behaviour.
- [ ] Test follows Given, When, Then pattern.
- [ ] Test is isolated and independent (no shared state).
- [ ] Only external dependencies are substituted with test doubles.
- [ ] Test data setup is clear and maintainable.
- [ ] Error messages are descriptive and reference requirements.
- [ ] Test organization follows naming conventions.
- [ ] Only modifications in test files. No production code written.
