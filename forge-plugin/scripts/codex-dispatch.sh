#!/usr/bin/env bash
set -euo pipefail
usage() { echo "Usage: codex-dispatch.sh --mode MODE --task ID --prompt-file FILE [--project DIR] [--worktree DIR] [--create-worktree] [--branch NAME] [--resume ID] [--write] [--dry-run]" >&2; }
mode=""; task=""; prompt_file=""; project="${CLAUDE_PROJECT_DIR:-$PWD}"; worktree=""; create_worktree=0; branch=""; resume=""; write=0; dry=0
while (($#)); do
  case "$1" in
    --mode) mode=$2; shift 2;;
    --task) task=$2; shift 2;;
    --prompt-file) prompt_file=$2; shift 2;;
    --project) project=$2; shift 2;;
    --worktree) worktree=$2; shift 2;;
    --create-worktree) create_worktree=1; shift;;
    --branch) branch=$2; shift 2;;
    --resume) resume=$2; shift 2;;
    --write) write=1; shift;;
    --dry-run) dry=1; shift;;
    -h|--help) usage; exit 0;;
    *) usage; exit 2;;
  esac
done
case "$mode" in investigate|setup|debug|review|implement) ;; *) echo "invalid mode; use investigate, setup, debug, review, or implement" >&2; exit 2;; esac
[[ -n "$task" && -n "$prompt_file" && -f "$prompt_file" ]] || { usage; exit 2; }
root=$(git -C "$project" rev-parse --show-toplevel 2>/dev/null) || { echo "dispatcher requires a Git repository" >&2; exit 2; }
root=$(cd "$root" && pwd -P); guard="$(dirname "${BASH_SOURCE[0]}")/forge-guard.sh"
if ! grep -Fq '<!-- forge-approval: approved -->' "$root/.forge/WORKLOG.md" 2>/dev/null; then
  echo "dispatch blocked: approved plan marker is required (approve with /forge-run first)" >&2; exit 1
fi
"$guard" check-plan "$root/.forge/PLAN.md"
CLAUDE_PROJECT_DIR="$root" "$guard" check-task "$task" "$mode"
if [[ "$mode" == implement ]]; then
  [[ -n "$worktree" ]] || { echo "implement requires --worktree" >&2; exit 2; }
  worktree=$(mkdir -p "$(dirname "$worktree")" && cd "$(dirname "$worktree")" && printf '%s/%s' "$PWD" "$(basename "$worktree")")
  if [[ ! -d "$worktree/.git" && ! -f "$worktree/.git" ]]; then
    [[ $create_worktree -eq 1 ]] || { echo "worktree does not exist; pass --create-worktree explicitly" >&2; exit 2; }
    [[ -n "$branch" ]] || branch="forge/${task//[^A-Za-z0-9._-]/-}"
    git -C "$root" worktree add -b "$branch" "$worktree" HEAD
  fi
  wtroot=$(git -C "$worktree" rev-parse --show-toplevel 2>/dev/null) || { echo "invalid implementation worktree" >&2; exit 2; }
  [[ $(cd "$wtroot" && pwd -P) != "$root" ]] || { echo "refusing to implement in main worktree" >&2; exit 1; }
  cwd=$(cd "$wtroot" && pwd -P)
else
  cwd="$root"
fi
"$guard" scan-command "$(<"$prompt_file")"
sandbox=read-only; approve_args=()
case "$mode" in
  setup|implement) sandbox=workspace-write; approve_args+=(--approve-for-me);;
  debug) [[ $write -eq 1 ]] && { sandbox=workspace-write; approve_args+=(--approve-for-me); };;
esac
stamp=$(date -u +%Y%m%dT%H%M%SZ); safe_task=${task//[^A-Za-z0-9._-]/_}; outdir="$root/.forge/codex"; mkdir -p "$outdir"
prompt_out="$outdir/${stamp}-${safe_task}.prompt.md"; json_out="$outdir/${stamp}-${safe_task}.jsonl"; last_out="$outdir/${stamp}-${safe_task}.last.md"; err_out="$outdir/${stamp}-${safe_task}.stderr.log"
{
  echo "# Forge Codex packet"; echo; echo "Task ID and goal: $task"; echo "Approved-plan reference: $root/.forge/PLAN.md"; echo "Sandbox / worktree permission: $sandbox; cwd=$cwd"; echo; cat "$prompt_file"
} > "$prompt_out"
if [[ $dry -eq 1 ]]; then
  printf 'dry-run: mode=%s task=%s sandbox=%s cwd=%s prompt=%s\n' "$mode" "$task" "$sandbox" "$cwd" "$prompt_out"; exit 0
fi
command=(codex exec --json --output-last-message "$last_out" --sandbox "$sandbox" --cd "$cwd" "${approve_args[@]}")
if [[ -n "$resume" ]]; then command+=(resume "$resume" -); else command+=(-); fi
set +e
"${command[@]}" < "$prompt_out" > "$json_out" 2> "$err_out"
exit_code=$?
set -e
printf '%s\n' "- Codex $mode task $task: exit=$exit_code; prompt=$prompt_out; result=$json_out; stderr=$err_out" >> "$root/.forge/WORKLOG.md"
printf 'Codex result: mode=%s task=%s exit=%s\n' "$mode" "$task" "$exit_code"
if [[ -s "$last_out" ]]; then sed -n '1,80p' "$last_out"; else echo "No final message; inspect $json_out and $err_out"; fi
exit "$exit_code"
