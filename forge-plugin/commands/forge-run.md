---
description: Execute the approved Forge plan autonomously. Optional additional request as argument.
argument-hint: [additional request or context]
---

Start executing the plan from `.forge/PLAN.md`. If no plan exists yet, tell the user to run `/forge` first.

1. Run `${CLAUDE_PLUGIN_ROOT}/scripts/forge-guard.sh approve --project "$CLAUDE_PROJECT_DIR"` to validate the plan and record the run state. Never bypass this gate.
2. If `$ARGUMENTS` contains an additional request, incorporate it into the plan scope before starting — add a task or note, update `.forge/PLAN.md` and `.forge/WORKLOG.md`.
3. Switch to auto mode. Work through tasks in plan order continuously. Keep `.forge/TASKS.md` and `.forge/WORKLOG.md` current with commands run, evidence, decisions, failures, and pauses.
4. Claude owns integration and judgment. Route each task by its `.forge/TASKS.md` owner: `Codex-*` tasks use `${CLAUDE_PLUGIN_ROOT}/scripts/codex-dispatch.sh` only for bounded packets (read-only `investigate`/`review` use `--sandbox read-only`; `implement` always uses a separate Git worktree); `Claude`-owned tasks use the `superpowers:subagent-driven-development` skill (fresh implementer subagent + task reviewer + fix loop per task).
5. **Do not ask for permission during execution** unless the action is:
   - `sudo` or system/kernel/driver/package-manager change
   - Credential, token, SSH key, or auth file access
   - New external login or paid service
   - Large or unlisted dependency download
   - Anything that could affect physical hardware
   - A second consecutive failure with the same root cause
   - Work clearly outside the approved plan scope
   For everything else: make the call, keep going, summarize at the end.
6. Physical robot actions remain prohibited regardless of plan content. Convert any such request to a human approval checklist.
7. Run every listed verification. Mark unrun tests as unverified, not complete.
8. When all tasks are done, give a concise summary: completed tasks, evidence, anything unverified, and next steps if any.
