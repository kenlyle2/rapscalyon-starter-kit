#!/usr/bin/env bash
# Stop hook: before Claude finishes, run the project's verify commands and hand
# any failure back so work continues instead of ending on red.
#
# Opt-in per project: .claude/verify.json  {"commands": ["npm test", "..."]}
# Runs only when the git working tree or HEAD changed since the last green run,
# so question-and-answer turns cost nothing. Never blocks twice in a row
# (stop_hook_active), when a command is not installed (exit 127), or outside git.
set -uo pipefail

INPUT="$(cat)"
read -r CWD ACTIVE < <(printf '%s' "$INPUT" | python3 -c 'import json,sys
try:
    d=json.load(sys.stdin)
    print(d.get("cwd","") or "-", str(d.get("stop_hook_active", False)))
except Exception: print("- False")' 2>/dev/null)

[ "$ACTIVE" = "True" ] && exit 0
[ "$CWD" = "-" ] && exit 0
CFG="$CWD/.claude/verify.json"
[ -f "$CFG" ] || exit 0
git -C "$CWD" rev-parse --git-dir >/dev/null 2>&1 || exit 0

CMDS=()
while IFS= read -r line; do [ -n "$line" ] && CMDS+=("$line"); done < <(python3 -c '
import json,sys
try:
    for c in json.load(open(sys.argv[1])).get("commands") or []:
        if isinstance(c, str) and c.strip(): print(c)
except Exception: pass
' "$CFG" 2>/dev/null)
[ ${#CMDS[@]} -eq 0 ] && exit 0

HOME_DIR="${CLAUDE_STARTER_KIT_HOME:-$HOME/.claude/starter-kit}"
KEY="$(printf '%s' "$CWD" | tr -c 'A-Za-z0-9' '-')"
STATE="$HOME_DIR/verified/$KEY"
FP="$( { git -C "$CWD" rev-parse HEAD 2>/dev/null; git -C "$CWD" status --porcelain 2>/dev/null; cat "$CFG"; } | cksum )"
[ "$(cat "$STATE" 2>/dev/null)" = "$FP" ] && exit 0

FAILED=""; SKIPPED=""
for cmd in "${CMDS[@]}"; do
  out="$(cd "$CWD" && bash -c "$cmd" 2>&1)"; rc=$?
  [ $rc -eq 0 ] && continue
  if [ $rc -eq 127 ]; then SKIPPED+="${cmd}; "; continue; fi
  FAILED+="
--- failed (exit $rc): $cmd ---
$(printf '%s' "$out" | tail -40)
"
done

if [ -z "$FAILED" ]; then
  if [ -n "$SKIPPED" ]; then
    python3 -c 'import json,sys
print(json.dumps({"systemMessage": "Starter Kit could not run: " + sys.argv[1] + "command not found, so it was not treated as a failure."}))' "$SKIPPED"
  else
    mkdir -p "$HOME_DIR/verified" 2>/dev/null && printf '%s' "$FP" > "$STATE" 2>/dev/null
  fi
  exit 0
fi

python3 -c 'import json,sys
print(json.dumps({"decision":"block","reason":"Verification failed before finishing. Fix these, then finish:\n" + sys.argv[1]}))' "$FAILED"
exit 0
