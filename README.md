# Forge

Forge is a personal Claude Code plugin for one-plan-at-a-time, evidence-backed autonomous software work. Claude remains the team lead; Codex CLI handles bounded investigation, setup, debugging, review, and separate-worktree implementation.

## Install

Same two commands as any other personal plugin — no cloning required:

```bash
claude plugin marketplace add chlgkals07/forge-plugin
claude plugin install forge@forge
```

This registers the repo as a marketplace (`.claude-plugin/marketplace.json` at the repo root) and installs the `forge` plugin from it at user scope, loading automatically every session from then on. To update later: `claude plugin update forge@forge` (restart to apply).

For local iteration on this repo instead, validate and run it for one session without installing:

```bash
claude plugin validate ./forge-plugin --strict
claude --plugin-dir ./forge-plugin
```

Plugin commands are available as `/forge:forge`, `/forge:forge-plan`, `/forge:forge-run`, `/forge:forge-status`, and `/forge:forge-closeout`; current Claude Code versions may also expose the unqualified aliases requested in the workflow (`/forge`, `/forge-plan`, `/forge-run`, `/forge-status`, `/forge-closeout`) when there is no name conflict.

This repo's `.claude/settings.json` also allowlists Edit/Write/Read under `.forge/**` and calls to `forge-plugin/scripts/*.sh`, so routine plan/state file updates don't prompt for approval on every write.

## Workflow

Use `/forge` for a rough request or `/forge-plan path/to/PLAN.md` for an existing plan. Forge creates `.forge/` on first use and enters plan mode, using the `superpowers:brainstorming` skill to classify the request, ask questions, compare approaches, and present a design; planning does not execute project commands. The approved design is folded into Forge's own plan schema (owners, allowed scope, verification, fallback) — not into a generic spec file. Approval to run is the plan-mode approval itself (e.g. "Yes, auto-accept edits" via `ExitPlanMode`); no separate confirmation phrase is required. After that, the approved single plan runs continuously within its boundaries via `/forge-run`. Use `/forge-status` and `/forge-closeout` for evidence and final verification.

During execution, `Codex-*`-owned tasks go through the Codex dispatcher (below); `Claude`-owned tasks go through the `superpowers:subagent-driven-development` skill — a fresh implementer subagent per task, then a task reviewer (spec compliance + code quality) with its own fix loop, which stands in for a separate Codex review on that task.

The Codex dispatcher defaults to `--sandbox read-only`, captures prompts/results as ignored `.forge/codex/` artifacts, uses `workspace-write` plus `--approve-for-me` only for explicitly approved setup/implementation writes, and refuses implementation in the main worktree. It never uses `danger-full-access` or approval bypass flags.

## Safety

Physical robot commands are permanently outside autonomous execution, including motor enable, deployment, policy launch, motion, teleoperation, actuators, and networked hardware control. Sudo/system changes, credentials, new logins, plan-external work, unlisted downloads/dependencies, and ambiguous hardware actions pause for a human. Tests not run are reported as unverified.

## Verification

```bash
bash tests/test_forge.sh
bash -n forge-plugin/scripts/*.sh tests/*.sh
claude plugin validate ./forge-plugin --strict
```

Live authenticated Codex and interactive Claude Code behavior must be checked in Claude Code itself; the shell suite uses a harmless mock Codex executable.

## After 16:00 Claude Code verification checklist

In a disposable non-hardware Git repository, confirm:

1. `/forge` creates `.forge/` and stays planning-only; `/forge-plan` flags missing schema fields.
2. `/forge-run` before plan-mode approval stays blocked; the `ExitPlanMode` approval (not any typed phrase) is what unblocks it.
3. An approved setup task uses only the isolated environment and records smoke-test evidence.
4. A Claude-owned task runs through subagent-driven-development (fresh implementer + task reviewer); a Codex-owned multi-file change still invokes read-only Codex review. Critical findings from either block closeout.
5. An implement task writes only to its separate worktree until Claude explicitly integrates it.
6. Physical G1/robot deployment or motion is converted to a human checklist and never launched.
7. Plan-external dependency/download, sudo, login, and system-change requests pause.
8. `/forge-status` and `/forge-closeout` show evidence, blockers, and every unverified item accurately.
