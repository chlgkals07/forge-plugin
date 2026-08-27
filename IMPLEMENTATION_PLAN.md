# Forge Plugin Implementation Plan

## Goal

Implement and verify the v1 Claude Code personal plugin described in the user-approved specification. The plugin must keep Claude in planning mode until the exact Korean approval phrase is observed, delegate bounded work to Codex CLI, enforce physical-hardware and system-change safety boundaries, and retain auditable repository-local state.

## Repository preflight

- The repository currently contains only Git metadata; there are no source files or local `AGENTS.md` instructions.
- Verify the locally installed `claude`, `codex`, `codex exec`, and `git` commands without installing or changing anything.
- Use current local CLI help plus the named official Codex non-interactive documentation to shape dispatcher flags. Missing tools/authentication must produce diagnostics, not trigger installation or login.

## Implementation scope

1. Scaffold `forge-plugin/` with `.claude-plugin/plugin.json`, five command entry points, three operational skills, scripts, and templates.
2. Add deterministic `.forge` initialization that:
   - requires a Git worktree,
   - creates state only on first Forge use,
   - never overwrites existing state,
   - asks before modifying an existing `.gitignore`, and otherwise records the default evidence/Codex ignores.
3. Encode planning and execution gates in commands and skills:
   - exact approval phrase only,
   - normalized plan/task schema,
   - no pre-approval project mutation or project commands,
   - physical-robot hard stop,
   - approved-scope and retry/pause boundaries,
   - evidence-backed completion only.
4. Implement `codex-dispatch.sh` with bounded worker modes, read-only default, prompt/result capture, structured JSONL output, compact summaries, and worktree-only implementation.
5. Implement `forge-status.sh` and closeout behavior around task/evidence state.
6. Add a minimal shell test suite covering initialization, approval matching, dispatcher validation/dry-run behavior, worktree isolation, status, and physical-robot safeguards.
7. Run syntax checks and the test suite. Record any environment-dependent or unrun acceptance cases explicitly.

## Files and boundaries

- Allowed writes: this repository only, primarily `forge-plugin/`, `tests/`, top-level documentation, and this plan.
- No dependency installation, external login, large download, system modification, or physical-hardware command.
- No commit and no modification of a pre-existing `.gitignore` without explicit user approval.
- Tests use disposable repositories under `/tmp` and must not touch valuable worktrees.

## Verification

- Shell syntax: `bash -n forge-plugin/scripts/*.sh tests/*.sh`
- Manifest/template assertions via the repository test suite.
- Disposable-Git-repository initialization and worktree isolation tests.
- Dispatcher dry-run/mocked-Codex tests; live authenticated Codex execution is reported separately if unavailable or unsafe to invoke during testing.
- Final `git diff --check` and repository status review.

## Pause conditions

Pause before any work beyond this scope, any new dependency/download/login, any system-level change, any physical-hardware ambiguity, a repeated root-cause failure, or a verification failure requiring an architectural change.
