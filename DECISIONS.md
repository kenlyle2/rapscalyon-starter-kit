# Decisions

Why the Starter Kit is built the way it is. Each entry records something that is not obvious from the files and would be expensive to rediscover. Newest first. Read this before changing the hooks, the manifest or the file locations.

---

## 2026-10-09 — Published as a public AGPL-3.0-or-later repository

**Decision:** the plugin is public, licensed AGPL-3.0-or-later, with the license text in `LICENSE`.
**Why:** it is meant to be handed to clients and reused, and it matches the license of the projects it grew out of.
**Rejected:** a permissive license. Not chosen because of the match above; revisit if a client deliverable needs one.
**Not changed:** the README recommends DeepWorkPlan and codebase-memory-mcp as companions, but nothing here depends on either.

## 2026-10-09 — Plugin name is `rapscalyon-starter-kit`, not `claude-starter-kit`

**Decision:** the plugin and marketplace are both named `rapscalyon-starter-kit`. "Claude Starter Kit" remains fine as a description.
**Why:** `claude plugin validate` rejects third-party names starting with `claude-`, `anthropic-` or `cc-plugin-`. The check fails validation, so the name is not a style choice.

## 2026-10-09 — Delivered as a user-level plugin, not as project hooks

**Decision:** the hooks ship as a Claude Code plugin installed at user scope. A project opts in with a file in the project; the plugin itself is never copied into projects.
**Why:** one install covers every project and every session, updates in one place, and can be given to a client with two commands. Project-level hooks would need copying into each repository and would drift.
**Rejected:** hooks in each project's `.claude/settings.json`.

## 2026-10-09 — Verification is opt-in per project, via `.claude/verify.json`

**Decision:** the Stop hook does nothing unless the project has `.claude/verify.json` with a `commands` list. Commands run through `bash -c` in the project root.
**Why:** a global hook that ran guessed commands would break unrelated projects. What counts as "verified" is the project's call. Running arbitrary strings is acceptable only because the project owner wrote them; the README warns that anyone who can edit the file can run commands on the machine.
**Not done:** `verify.json` is not validated or sandboxed. Do not accept it from untrusted pull requests without review.

## 2026-10-09 — Skip verification when nothing changed since the last green run

**Decision:** the Stop hook fingerprints `HEAD`, `git status --porcelain` and `verify.json`, stores the fingerprint after a passing run in `~/.claude/starter-kit/verified/`, and skips the run while it still matches.
**Why:** without it, every turn of pure question and answer would re-run the full test suite. Only a green run is recorded, so a failure is re-checked next time.
**Rejected:** running only when the tree is dirty. A session that commits and then stops would skip verification, because the tree is clean.
**Not done:** outside a git repository the hook does nothing, since there is no change signal.

## 2026-10-09 — The Stop hook can never trap a session

**Decision:** the hook exits without blocking when `stop_hook_active` is true, and treats exit code 127 (command not found) as "could not run", reported as a message and not as a failure.
**Why:** a hook that blocks again after Claude has already tried to fix things loops forever. And a missing dependency, such as a fresh checkout without installed packages, is not a failing test; blocking on it would trap the session in an environment it cannot fix.

## 2026-10-09 — Transcript archives live outside the project

**Decision:** the PreCompact hook copies the transcript to `~/.claude/starter-kit/archive/<project>/` and keeps the newest 20 per project. `CLAUDE_STARTER_KIT_HOME` overrides the base directory.
**Why:** transcripts can contain secrets, and a project directory can be a public repository. Compaction loses decisions and rejected approaches first, so the full transcript is worth keeping.
**Gotcha:** archive names include the process id as well as the timestamp. With the timestamp alone, two compactions within the same second overwrote each other and the pruning test failed.

## 2026-10-09 — Only two hooks; the rest of Proof was not adopted

**Decision:** the kit was written after evaluating `jsamitt/proof-claude-plugin`, a solo-developer harness with 11 skills, 4 reviewer agents and 4 hooks. Only the ideas of a verify-before-finishing gate and a pre-compaction archive were taken. The code here is a rewrite.
**Why not the rest:** its planning skills duplicate DeepWorkPlan, its workflow requires a GitHub Projects board, and the repository carries no license file, so nothing could be reused.
**Not done:** its destructive-command and protected-path guards and its adversarial reviewer agents were not adopted. The reviewer prompts were not read in full.
