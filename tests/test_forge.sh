#!/usr/bin/env bash
set -euo pipefail
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)
init="$repo_root/forge-plugin/scripts/forge-init.sh"; guard="$repo_root/forge-plugin/scripts/forge-guard.sh"; dispatch="$repo_root/forge-plugin/scripts/codex-dispatch.sh"; status="$repo_root/forge-plugin/scripts/forge-status.sh"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
pass=0; fail=0
ok() { echo "ok - $1"; pass=$((pass+1)); }
bad() { echo "not ok - $1" >&2; fail=$((fail+1)); }
run_expect() { local label=$1 expected=$2; shift 2; if "$@" >/dev/null 2>&1; then got=0; else got=$?; fi; [[ $got -eq $expected ]] && ok "$label" || bad "$label (exit $got, expected $expected)"; }
main="$tmp/repo"; mkdir "$main"; git -C "$main" init -q; git -C "$main" config user.email test@example.invalid; git -C "$main" config user.name Test; touch "$main/README"; git -C "$main" add README; git -C "$main" commit -qm init
"$init" --project "$main" >/dev/null
[[ -d "$main/.forge/evidence" && -d "$main/.forge/codex" && -f "$main/.gitignore" ]] && ok "initializes state and default ignores" || bad "initialization"
before=$(sha256sum "$main/.forge/PLAN.md"); "$init" --project "$main" >/dev/null; [[ $(sha256sum "$main/.forge/PLAN.md") == "$before" ]] && ok "does not overwrite existing plan" || bad "plan overwrite"
run_expect "near-miss approval blocked" 1 "$guard" check-approval '계획 확정. 자율 실행해!'
run_expect "exact approval accepted" 0 "$guard" check-approval '계획 확정. 자율 실행해.'
run_expect "physical robot command blocked" 1 "$guard" scan-command 'motor enable on G1'
run_expect "sudo blocked" 1 "$guard" scan-command 'sudo apt install foo'
run_expect "safe command accepted" 0 "$guard" scan-command 'pytest -q'
"$guard" approve --project "$main" --phrase '계획 확정. 자율 실행해.' >/dev/null
prompt="$tmp/prompt.md"; printf '%s\n' '## Task ID and goal' 'T1 inspect repository' '## Approved-plan reference' '## Allowed scope and forbidden actions' '## Current evidence' '## Required verification' 'pytest -q' '## Sandbox / worktree permission' 'read-only' '## Return format' 'conclusion, changed files, commands run, results, risks, next action' > "$prompt"
run_expect "dispatcher rejects wrong owner" 1 "$dispatch" --project "$main" --mode investigate --task T1 --prompt-file "$prompt" --dry-run
sed -i 's/owner: Claude/owner: Codex-investigate/' "$main/.forge/TASKS.md"
out=$("$dispatch" --project "$main" --mode investigate --task T1 --prompt-file "$prompt" --dry-run)
[[ $out == *'sandbox=read-only'* ]] && ok "dispatcher dry-run is read-only" || bad "dispatcher dry-run"
find "$main/.forge/codex" -maxdepth 1 -name "*.prompt.md" -print -quit | grep -q . && ok "dispatcher captures prompt" || bad "prompt capture"
cat > "$tmp/codex" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
last=''; cwd='.'
while (($#)); do case "$1" in --output-last-message) last=$2; shift 2;; --cd) cwd=$2; shift 2;; *) shift;; esac; done
printf '%s\n' '{"type":"turn.completed","session_id":"mock-session"}'
printf '%s\n' 'mock conclusion' > "$last"
printf '%s\n' "cwd=$cwd" > "$cwd/mock-worker.txt"
MOCK
chmod +x "$tmp/codex"; PATH="$tmp:$PATH" "$dispatch" --project "$main" --mode investigate --task T1 --prompt-file "$prompt" >/dev/null
[[ -f "$main/mock-worker.txt" ]] && ok "mock read-only worker runs in project root" || bad "mock worker"
git -C "$main" add mock-worker.txt; git -C "$main" commit -qm worker
sed -i 's/owner: Codex-investigate/owner: Codex-implement/' "$main/.forge/TASKS.md"
wt="$tmp/worktree"; PATH="$tmp:$PATH" "$dispatch" --project "$main" --mode implement --task T1 --prompt-file "$prompt" --worktree "$wt" --create-worktree --branch forge-test >/dev/null
[[ -f "$wt/mock-worker.txt" ]] && grep -q "cwd=$wt" "$wt/mock-worker.txt" && ! grep -q "cwd=$wt" "$main/mock-worker.txt" && ok "implementation worker is isolated in worktree" || bad "worktree isolation"
PATH="$tmp:$PATH" "$status" --project "$main" >/dev/null && ok "status reports initialized repository" || bad "status"
echo "tests: $pass passed, $fail failed"; [[ $fail -eq 0 ]]
