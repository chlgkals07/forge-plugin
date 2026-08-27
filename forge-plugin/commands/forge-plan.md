---
description: Import, validate, and normalize a prepared Forge plan without executing it.
argument-hint: <path/to/PLAN.md>
disable-model-invocation: true
---

Import the plan path from `$ARGUMENTS`.

1. Initialize `.forge/` with `${CLAUDE_PLUGIN_ROOT}/scripts/forge-init.sh` if needed.
2. Call `EnterPlanMode`. Read the supplied plan and validate/normalize it into `.forge/PLAN.md` with all required sections: Goal and success criteria; Context and assumptions; Alternatives considered and chosen approach; Allowed scope; Forbidden / approval-required actions; Environment constraints; Task list; Integration and final verification; Known risks and unverified items.
3. For every `### T...` task, require an allowed owner, inputs/allowed paths, expected deliverable, verification command(s), and fallback/pause condition. If material gaps exist, invoke the `superpowers:brainstorming` skill to ask only those questions and resolve them (see the `forge-planning` skill for folding the result into this schema).
4. Create/update `.forge/TASKS.md`, `.forge/SAFETY.md`, and append the import decision to `.forge/WORKLOG.md`. Do not execute project commands, install, download, login, or call Codex.
5. Present the execution-ready plan and call `ExitPlanMode` to request approval. The user's approval of the plan is the sign-off — no separate confirmation phrase is required. Until that approval, remain blocked.
