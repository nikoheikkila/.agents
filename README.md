# .agents

A version-controlled home for [Claude Code](https://claude.ai/code) configuration: slash commands, skills, and
plugins. The repo is public because Claude Code installs plugins from a GitHub marketplace, not from a local working copy.

## Installation

Add the marketplace once, then install whichever plugins you need:

```text
/plugin marketplace add nikoheikkila/.agents
/plugin install alt-text-generator@nikoheikkila-agents
/plugin install tdd@nikoheikkila-agents
```

Installed plugins are pinned to a commit SHA, so a change pushed to this repo isn't picked up automatically. Update
with:

```
/plugin marketplace update nikoheikkila-agents
/plugin install <name>@nikoheikkila-agents
```

## Available Plugins

### `alt-text-generator`

Generates screen-reader-compatible alt text for images.

- Skill `generating-alt-text` — invoke directly as `/alt-text-generator:generating-alt-text` for interactive use, or
  let it trigger automatically on prompts like "write alt text for this image" or "is this accessible for screen
  readers?"
- Agent `alt-text-generator` — a noninteractive subagent (no clarifying questions, no preamble) that reads an image
  and returns alt text, intended for use by other agents or automation rather than direct chat.

### `tdd`

Skills for the Red-Green-Refactor test-driven development cycle:

- `red` — write a failing test first, driven from Gherkin/BDD feature files, before any implementation exists.
- `green` — implement the minimal code needed to make a failing test pass, without over-engineering.
- `refactor` — improve code quality and design once tests are green, without changing behaviour.

Invoke as `/tdd:red`, `/tdd:green`, `/tdd:refactor`, or let them trigger on natural mentions of starting a TDD cycle,
making a test pass, or cleaning up passing code.

## Commands

`commands/reflect.md` → `/reflect` — a post-session maintenance loop. It reviews the current session for friction and
writes durable improvements back into the relevant repo: repo-wide instructions into `AGENTS.md`/`CLAUDE.md`,
human-facing docs into `README.md`, and skill amendments under `.claude/skills/` (or, when run inside this repo,
under this repo's own `skills/`/`plugins/`).

## Subagents

`agents/` holds a seven-agent pre-commit pipeline ported from the
[MinimumCD agentic-CD guide](https://beyond.minimumcd.org/docs/agentic-cd/architecture/agent-configuration/).
`orchestrator` is the entry point — ask it to start a BDD session and it assembles the minimum context and
delegates to `implementation` for one scenario at a time. It then stops at the review gate rather than crossing
it: `/review` invokes `review-orchestrator`, which runs `semantic-review`, `security-review`,
`performance-review`, and `concurrency-review` in parallel and returns a single pass/block decision as JSON.
The orchestrator holds the commit until that decision is `pass`.

They reach Claude Code through a whole-directory symlink, created once:

```sh
ln -s ../.agents/agents ~/.claude/agents
```

Only `orchestrator` is meant to be invoked directly; the other six expect a context bundle from their parent
and will not gather one themselves.

## Vendored Skills

`skills/accessibility`, `skills/performance`, and `skills/find-skills` were installed with the
[Skills CLI](https://github.com/vercel-labs/skills) from `addyosmani/web-quality-skills` and `vercel-labs/skills`, and
are tracked in `.skill-lock.json`. They reach Claude Code via per-skill symlinks into `~/.claude/skills/`.

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
