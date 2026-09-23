# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repository Is

`~/.agents` is a version-controlled home for agent configuration: slash commands, skills, and plugins. There is no
application code, no build, no test suite, and no CI — content is Markdown with YAML frontmatter plus a few JSON
manifests. "Correctness" means the frontmatter is valid and the delivery path (symlink or plugin marketplace) actually
resolves.

Remote: `git@github.com:nikoheikkila/.agents.git`. The repo is public because Claude Code installs plugins from GitHub,
not from this working copy.

## Three Delivery Mechanisms — Know Which One You Are Editing

Each top-level directory reaches Claude Code a different way. Getting this wrong means an edit that appears correct but
never loads.

| Directory   | Reaches the agent via                                                               | Authoring rule                                          |
| ----------- | ----------------------------------------------------------------------------------- | ------------------------------------------------------- |
| `commands/` | Whole-directory symlink `~/.claude/commands -> ../.agents/commands`                 | Edit freely; live immediately, no install step          |
| `skills/`   | Per-skill symlinks `~/.claude/skills/<name> -> ../../.agents/skills/<name>`         | **Vendored third-party — do not hand-edit** (see below) |
| `plugins/`  | GitHub marketplace `nikoheikkila-agents`, installed into `~/.claude/plugins/cache/` | Own authored work goes here; requires push + update     |
| `agents/`   | Whole-directory symlink `~/.claude/agents -> ../.agents/agents`                     | Edit freely; live immediately at next session start     |

### `Skills/` Is Vendored, Not Authored

`accessibility`, `performance`, and `find-skills` were installed with the Skills CLI (`npx skills`) and are tracked in
`.skill-lock.json` with a `skillFolderHash` per skill. Local edits will be clobbered by `npx skills update`. Upstream
sources are `addyosmani/web-quality-skills` and `vercel-labs/skills`. If a change is needed, either contribute upstream
or fork the skill into `plugins/` under a different name.

Useful commands (from the `find-skills` skill):

```bash
npx skills check                          # see which vendored skills have updates
npx skills update                         # pull them, rewriting skills/ and .skill-lock.json
npx skills add <owner/repo@skill> -g -y   # install a new one globally
```

### `Agents/` Is the Agentic-CD Pipeline

Seven user-level subagents ported from the
[MinimumCD agentic-CD guide](https://beyond.minimumcd.org/docs/agentic-cd/architecture/agent-configuration/):
`orchestrator` routes an implementation session and spawns `implementation`, which writes one scenario test-first.
The review gate is separate: `/review` invokes `review-orchestrator`, which fans out to `semantic-review`,
`security-review`, `performance-review`, and `concurrency-review`. The orchestrator never spawns the review
orchestrator — it stops at the gate and hands off.

Two rules keep them honest when editing:

- **Model tiers are prescribed by the source doc**, not chosen freely — haiku for the two orchestrators and
  performance, sonnet for concurrency, opus for implementation, semantic, and security. Changing one is a
  deliberate deviation from the guide.
- **Every agent pins `tools`.** The review agents get `Read` only, so "you do not modify code" is enforced
  rather than merely requested; the orchestrators use the `Agent(<name>)` allowlist to declare exactly which
  subagents they may spawn. The chain sits at the default three-layer nesting limit, so
  `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH` below 3 breaks the review gate.

Descriptions do double duty as routing rules: only `orchestrator` invites delegation, and the other six say
they are invoked by a named parent and need a pre-assembled diff they will not collect themselves.

### `Plugins/` Is the Authored Surface

Every plugin needs three things in agreement:

1. `plugins/<name>/.claude-plugin/plugin.json` — `name`, `version`, `description`, `author`.
2. An entry in the root `.claude-plugin/marketplace.json` listing `name`, `source: "./plugins/<name>"`, `description`.
3. Content directories inside the plugin: `skills/<skill-name>/SKILL.md`, `agents/<agent>.md`.

A plugin skill's frontmatter `name` must equal its directory name, and it is invoked as `<plugin>:<skill>`.

Publishing a plugin change is not just a commit: the installed copy is pinned to a `gitCommitSha` in
`~/.claude/plugins/installed_plugins.json`, so changes are invisible until pushed and pulled back down:

```bash
git push
claude # then: /plugin marketplace update nikoheikkila-agents
       #       /plugin install <name>@nikoheikkila-agents
```

## Conventions

- Skill frontmatter descriptions are written as trigger lists in third person ("Use when the user asks…"), enumerating
  the phrasings that should activate the skill, not summarizing what it does.
- Command files take the same frontmatter, minus `name` and `paths`: the filename is the command. Always set
  `description` — without it Claude Code falls back to the first content line, so a body opening with a `## /command`
  heading leaves the command with its own name as its description and nothing to route on. Side-effecting commands
  (`/start-session`, `/end-session`) set `disable-model-invocation: true`; the rest stay model-invocable so handoffs
  like `orchestrator` → `/review` still fire.
- Subagent frontmatter pins `tools`, `model`, `skills`, and `effort` explicitly (see
  `plugins/alt-text-generator/agents/alt-text-generator.md`); agents delegate their substance to a skill rather than
  restating it.
- Agents intended for non-interactive use say so and forbid clarifying questions and preamble, because a question or a
  wrapper sentence corrupts the caller's output.
- Commit messages follow Conventional Commits (`feat:`, `docs:`, `chore:`).

## `/reflect`

`commands/reflect.md` is the maintenance loop for this repo and others: after a session, record friction as
repo-wide instructions in `AGENTS.md`, human-facing docs in `README.md`, and skill amendments under `.claude/skills/`.
When run here, amendments belong in this repo's own `skills/` or `plugins/` per the routing table above.
