#!/usr/bin/env bash
set -euo pipefail
usage() { echo "Usage: forge-guard.sh {approve|check-plan|check-task|scan-command} ..." >&2; }
project="${CLAUDE_PROJECT_DIR:-$PWD}"
validate_plan() {
  local file=$1 missing=0 h
  [[ -f "$file" ]] || { echo "missing plan: $file" >&2; return 1; }
  for h in "## Goal and success criteria" "## Context and assumptions" "## Alternatives considered and chosen approach" "## Allowed scope" "## Forbidden / approval-required actions" "## Environment constraints" "## Task list" "## Integration and final verification" "## Known risks and unverified items"; do
    grep -Fqx "$h" "$file" || { echo "plan missing heading: $h" >&2; missing=1; }
  done
  grep -Eq '^### T[[:alnum:]_.-]+[[:space:]]+[—-]' "$file" || { echo "plan has no task heading (### T... — title)" >&2; missing=1; }
  return "$missing"
}
task_owner() {
  local file=$1 id=$2 mode=$3
  awk -v id="$id" -v mode="$mode" '
    $0 ~ "^### " id "([[:space:]]|$)" { in_task=1; next }
    in_task && $0 ~ /^### / { exit }
    in_task && $0 ~ /^- owner:/ { owner=$0; found=1 }
    END {
      if (!found) { print "task not found or has no owner: " id > "/dev/stderr"; exit 1 }
      allowed=(mode=="investigate" && owner ~ /Codex-investigate/) || (mode=="review" && owner ~ /Codex-review/) || (mode=="setup" && owner ~ /Codex-setup/) || (mode=="implement" && owner ~ /Codex-implement/) || (mode=="debug" && owner ~ /(Codex-investigate|Codex-implement)/)
      if (!allowed) { print "owner does not authorize mode " mode ": " owner > "/dev/stderr"; exit 1 }
    }' "$file"
}
case "${1:-}" in
  approve)
    shift; plan=""
    while (($#)); do
      case "$1" in
        --project) project=$2; shift 2;;
        --plan) plan=$2; shift 2;;
        *) usage; exit 2;;
      esac
    done
    root=$(git -C "$project" rev-parse --show-toplevel 2>/dev/null) || { echo "not a Git repository" >&2; exit 2; }
    root=$(cd "$root" && pwd -P); plan=${plan:-$root/.forge/PLAN.md}; worklog="$root/.forge/WORKLOG.md"
    validate_plan "$plan" || exit 1
    [[ -f "$worklog" ]] || { echo "missing .forge/WORKLOG.md; initialize Forge first" >&2; exit 1; }
    sed -i 's/<!-- forge-approval: pending -->/<!-- forge-approval: approved -->/' "$worklog"
    sed -i 's/<!-- forge-run-state: planning -->/<!-- forge-run-state: running -->/' "$worklog"
    printf '%s\n' "- forge-run started: $(date -Iseconds); plan: $plan" >> "$worklog"
    echo "approved: $plan" ;;
  check-plan) validate_plan "${2:-$project/.forge/PLAN.md}" ;;
  check-task)
    [[ $# -ge 3 ]] || { usage; exit 2; }
    root=$(git -C "$project" rev-parse --show-toplevel 2>/dev/null) || { echo "not a Git repository" >&2; exit 2; }
    task_owner "$root/.forge/TASKS.md" "$2" "$3" ;;
  scan-command)
    shift; command_text="$*"
    if printf '%s' "$command_text" | LC_ALL=C grep -Eiq '(motor[[:space:]_-]*(enable|on)|servo[[:space:]_-]*(enable|on)|actuator|teleop|policy[[:space:]_-]*launch|deploy(ment)?[[:space:]]+(to|on)[[:space:]]+(g1|robot|hardware)|real[ -]?robot|실물[[:space:]]*(로봇|G1)|모터[[:space:]]*(활성|켜)|로봇[[:space:]]*(배포|동작|제어))'; then
      echo "blocked: possible physical-robot action; human approval checklist required" >&2; exit 1
    fi
    if printf '%s' "$command_text" | LC_ALL=C grep -Eiq '(^|[[:space:];|&])sudo([[:space:]]|$)|dangerously-bypass|danger-full-access'; then
      echo "blocked: prohibited privilege/sandbox bypass" >&2; exit 1
    fi
    echo "command safety scan passed" ;;
  *) usage; exit 2 ;;
esac
