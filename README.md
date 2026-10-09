# RapScalYon Starter Kit for Claude Code

A Claude Code plugin of guardrails that cost nothing to run. Install once, globally; each project opts in.

| Hook | What it does |
|---|---|
| **Verify before finishing** (`Stop`) | Runs the project's own check commands before Claude is allowed to finish. A failure is handed back so work continues instead of ending on red. |
| **Archive before compaction** (`PreCompact`) | Keeps the full transcript before Claude's context is summarised, since decisions and rejected approaches are what summaries lose first. |

## Install

```
claude plugin marketplace add <path-or-git-url-of-this-repo>
claude plugin install rapscalyon-starter-kit@rapscalyon-starter-kit
```

Requires `bash`, `git` and `python3`.

## Opt a project in

Create `.claude/verify.json` in the project:

```json
{ "commands": ["npm run typecheck", "npm test"] }
```

Without that file the verify hook does nothing. Commands run through `bash -c` in the project root, so only put in what you trust: anyone who can edit this file can run commands on your machine.

Rules the verify hook follows:
- Runs only when the git working tree, `HEAD` or `verify.json` changed since the last passing run, so question-and-answer turns cost nothing.
- Blocks at most once per stop (`stop_hook_active`), so a session can never be trapped in a loop.
- A command that is not installed (exit 127) is reported, not treated as a failure.
- Outside a git repository it does nothing.

## Where files go

Everything lives under `~/.claude/starter-kit/` (override with `CLAUDE_STARTER_KIT_HOME`): `archive/<project>/` holds the newest 20 transcripts per project, `verified/` holds the last green fingerprint. Transcripts can contain secrets, so they are deliberately kept out of project directories and repositories.

## Test

```
bash tests/hooks.test.sh
```
