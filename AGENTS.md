# CLAUDE.md

## What This Repository Is

`~/.agents` is a version-controlled home for agent configuration: slash commands, skills, and plugins. There is no
application code, no build, no test suite, and no CI — content is Markdown with YAML frontmatter plus a few JSON
manifests. "Correctness" means the frontmatter is valid and the delivery path (symlink or plugin marketplace) actually
resolves. `scripts/check-plugins.sh` checks both for every plugin: it runs `claude plugin validate` and fails if
Copilot CLI's skill loader reports `failed to load`. Run it before pushing a plugin change.

Remote: `git@github.com:nikoheikkila/.agents.git`. The repo is public because Claude Code and Copilot CLI install
plugins from GitHub, not from this working copy.

## Two Delivery Mechanisms — Know Which One You Are Editing

Each top-level directory reaches Claude Code a different way. Getting this wrong means an edit that appears correct but
never loads.

| Directory  | Reaches the agent via                                                                                  | Authoring rule                                                           |
| ---------- | ------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------ |
| `skills/`  | Whole-directory symlink `~/.claude/skills -> ../.agents/skills`                                        | Vendored: do not hand-edit. Authored skills live in `plugins/agentic-cd` |
| `plugins/` | GitHub marketplace `nikoheikkila-agents`, installed into `~/.claude/plugins/cache/` and by Copilot CLI | Own authored work goes here; requires push + update                      |

### `Skills/` Is Mostly Vendored

`skills/synced/` is written by the claude.ai skill sync. It is account-specific, not authored here, and git-ignored.
Never edit or commit it. The rest of this section is about the vendored skills.

Useful commands (from the `find-skills` skill):

```bash
npx skills check                          # see which vendored skills have updates
npx skills update                         # pull them, rewriting skills/ and .skill-lock.json
npx skills add <owner/repo@skill> -g -y   # install a new one globally
```

### `Plugins/` Is the Authored Surface

Every plugin needs three things in agreement:

1. `plugins/<name>/.claude-plugin/plugin.json` — `name`, `version`, `description`, `author`.
2. An entry in the root `.claude-plugin/marketplace.json` listing `name`, `source: "./plugins/<name>"`, `description`.
3. Content directories inside the plugin: `skills/<skill-name>/SKILL.md`, `agents/<agent>.md`.

A plugin skill's frontmatter `name` must equal its directory name, and it is invoked as `<plugin>:<skill>`.

```bash
git push
claude # then: /plugin marketplace update nikoheikkila-agents
       #       /plugin install <name>@nikoheikkila-agents
copilot plugin marketplace update nikoheikkila-agents
copilot plugin update <name>
```

To try a change before pushing, load the working copy directly: `claude --plugin-dir ./plugins/<name>` or
`copilot --plugin-dir ./plugins/<name>`.

### One Source for Claude Code and Copilot CLI

Copilot CLI reads Claude Code plugins without conversion. It finds `.claude-plugin/marketplace.json` and
`.claude-plugin/plugin.json` and loads `skills/` and `agents/`. It also loads `commands/*.md` as skills. Plugin agents
get the same `agentic-cd:<name>` namespace in both clients. Keep a single tree. Do not add a second manifest or a
`com.github.copilot/` overlay unless Copilot rejects a file outright. Copilot drops some fields silently, so follow
these rules:

- **Skill `description` ≤ 1024 characters.** Copilot refuses to load a longer one; Claude Code accepts it, so only
  the check script catches it.
- **`${CLAUDE_PLUGIN_ROOT}` is not expanded by Copilot** in command or skill bodies. Next to every use, state a
  fallback path relative to the file, e.g. "(if that variable is not expanded, `../skills/review/scripts/` relative
  to this file)".
- **Copilot ignores `Agent(<name>)` in `tools`.** It ignores every tool name it does not recognize. Append
  `custom-agent` to any agent that spawns subagents. Copilot maps that to its agent tool, and Claude Code ignores it,
  so the `Agent(...)` allowlist still applies in Claude Code. In Copilot the allowlist is advisory only, through the
  agent body.
- **Copilot ignores `skills:` preload.** An agent body must name the skill and say to load it if it is not
  already in context.
- **Copilot ignores `model:`, `effort:` and `allowed-tools` patterns.** It falls back to the session model and its
  own permission prompts, so the model tiers above are enforced in Claude Code only.

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
- In `allowed-tools`, a leading-wildcard rule with the legacy `:*` suffix (`Bash(*/x.sh:*)`) matches nothing; write
  `Bash(*/x.sh *)`, or `Bash(*/x.sh*)` when the script also runs without arguments. `auto` mode hides a dead rule,
  so verify with `claude -p "<prompt>" --permission-mode acceptEdits --output-format json` and check
  `permission_denials`. Put the prompt before `--allowedTools`, which is variadic and swallows it.
- Commit messages follow Conventional Commits (`feat:`, `docs:`, `chore:`).

## `/reflect`

`plugins/agentic-cd/commands/reflect.md` is the maintenance loop for this repo and others: after a session, record friction as
repo-wide instructions in `AGENTS.md`, human-facing docs in `README.md`, and skill amendments under `.claude/skills/`.
When run here, amendments belong in this repo's own `skills/` or `plugins/` per the routing table above.
