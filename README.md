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

## Recommended companions

The hooks are the enforcement layer. Two other tools cover the planning and navigation sides, and we use and recommend both:

- **[DeepWorkPlan](https://github.com/DailybotHQ/deepworkplan-skill)** (DWP): turns multi-step work into a written plan in `.dwp/plans/` that survives interruptions and can be resumed. Pair it with verify-on-stop so each task ends on green.
- **[codebase-memory-mcp](https://github.com/DeusData/codebase-memory-mcp)** (MIT): indexes the repository into a knowledge graph so Claude finds callers, call chains and symbols with a few queries instead of reading whole files. It cuts token use and keeps answers grounded in the real code.

Neither is required, and this plugin does not depend on them.

## License

AGPL-3.0-or-later. See `LICENSE`.

## Test

```
bash tests/hooks.test.sh
```
