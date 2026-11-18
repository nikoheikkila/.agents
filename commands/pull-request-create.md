---
name: pull-request-create
description: Opens a draft pull request into GitHub and monitors the workflow run until completion.
---

The user wants to open a new draft pull request and monitor its workflow run.

## Tasks

1. If you're in `main` branch, create a new feature branch. Otherwise, use the current branch, and do **not** create a
   new one.
2. Commit the changes as per repository instructions and conventions.
3. Push the branch to remote.
4. Write a pull request summary using the pull request template if one exists.
5. Open a draft pull request with `gh pr create --draft --body "$summary"`, where `$summary` holds the text generated in
   previous step.
6. Wait until a new workflow run appears in `gh run list`
7. Using the run's ID, setup a monitor task with `gh run watch`
8. If the workflow run fails, investigate the root cause, fix it, commit, push, and loop back to step 6.
9. If the workflow run succeeds, report the task completion to user as described below.

## Output

Return the message below and nothing else:

```markdown
- Pull Request: <URL>
- Pipeline Status: Completed
```
