#!/usr/bin/env bash
# PreCompact hook: keep the full transcript before compaction summarises it.
# Archives live outside the project (default ~/.claude/starter-kit/archive/<project>/),
# so transcripts, which can contain secrets, never end up in a repository.
# Keeps the newest 20 per project. Best effort; never interferes.
set -uo pipefail

INPUT="$(cat)"
read -r TRANSCRIPT CWD < <(printf '%s' "$INPUT" | python3 -c 'import json,sys
try:
    d=json.load(sys.stdin)
    print(d.get("transcript_path","") or "-", d.get("cwd","") or "-")
except Exception: print("- -")' 2>/dev/null)

{ [ "$TRANSCRIPT" = "-" ] || [ ! -f "$TRANSCRIPT" ] || [ "$CWD" = "-" ]; } && exit 0

HOME_DIR="${CLAUDE_STARTER_KIT_HOME:-$HOME/.claude/starter-kit}"
DEST="$HOME_DIR/archive/$(printf '%s' "$CWD" | tr -c 'A-Za-z0-9' '-')"
mkdir -p "$DEST" 2>/dev/null || exit 0
cp "$TRANSCRIPT" "$DEST/$(date +%Y%m%d-%H%M%S)-$$-$(basename "$TRANSCRIPT")" 2>/dev/null || true
ls -1t "$DEST"/*.jsonl 2>/dev/null | tail -n +21 | xargs -r rm -f 2>/dev/null || true
exit 0
