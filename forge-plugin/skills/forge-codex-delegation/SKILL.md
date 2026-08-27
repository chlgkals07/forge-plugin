---
name: forge-codex-delegation
description: Delegate bounded investigation, setup, debugging, review, and implementation packets to Codex safely.
disable-model-invocation: true
---

Use `scripts/codex-dispatch.sh` only for a task present in `.forge/TASKS.md` and the approved `.forge/PLAN.md`. Every prompt must include task ID and goal, approved-plan reference, allowed scope and forbidden actions, current evidence, required verification, sandbox/worktree permission, and return format: conclusion, changed files, commands run, results, risks, next action.

`investigate` and `review` are read-only; `debug` is read-only unless the task explicitly authorizes a write; `setup` is workspace-write only for an approved isolated environment task; `implement` is always in a separate Git worktree. Capture the exact prompt, JSONL events, last message, stderr, exit code, and session ID under `.forge/codex/`. Treat Codex output as evidence: Claude accepts, rejects with reasons, or requests follow-up verification.
