---
name: obsidian
description: >-
  Create, find, read, update and delete notes in the user's personal Obsidian vault at ~/Vaults. This is the
  one entrypoint for anything involving "my notes". Use it whenever the user wants to write something down
  ("make a note", "jot this down", "add a todo", "remind me to…", "put this in my journal"), look something up
  in their notes ("what did I write about…", "find my notes on…", "what's on my task list", "what did I do last
  week"), change a note (append, edit, tag, tick a task, rename, move), or remove one ("delete that note", "trash
  it"). Trigger even when Obsidian or the vault isn't named. "My notes", "my journal", and "today's tasks"
  all mean this vault, from any working directory. Not for Obsidian plugin or theme development,
  Bases (.base) files, or Markdown docs that belong in a code repository.
---

# Obsidian Vault

This skill is the front door to the user's personal Obsidian vault: capture, retrieval, editing and removal of
notes. It encodes the user's own preferences for how much to ask, where things go, and which tool to use for
each job.

## Orient First

- **Vault root:** `~/Vaults`, a symlink to `~/Library/Mobile Documents/iCloud~md~obsidian/Documents` (synced
  through iCloud). Work only through `~/Vaults` and never scan both trees. File tools need absolute paths, so
  expand `~` to the home directory.
- **Conventions live in `~/Vaults/CLAUDE.md`.** If it isn't already in your context (it is when the session
  started inside the vault), read it before writing anything. It is the source of truth for layout, front
  matter, tags and file names. This skill adds the CRUD workflow on top. The one deliberate difference is the
  confirmation policy below, which the user chose specifically for this skill and which replaces CLAUDE.md's
  "confirm each step".
- **Today's date:** get it from `date +%F` instead of assuming it. Journal file names depend on it.

Layout in brief: `000 - Inbox/` holds new notes and the daily journal (`Journal/YYYY-MM-DD.md`, older entries in
`Journal/Archive/`). `001 - Home/` holds personal notes, `002 - Work/` holds work notes by topic,
`003 - Read Later/` holds Instapaper highlight exports, and `004 - Templates/` holds note templates.

## Safety: There Is No Undo

The vault is not a git repository and iCloud syncs every change to the user's other devices within seconds, so a
bad write spreads and cannot be rolled back. That is why these rules hold:

- **Never overwrite when creating.** Check that the target path doesn't exist first.
- **Never `rm`, and never `obsidian delete permanent`.** "Delete" means moving the note into `~/Vaults/.trash/`
  with `mv -n`.
- **Read a note in full before editing it, and edit surgically** with the Edit tool rather than rewriting the
  file. Untouched content should stay byte-identical.
- **Leave alone** `.obsidian/`, `.agents/`, `.claude/`, `CLAUDE.md` and `skills-lock.json`. Never edit anything
  inside `.trash/`; moving a note into it is the only exception.
- **Quote every path** in shell commands. Note names contain spaces, `&`, `|`, `'` and `—`.

## When to Ask First

The user picked this balance: capture should be frictionless, but anything that could destroy or rearrange
existing material gets a preview first.

**Do it, then report:**

- Creating a new note or a journal entry
- Appending or prepending content, or adding a section, task, tag, or property
- A precise change the user dictated exactly, such as "tick off the passport task" or "change bench press to
  25 kg". The request already is the plan, so a preview adds nothing.

**Show the plan and wait for an okay:**

- Rewording, restructuring, summarising, or removing existing text
- Any change that spans several notes
- Renaming or moving a note
- Deleting a note (moving it to `.trash/`)

Keep the plan short. List the paths, a before and after excerpt of the affected lines, and, for rename, move, or
delete, how many notes link to the target. Don't paste the whole note.

When a request mixes both kinds, do the safe part right away and ask about the rest in the same reply.

## Which Tool for Which Job

| Job            | Use                                                          | Why                                                                                      |
| -------------- | ------------------------------------------------------------ | ---------------------------------------------------------------------------------------- |
| Find and read  | `rg` over the vault, then the Read tool                      | Fast, works without the app. `rg` skips hidden folders such as `.trash` and `.obsidian`. |
| Create         | Write tool on the full path, after checking it doesn't exist | No escaping problems. The CLI's `content=` mangles backslashes and long text.            |
| Edit or append | Edit tool                                                    | Surgical, so the rest of the note stays untouched.                                       |
| Rename or move | `obsidian rename` or `obsidian move`                         | Obsidian rewrites incoming links (`alwaysUpdateLinks` is on). Plain `mv` breaks them.    |
| Delete         | `mv -n` into `~/Vaults/.trash/`                              | Matches the vault's `trashOption: local`, and `-n` never overwrites.                     |

### `rg` recipes

```bash
cd ~/Vaults && rg --files | rg -i 'kubernetes|k8s'      # match file names
cd ~/Vaults && rg -i -l 'kubernetes|k8s'               # notes that mention it
cd ~/Vaults && rg -i -n -C2 'kubernetes' '002 - Work'  # with context, in one folder
cd ~/Vaults && rg -n '^\s*- \[ \]'                      # open tasks
```

### Obsidian CLI

- The CLI needs the desktop app running. Check with `obsidian vault=Documents vault info=name 2>/dev/null`. It
  prints `Documents` when the app is reachable.
- Pass `vault=Documents` as the first argument, because otherwise the CLI guesses the vault from the working
  directory. Append `2>/dev/null`, because every call prints harmless Electron `FATAL … Unable to find helper
app` lines on stderr.
- The exit status is always 0, so read the output to tell whether the command worked.
- Paths are relative to the vault root, for example `path="002 - Work/Meetings/OP Monthly.md"`.
- This build has no `daily:*` commands, and the core daily-notes format is set to `[Week]-W`. Handle the journal
  with plain files as described below.

## Create

### Journal or Standalone Note?

**Today's journal** is for quick captures: tasks, reminders, to-dos, a one- or two-line thought, or something that
happened today. For example: "note that I need to renew my passport", "remind me to send the November invoice",
or "remember to book a dentist appointment".

**A standalone note** is for topic-shaped material worth finding again by its title: meeting notes, a talk, book
or article summary, a how-to, a list the user will keep adding to, anything multi-paragraph, or whenever the
user says "a note about", "a note called" or "a new note".

If it's genuinely unclear, pick one, do it, and say in one line where it went. A wrong guess costs one follow-up,
but asking every time adds friction to every capture.

### Journal Entry

The path is `~/Vaults/000 - Inbox/Journal/<YYYY-MM-DD>.md`. Use today's date unless the user names another day,
such as "add to Monday's journal". If the file doesn't exist, create it in exactly this shape:

```markdown
---
id: 2026-11-14
aliases: []
tags:
  - daily-notes
---

## Tasks

- [ ] Renew passport before Christmas
```

- Add tasks and reminders as `- [ ] ` items at the end of the `## Tasks` list. If the heading is missing, add it
  at the top of the body.
- Add other quick notes as bullets under `## Notes` at the end of the file, creating that heading if needed. If
  today's note already has a heading the entry clearly belongs under, such as `## Renovate (week 46)`, add it
  there instead.
- Keep the user's wording and language. Phrase a task as an action, without adding detail the user didn't give.

### Standalone Note

1. **Title:** a short, human-readable title in the user's language, in Title Case like the existing notes (for
   example `Gym Weights` or `Code Craft & AI`). Avoid `/ \ : # ^ [ ] |` and a leading dot, because they break
   file systems or wikilinks. If the title contains a dot, that's fine for the file tools.
2. **Folder:** `000 - Inbox/`, unless the user names a folder or points at an existing one (for example, "in my
   work meetings folder" means `002 - Work/Meetings/`). The user triages the Inbox themselves, so don't guess a
   topic folder. Resolve a named folder against the real tree with
   `cd ~/Vaults && find . -type d -not -path '*/.*' | sort`.
3. **Collision check:** confirm the exact path doesn't exist, and look for near-duplicates with
   `rg --files | rg -i '<key words>'`. If the exact title exists, don't overwrite it. Tell the user, and offer to
   append to the existing note instead, which is probably what they want. If a closely related note exists,
   create the new one anyway and mention the related note in your report.
4. **Front matter:** usually just `tags` in YAML list form, with one to three lowercase tags. Concatenate
   multi-word tags (`continuousdelivery`) and reuse existing tags before inventing new ones. List them with
   `obsidian vault=Documents tags counts sort=count 2>/dev/null`, or without the app with
   `cd ~/Vaults && rg --no-filename -A8 '^tags:' | rg -o '^  - \S+' | sort | uniq -c | sort -rn`. Add `url` and
   `author` only when the content has a source. Most notes have nothing more, so don't add `created`, `title` or
   similar properties.
5. **Body:** the user's content, lightly structured with `##` headings, bullets and tasks. Nested lists use tabs
   in this vault. Link to existing notes with `[[wikilinks]]` when that's natural.

**Write down what the user gave you.** Don't pad notes with background, summaries or "key takeaways" the user
didn't say. The vault is the user's own record, and invented content quickly becomes indistinguishable from what
they actually know or observed. Tidying grammar and structure is fine. If the user explicitly asks you to draft
or research something for the note, do it and say so.

**Templates:** if the user asks for a kind of note that has a template in `004 - Templates/` (currently interview
templates with `date` and `candidate` properties), start from the template. Copy its content and fill in its
properties.

**Read Later** notes are Instapaper exports. Create one there only when asked, following the existing format:
`url`, `date` and `author` front matter, then `>` blockquoted highlights.

## Read and Find

1. **Search broadly before you conclude nothing exists.** Search file names and content.
   Matches in filenames count as much as matches in text.
2. **Read promising notes in full** rather than answering from grep snippets. Most notes are short, and snippets
   miss context such as the dated heading a bullet sits under.
3. **Answer first, then cite** the vault-relative paths the answer came from, with the heading or date where it
   helps. Quote only when the exact wording matters.
4. **Keep the notes separate from general knowledge.** The user is asking about their own record. If the notes
   don't cover something, say so plainly, and label any general knowledge you add.
5. **Time-based questions** ("what did I do last week", "what was on my list on Monday"): journal files in
   `000 - Inbox/Journal/` and `Journal/Archive/` are named by date, so filter by name. Dated headings inside notes
   also count, for example `## 5.11.2024` (Finnish D.M.YYYY) in meeting notes.
6. **Open tasks:** `rg -n '^\s*- \[ \]'`, grouped by note, with journal tasks grouped by date.

Reading never modifies anything.

## Update

1. **Locate the note.** If several notes match, list them and ask which one. Don't guess when the action is a
   write.
2. **Read the whole note**, then classify the change using "When to ask first".
3. **Apply the change with the Edit tool**, preserving the front matter style (YAML lists, never inline arrays
   with values), lowercase tags, the note's language, its indentation and heading levels, and everything you
   weren't asked to touch.

Common edits:

- **Add to a section:** insert at the end of that heading's section, not at the end of the file.
- **Tick a task:** change `- [ ]` to `- [x]` on exactly that line.
- **Add a tag:** extend the `tags:` list, creating front matter if the note has none.
- **Rename or move:** run `obsidian vault=Documents rename path="<path>" name="<New Title>"` or
  `obsidian vault=Documents move path="<path>" to="<folder>/"`, then confirm the new path exists with `ls`.
  If the app isn't running, ask the user to open Obsidian. If they'd rather not, use `mv -n`, then find and fix
  links yourself with `rg -l -F '[[Old Title'`. Cover the `[[Old Title]]`, `[[Old Title|alias]]` and
  `[[Old Title#heading]]` forms. Internal links are rare in this vault, so there's usually nothing to fix, but
  check.

## Delete

1. **Locate the exact file.** Show its path, a line or two of its content, and its incoming links. Find those
   with `rg -l -F '[[<Title>'` and `rg -l -F '<Title>.md'`, excluding the note itself. Say whether it holds
   anything of lasting value.
2. **Wait for explicit confirmation.**
3. **Move it:** `mv -n "$HOME/Vaults/<path>" "$HOME/Vaults/.trash/"`. Notes from nested vaults such as
   `002 - Work/` also go to the root `.trash/`. Then confirm the original is gone and the file is in `.trash/`.
   If a file with the same name is already in `.trash/`, `mv -n` silently does nothing. In that case, offer to
   trash the note as `<Title> (YYYY-MM-DD).md` instead.
4. **Tell the user** they can restore it by moving it back out of `~/Vaults/.trash/`, and mention any links left
   broken.

Removing part of a note, such as a section, a line or finished tasks, is an edit that removes text. Preview it
and wait for confirmation, then use Edit. For bulk cleanup of empty notes, suggest the vault's `/prune` command,
which is available when Claude is started inside the vault.

## Report Back

End every operation with a short confirmation: what changed, and the vault-relative path. For reads, give the
answer and its sources. Don't echo a whole note back after writing it.
