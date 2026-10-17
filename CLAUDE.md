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

| Directory   | Reaches the agent via                                                               | Authoring rule                                      |
| ----------- | ----------------------------------------------------------------------------------- | --------------------------------------------------- |
| `commands/` | Whole-directory symlink `~/.claude/commands -> ../.agents/commands`                 | Edit freely; live immediately, no install step      |
| `skills/`   | Whole-directory symlink `~/.claude/skills -> ../.agents/skills`                     | Vendored: do not hand-edit. Authored: `review`, `specify`, `gherkin` |
| `plugins/`  | GitHub marketplace `nikoheikkila-agents`, installed into `~/.claude/plugins/cache/` | Own authored work goes here; requires push + update |
| `agents/`   | Whole-directory symlink `~/.claude/agents -> ../.agents/agents`                     | Edit freely; live immediately at next session start |

### `Skills/` Is Mostly Vendored

`review` is an authored skill: the pre-commit review gate, with its `scripts/review-diff.sh` in the skill's
`scripts/` directory. It is not in `.skill-lock.json`, so `npx skills update` should leave it alone. Since 2026-10-03,
`~/.claude/skills` is one symlink to this directory, so a new skill directory loads without any per-skill link.

`skills/synced/` is written by the claude.ai skill sync. It is account-specific, not authored here, and git-ignored.
Never edit or commit it. The rest of this section is about the vendored skills.

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

Nine user-level subagents adapted from the
[MinimumCD agentic-CD guide](https://beyond.minimumcd.org/docs/agentic-cd/architecture/agent-configuration/):
`orchestrator` routes an implementation session and, for each scenario, spawns `tdd-red` (failing test),
`tdd-green` (minimum code), and `tdd-refactor` (simplest design) in sequence.
The phase agents preload the `tdd:red`, `tdd:green`, and
`tdd:refactor` skills from `plugins/tdd`, so that plugin must be installed for them to load their rules.
The review gate is separate: `/review` invokes `review-orchestrator`, which fans out to `semantic-review`,
`security-review`, `performance-review`, and `concurrency-review`. The orchestrator never spawns the review
orchestrator and never commits. It returns a gate-ready checkpoint per chunk, and `/start-session` runs `/review`
and commits that chunk.

Two rules keep them honest when editing:

- **Model tiers are prescribed by the source doc**, not chosen freely — haiku for the review orchestrator and
  performance, sonnet for concurrency, opus for semantic and security. Changing one is a deliberate deviation
  from the guide. Two exist: the TDD split (sonnet/low for `tdd-red`, opus/high for `tdd-green`, opus/medium for
  `tdd-refactor`), and `orchestrator` on sonnet/medium instead of haiku.
- **Every agent pins `tools`.** The review agents get `Read` only, so "you do not modify code" is enforced
  rather than merely requested; the orchestrators use the `Agent(<name>)` allowlist to declare exactly which
  subagents they may spawn. The chain sits at the default three-layer nesting limit, so
  `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH` below 3 breaks the review gate.

Descriptions do double duty as routing rules: only `orchestrator` invites delegation, and the other eight say
they are invoked by a named parent and need a pre-assembled diff they will not collect themselves.

### The Review Gate Has to Converge

- **`block` needs a `failure_scenario`.** Every finding carries `severity: blocking | advisory`, and only a
  finding that names a concrete input or state and the wrong outcome in the code as written is `blocking`.
  `review-orchestrator` sets `decision` itself from the severities and ignores the `decision` an agent returned.
  Advisory findings never block. On a pass, the cheap in-scope ones (stale docs, dead code, a missing test for
  stated behaviour) get one fix round and a delta review before the commit. The rest go into the pull request
  description.
- **Rounds are full, then delta, at most three.** The skill's `scripts/review-diff.sh` writes the diff to a file (lockfiles
  excluded, because an 80 KB diff does not fit in a prompt) and records the index tree and HEAD; `--delta` produces
  only what the fixes changed, and falls back to a full diff once HEAD has moved. On a pass, `--mark-pass` records
  the passed tree, and the committer runs `--check-pass` so nothing staged after the review gets committed. Delta rounds check that each previous blocker closed and that the delta added nothing
  new. Round 3 still blocking goes to the user, not to a fourth round.
- **The caller triages before routing.** Verify each blocking finding against the code or the platform docs, drop
  the ones whose scenario does not hold, and batch the ones that need a product decision into one question. The
  accepted-risk list travels with every round so a settled concern is not raised again.
- **Move the real-environment facts left.** The orchestrator orders scenarios boundary-first (the thinnest slice
  that runs across the real CI, service, or runtime boundary comes first), adds risk scenarios (empty input,
  each failure path reported once, untrusted text in markup, temp resources), and runs the production build and
  end-to-end command before it hands off to the gate.
- **An orchestrator run is a chunk, not a session.** At most three TDD cycles or one fix round per run, ending in
  a JSON checkpoint with `git_status` and `not_done`. The caller verifies the checkpoint, so a claim like "fixed"
  is only as good as the evidence attached to it. Each chunk is reviewed and committed on its own.

### The Session Loop

`/specify` writes `specs/<slug>.md` (`Type: feature | bugfix`, with a short bugfix mode) and the feature file.
`/start-session <spec>` commits the spec, creates `feat/` or `fix/<slug>` unless the repo is trunk-based, then
loops chunk → `/review` → commit, and sets the spec to `Status: done` with the last chunk. `/end-session` commits
nothing: it pushes, opens the pull request from the ledger, and watches the run. `/fix` classifies a red run
(`test`, `build`, `lint`, `config`, `environment`, `flaky`), routes the first four through the orchestrator, and
reviews, commits, pushes, and watches the fix, at most twice.

Session state lives in `skills/review/scripts/ledger.sh`: an append-only log per slug in
`$(git rev-parse --git-dir)/agentic/`, so it survives `/clear` without touching the working tree. The commands
reach both scripts as `~/.claude/skills/review/scripts/`, which depends on the whole-directory `skills/` symlink.

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
