#!/usr/bin/env bash
# Regression tests for both hooks. Run: bash tests/hooks.test.sh
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
export CLAUDE_STARTER_KIT_HOME="$T/home"
fail=0
check() { if [ "$2" = "$3" ]; then echo "ok   $1"; else echo "FAIL $1: expected [$2] got [$3]"; fail=1; fi; }

P="$T/proj"; mkdir -p "$P/.claude"; git -C "$P" init -q; git -C "$P" config user.email t@t; git -C "$P" config user.name t
echo a > "$P/f"; git -C "$P" add f; git -C "$P" commit -qm init
run() { printf '{"cwd":"%s","stop_hook_active":%s}' "$P" "${1:-false}" | "$ROOT/scripts/verify-on-stop.sh"; }

check "no config: allow" "" "$(run)"
echo '{"commands":["false"]}' > "$P/.claude/verify.json"
check "failing command: block" "block" "$(run | python3 -c 'import json,sys;print(json.load(sys.stdin)["decision"])')"
check "stop_hook_active: allow" "" "$(run true)"
echo '{"commands":["true"]}' > "$P/.claude/verify.json"
check "passing: allow" "" "$(run)"
echo '{"commands":["echo x >> '"$T"'/count; true"]}' > "$P/.claude/verify.json"
run >/dev/null; run >/dev/null
check "unchanged tree: runs once" "1" "$(wc -l < "$T/count")"
echo b >> "$P/f"; run >/dev/null
check "changed tree: reruns" "2" "$(wc -l < "$T/count")"
echo '{"commands":["no_such_cmd_xyz"]}' > "$P/.claude/verify.json"
check "command not found: not a failure" "" "$(run | grep -c '"decision"' | grep -v '^0$')"
check "non-git dir: allow" "" "$(printf '{"cwd":"%s"}' "$T" | "$ROOT/scripts/verify-on-stop.sh")"

echo '{}' > "$T/t.jsonl"
for i in $(seq 1 22); do printf '{"transcript_path":"%s","cwd":"%s"}' "$T/t.jsonl" "$P" | "$ROOT/scripts/precompact-archive.sh"; sleep 0.01; done
check "archive outside project" "no" "$([ -d "$P/.claude/archive" ] && echo yes || echo no)"
check "archive pruned to 20" "20" "$(ls "$T"/home/archive/*/ | wc -l | tr -d ' ')"
exit $fail
