---
description: Import, validate, and normalize a prepared Forge plan without executing it.
argument-hint: <path/to/PLAN.md>
disable-model-invocation: true
---

Import the plan path from `$ARGUMENTS`.

1. Initialize `.forge/` with `${CLAUDE_PLUGIN_ROOT}/scripts/forge-init.sh` if needed.
2. Read the supplied plan and validate/normalize it into `.forge/PLAN.md` with all required sections: Goal and success criteria; Context and assumptions; Alternatives considered and chosen approach; Allowed scope; Forbidden / approval-required actions; Environment constraints; Task list; Integration and final verification; Known risks and unverified items.
3. For every `### T...` task, require an allowed owner, inputs/allowed paths, expected deliverable, verification command(s), and fallback/pause condition. Flag material gaps and ask only those questions.
4. Create/update `.forge/TASKS.md`, `.forge/SAFETY.md`, and append the import decision to `.forge/WORKLOG.md`. Do not execute project commands, install, download, login, or call Codex.
5. Present the execution-ready plan and state that the only approval is the exact standalone phrase `계획 확정. 자율 실행해.`. Until that phrase is received, remain blocked.
