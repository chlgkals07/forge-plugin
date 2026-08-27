#!/usr/bin/env bash
set -euo pipefail
project="${CLAUDE_PROJECT_DIR:-$PWD}"; closeout=0
while (($#)); do
  case "$1" in
    --project) project=$2; shift 2;;
    --closeout) closeout=1; shift;;
    *) echo "Usage: forge-status.sh [--project DIR] [--closeout]" >&2; exit 2;;
  esac
done
root=$(git -C "$project" rev-parse --show-toplevel 2>/dev/null) || { echo "Forge status requires a Git repository" >&2; exit 2; }
root=$(cd "$root" && pwd -P); state="$root/.forge"
[[ -d "$state" ]] || { echo "Forge is not initialized in $root"; exit 1; }
approval=$(grep -o 'forge-approval: [a-z-]*' "$state/WORKLOG.md" 2>/dev/null | head -1 || echo "forge-approval: unknown")
run_state=$(grep -o 'forge-run-state: [a-z-]*' "$state/WORKLOG.md" 2>/dev/null | head -1 || echo "forge-run-state: unknown")
echo "Forge status: $root"; echo "- $approval"; echo "- $run_state"; echo "- Plan: $([[ -f "$state/PLAN.md" ]] && echo present || echo missing)"; echo "- Tasks: $([[ -f "$state/TASKS.md" ]] && echo present || echo missing)"
if [[ -f "$state/TASKS.md" ]]; then
  echo "- Task records:"; grep -E '^### T|^- status:|^- owner:|^- evidence:' "$state/TASKS.md" | sed -n '1,160p' || true
fi
echo "- Codex artifacts: $(find "$state/codex" -maxdepth 1 -type f 2>/dev/null | wc -l | tr -d ' ')"; echo "- Evidence artifacts: $(find "$state/evidence" -maxdepth 1 -type f 2>/dev/null | wc -l | tr -d ' ')"
echo "- Last worklog entries:"; tail -n 12 "$state/WORKLOG.md"
if [[ $closeout -eq 1 ]]; then echo "- Closeout rule: only verified commands count as complete; inspect all unverified items above and in PLAN.md."; fi
