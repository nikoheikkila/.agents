# .agents

A version-controlled home for [Claude Code](https://claude.ai/code) and GitHub Copilot CLI configuration: slash commands, skills, and
plugins. The repo is public because both clients install plugins from a GitHub marketplace, not from a local working copy.

## Installation

Add the marketplace once, then install whichever plugins you need:

```bash
/plugin marketplace add nikoheikkila/.agents
/plugin install alt-text-generator@nikoheikkila-agents
/plugin install agentic-cd@nikoheikkila-agents
```

The `agentic-cd` plugin replaces the old `tdd` plugin. If you installed that, remove it with
`/plugin uninstall tdd@nikoheikkila-agents`.

Installed plugins are pinned to a commit SHA, so a change pushed to this repo isn't picked up automatically. Update
with:

```bash
/plugin marketplace update nikoheikkila-agents
/plugin install <name>@nikoheikkila-agents
```

### GitHub Copilot CLI

The same marketplace and plugins install unchanged in [Copilot CLI](https://docs.github.com/copilot/concepts/agents/copilot-cli/about-cli-plugins):

```bash
copilot plugin marketplace add nikoheikkila/.agents
copilot plugin install agentic-cd@nikoheikkila-agents

# after a change is pushed
copilot plugin marketplace update nikoheikkila-agents
copilot plugin update agentic-cd
```

In Copilot, commands such as `/start-session` load as skills, and agents keep the `agentic-cd:` prefix. Copilot
ignores the per-agent `model` and `effort` settings and the `Agent(...)` spawn allowlists, so agents run on the
session's model.

To develop either client against the working copy, use `--plugin-dir ./plugins/<name>`, then run
`scripts/check-plugins.sh` before pushing.

## Available Plugins

### `alt-text-generator`

Generates screen-reader-compatible alt text for images.

- Skill `generating-alt-text` — invoke directly as `/alt-text-generator:generating-alt-text` for interactive use, or
  let it trigger automatically on prompts like "write alt text for this image" or "is this accessible for screen
  readers?"
- Agent `alt-text-generator` — a noninteractive subagent (no clarifying questions, no preamble) that reads an image
  and returns alt text, intended for use by other agents or automation rather than direct chat.

### `agentic-cd`

The whole agentic continuous-delivery workflow in one plugin (the old `tdd` plugin is deprecated and removed; its
skills live here now). Everything is invoked as `/agentic-cd:<name>`, and the bare name works while it is unambiguous.

- Commands: `start-session`, `end-session`, `fix`, `reflect`.
- Skills: `specify`, `review`, `gherkin`, `mutation-testing` (called by `/end-session`), and the TDD phase skills
  `tdd-red`, `tdd-green`, `tdd-refactor` (preloaded by the phase agents; `/agentic-cd:tdd-red` etc., formerly `/tdd:red`).
- Agents: `orchestrator`, `tdd-red`, `tdd-green`, `tdd-refactor`, `review-orchestrator`, `semantic-review`,
  `security-review`, `performance-review`, `concurrency-review`.

The sections below describe each part. Paths such as `commands/start-session.md` are relative to
`plugins/agentic-cd/`.

## Commands

`commands/reflect.md` → `/reflect` — a post-session maintenance loop. It reviews the current session for friction and
writes durable improvements back into the relevant repo: repo-wide instructions into `AGENTS.md`/`CLAUDE.md`,
human-facing docs into `README.md`, and skill amendments under `.claude/skills/` (or, when run inside this repo,
under this repo's own `skills/`/`plugins/`).

The review gate is the skill `skills/review` (invoked as `/review`); see [How the gate converges](#how-the-gate-converges).
The commands here drive the agentic-CD pipeline in `agents/`, starting from a spec written with the `specify`
skill:

- `commands/start-session.md` → `/start-session <spec | #issue | bug>` — commits the spec, creates the feature
  branch, and loops: the `orchestrator` runs up to three `tdd-red` → `tdd-green` → `tdd-refactor` cycles, `/review`
  gates the chunk, and the chunk is committed. A bug report without a spec goes through `specify`'s bugfix mode
  first.
- `commands/end-session.md` → `/end-session` — checks that everything is committed and the base pipeline is green,
  pushes, opens the pull request with deferred findings and accepted risks from the ledger, and watches the run.
- `commands/fix.md` → `/fix [run URL | run id | failing command]` — reads the failed CI log, classifies the failure, routes
  code and config failures to the `orchestrator`, reruns flakes once, and reviews, commits, and pushes the fix.

`/start-session` and `/end-session` carry `disable-model-invocation: true` — type those yourself. `/review` and `/fix`
stay model-invocable, because `/start-session` runs `/review` for every chunk and a red pipeline should pull in `/fix`
without being asked. Session state survives `/clear` in a ledger under the git directory
(`skills/review/scripts/ledger.sh`, reached through `${CLAUDE_PLUGIN_ROOT}`).

## Agentic CD Workflow

The commands, skills, and subagents below form one loop. Humans own the start (the spec) and the end (acceptance and
push); agents own everything between, one small chunk at a time.

```mermaid
sequenceDiagram
  autonumber
  actor Human
  participant Main as 🤖 Main Agent
  participant Orchestrator as 🤖 Orchestrator
  participant TDD as 🤖 TDD Red, Green, Refactor
  participant Review as 🤖 Review Orchestrator
  participant Reviewers as 🤖 Reviewer Agents

  Human->>Main: /specify
  loop Refinement
    Main->>Human: Critique and refine
    Human->>Main: Decide
  end
  Main->>Human: Spec & features

  Human->>Main: /start-session
  Main->>Main: Commit spec, create branch

  loop Each chunk
    Main->>Orchestrator: Implement chunk
    loop Up to 3 steps: acceptance test or TDD cycle
      Orchestrator->>TDD: Red, then Green, then Refactor
      TDD->>Orchestrator: Tests pass
    end
    Orchestrator->>Main: Checkpoint

    loop Up to 3 rounds
      Main->>Review: /review
      Review->>Reviewers: Diff, in parallel
      Reviewers->>Review: Findings
      Review->>Main: Pass or block
      opt Blocking findings
        Main->>Orchestrator: Fix with TDD, then delta review
      end
    end
    Main->>Main: Commit chunk
  end

  Human->>Human: Review and test
  Human->>Main: /end-session
  Main->>Main: Push, open pull request

  loop Until pipeline is green
    Main->>Main: Watch pipeline
    opt Pipeline failed
      Main->>Main: /fix (at most twice)
    end
  end
```

1. **Specify.** The human runs `/specify` to create and refine the spec artifacts: the intent, the BDD scenarios, the
   feature description, and the acceptance criteria. A spec holds exactly one scenario, which becomes the
   acceptance test of the ATDD loop. The human then approves a plan of at most six TDD cycles that make it pass.
   Each step lists the existing tests it affects, found with `grep`.
2. **Start the session.** The human runs `/start-session` to start working on the spec. The main agent commits the
   spec, creates the branch, and begins the chunk loop.
3. **Gather context.** The main agent invokes `orchestrator`, which assembles the minimum context for the chunk: the
   feature description, the next one to three steps of the plan (the acceptance test or a TDD cycle), the files
   they touch, and the prior checkpoint.
4. **Red.** In the first chunk, `tdd-red` writes the failing acceptance test for the scenario, and the
   orchestrator marks it strictly expected-to-fail. In each cycle, `tdd-red` writes one failing unit test.
5. **Green.** The orchestrator runs the test itself and confirms it fails on an assertion, then invokes `tdd-green` to
   make it pass with the minimum code.
6. **Refactor.** The orchestrator confirms the suite is passing, then invokes `tdd-refactor` to clean the code up. It
   repeats steps 4–6 for each cycle, up to three steps per chunk, then returns a checkpoint to the main agent. When
   a cycle makes the acceptance test pass, its marker trips and is removed, and the spec is done.
7. **Review gate.** The main agent runs `/review`, which delegates to `review-orchestrator`.
8. **Parallel review.** `review-orchestrator` invokes `security-review`, `performance-review`, `semantic-review`, and
   `concurrency-review` in parallel and returns a single pass/block decision.
9. **Fix findings.** If there are blocking findings, the main agent triages them and delegates them to the
   orchestrator, which fixes them in TDD cycles. A delta review follows, at most three rounds in total. When the gate
   passes, the cheap in-scope advisories are fixed, the rest are deferred to the pull request, and the main agent
   commits the chunk, stops that chunk's orchestrators, and starts the next chunk with a new one.
10. **Human review.** Once the acceptance test passes and is committed, the human reviews and tests the outcome.
11. **End the session.** The human runs `/end-session`, which pushes the changes and opens the pull request.
12. **Watch the pipeline.** The main agent monitors the CI/CD pipeline. If it fails, it runs `/fix`, which classifies the
    failure, routes it to the orchestrator, then reviews, commits, and pushes the fix, at most twice.

## Subagents

`plugins/agentic-cd/agents/` holds a nine-agent pre-commit pipeline adapted from the
[MinimumCD agentic-CD guide](https://beyond.minimumcd.org/docs/agentic-cd/architecture/agent-configuration/).
`orchestrator` is the entry point — ask it to start working on an implementation from a plan,
and it assembles the minimum context, writes the spec's acceptance test, and runs the planned TDD cycles until it
passes:

| Agent          | Phase                                         | Model  | Effort |
| -------------- | --------------------------------------------- | ------ | ------ |
| `tdd-red`      | Write one failing acceptance or unit test     | sonnet | low    |
| `tdd-green`    | Write the minimum code to make it pass        | opus   | high   |
| `tdd-refactor` | Simplify the design while keeping tests green | opus   | medium |

Each phase agent returns one minimal JSON object — `status` (`done`, `concern`, or `context_needed`) plus
repo-relative paths and the test command, never file contents or logs — so the orchestrator's context stays small.
The orchestrator never edits a file itself: tests and behaviour go through the three phase agents, and anything
else (config, manifests, docs) goes to a `general-purpose` subagent. Its Bash use is limited to running tests and git.
Between phases the orchestrator re-runs each agent's test command itself, reading only the exit code and a short tail, and it hashes the Red test files so a
later phase that edits a test is caught and re-run. The phase agents preload the matching `agentic-cd` skill, which ship in the same plugin.

After each chunk of up to three steps the orchestrator stops at the review gate rather than crossing it:
`/start-session` runs `/review`, which invokes `review-orchestrator`, which runs `semantic-review`, `security-review`,
`performance-review`, and `concurrency-review` in parallel and returns a single pass/block decision as JSON.
`/start-session` commits the chunk only when that decision is `pass` and the index still matches the tree the gate
passed.

### How the Gate Converges

- Findings are `blocking` or `advisory`. Only a finding that names a concrete `failure_scenario` in the code as
  written is blocking, and `review-orchestrator` derives the decision from the severities. Advisory findings never
  block. The cheap in-scope ones are fixed before the commit and the rest are listed for the pull request description.
- Round 1 reviews the whole staged diff. Later rounds review only the delta since the previous round, checking that
  the earlier blockers closed and nothing new broke. After round 3 the remaining findings go to the user.
- The skill's `scripts/review-diff.sh [--delta]` prepares each round's diff: it writes it to a file
  (lockfiles excluded) and records the index tree and HEAD for the next delta. Reviewers read the file, so the diff
  can be any size. `--mark-pass` records the tree a passing gate saw, and `--check-pass` refuses a commit whose index
  has changed since.
- Before every gate the orchestrator runs the production build and the end-to-end command. The acceptance test
  crosses the real boundary, and the plan puts the cycle that meets it early. Facts only the real environment shows are cheaper to meet
  there than as a blocking finding.
- An orchestrator run is a chunk of at most three TDD cycles that ends in a JSON checkpoint. `/start-session`
  checks each claim against the files (`git status --short`, the tests and the acceptance marker it names, and the
  test command's exit code), then gates and commits the chunk and stops its orchestrators. Answers the user gives
  go into the ledger and on to every orchestrator that is resumed or started after them.
- A `review-orchestrator` that returns before all four reviewers finish is resumed, not replaced. A replacement
  repeats the round, and a second `--delta` on the same index produces an empty diff.

They are plugin agents, so their types are namespaced (`agentic-cd:tdd-red`, and so on), and the
`Agent(...)` allowlists in their frontmatter use those names.

Only `orchestrator` is meant to be invoked directly; the other eight expect a context bundle from their parent
and will not gather one themselves.

## Skills

The `review` skill (`/agentic-cd:review`) prepares the staged diff with its bundled `scripts/review-diff.sh`, spawns
`review-orchestrator`, triages blocking findings, and runs up to three rounds (full, then delta). On a pass it fixes
the cheap, in-scope advisory findings (stale docs, dead code, missing tests) before the commit and defers the rest.

The plugin skills are delivered by the plugin. The remaining skills in `skills/` reach Claude Code through one
whole-directory symlink, created once:

```sh
ln -s ../.agents/skills ~/.claude/skills
```

`skills/synced/` is written by the claude.ai skill sync and is git-ignored.

### Vendored Skills

`skills/accessibility`, `skills/performance`, and `skills/find-skills` were installed with the
[Skills CLI](https://github.com/vercel-labs/skills) from `addyosmani/web-quality-skills` and `vercel-labs/skills`, and
are tracked in `.skill-lock.json`.

Do not hand-edit these — a future `npx skills update` will overwrite local changes. To check for or pull updates:

```bash
npx skills check    # see which vendored skills have updates
npx skills update    # pull them, rewriting skills/ and .skill-lock.json
npx skills add <owner/repo@skill> -g -y   # install a new one globally
```

If a vendored skill needs a real change, either contribute it upstream or fork it into `plugins/` under a different
name so it becomes authored content instead.

## Authoring a New Plugin

1. Create `plugins/<name>/.claude-plugin/plugin.json` with `name`, `version`, `description`, `author`.
2. Add an entry for it in the root `.claude-plugin/marketplace.json` (`name`, `source: "./plugins/<name>"`,
   `description`).
3. Add content directories inside the plugin: `skills/<skill-name>/SKILL.md`, `agents/<agent>.md`, etc.

A plugin skill's frontmatter `name` must match its directory name, and it's invoked as `<plugin>:<skill>`. Skill
frontmatter descriptions are written as trigger lists in third person ("Use when the user asks…") rather than
summaries, so Claude Code can match them against a user's phrasing. Subagent frontmatter pins `tools`, `model`,
`skills`, and `effort` explicitly, and delegates its substance to a skill rather than restating it. Agents meant for
noninteractive use say so explicitly and forbid clarifying questions and preamble, since either would corrupt the
caller's output.

Push and update the marketplace to make a plugin change visible (see [Install](#installation) above).

## Conventions

- Commit messages follow [Conventional Commits](https://www.conventionalcommits.org/) (`feat:`, `docs:`, `chore:`).
- See `CLAUDE.md` for the fuller set of authoring rules Claude Code itself follows when editing this repository.
