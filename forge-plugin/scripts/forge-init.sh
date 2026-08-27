#!/usr/bin/env bash
set -euo pipefail
usage() { echo "Usage: forge-init.sh [--project DIR] [--update-gitignore]" >&2; }
project="${CLAUDE_PROJECT_DIR:-$PWD}"
update_gitignore=0
while (($#)); do
  case "$1" in
    --project) [[ $# -ge 2 ]] || { usage; exit 2; }; project=$2; shift 2 ;;
    --update-gitignore) update_gitignore=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) usage; exit 2 ;;
  esac
done
root=$(git -C "$project" rev-parse --show-toplevel 2>/dev/null) || { echo "Forge requires a Git repository: $project" >&2; exit 2; }
root=$(cd "$root" && pwd -P)
plugin_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)
state="$root/.forge"
mkdir -p "$state/evidence" "$state/codex"
for name in PLAN.md TASKS.md SAFETY.md WORKLOG.md; do
  if [[ ! -e "$state/$name" ]]; then
    install -m 0644 "$plugin_root/templates/$name" "$state/$name"
    echo "created .forge/$name"
  else
    echo "kept existing .forge/$name"
  fi
done
ignore_lines=(".forge/evidence/" ".forge/codex/")
ignore_file="$root/.gitignore"
if [[ ! -e "$ignore_file" ]]; then
  printf '%s\n' "# Forge generated evidence and worker transcripts" "${ignore_lines[@]}" > "$ignore_file"
  echo "created .gitignore with Forge evidence ignores"
elif [[ $update_gitignore -eq 1 ]]; then
  for line in "${ignore_lines[@]}"; do
    grep -Fqx "$line" "$ignore_file" || printf '%s\n' "$line" >> "$ignore_file"
  done
  echo "updated .gitignore with Forge evidence ignores"
else
  missing=()
  for line in "${ignore_lines[@]}"; do
    grep -Fqx "$line" "$ignore_file" || missing+=("$line")
  done
  if ((${#missing[@]})); then
    echo "existing .gitignore needs explicit approval before modification; missing: ${missing[*]}" >&2
    echo "after user approval run: forge-init.sh --project '$root' --update-gitignore" >&2
  fi
fi
printf 'Forge state: %s\n' "$state"
printf 'Approval: %s\n' "$(grep -o 'forge-approval: [a-z-]*' "$state/WORKLOG.md" | head -1 || true)"
