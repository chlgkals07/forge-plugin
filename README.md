# Forge

Forge is a personal Claude Code plugin for one-plan-at-a-time, evidence-backed autonomous software work. Claude remains the team lead; Codex CLI handles bounded investigation, setup, debugging, review, and separate-worktree implementation.

## Install

From this repository, validate and install the local plugin:

```bash
claude plugin validate ./forge-plugin --strict
claude --plugin-dir ./forge-plugin
```

For a persistent personal install, use Claude Code's `/plugin` UI or install the directory at user scope according to your Claude Code version. A skills-directory alternative is to place/copy `forge-plugin/` under a personal skills directory; restart Claude Code or run `/reload-plugins` after changes. Plugin commands are available as `/forge:forge`, `/forge:forge-plan`, `/forge:forge-run`, `/forge:forge-status`, and `/forge:forge-closeout`; current Claude Code versions may also expose the unqualified aliases requested in the workflow (`/forge`, `/forge-plan`, `/forge-run`, `/forge-status`, `/forge-closeout`) when there is no name conflict.

## Workflow

Use `/forge` for a rough request or `/forge-plan path/to/PLAN.md` for an existing plan. Forge creates `.forge/` on first use. Planning does not execute project commands. Only the exact standalone phrase `계획 확정. 자율 실행해.` authorizes `/forge-run`; after that, the approved single plan runs continuously within its boundaries. Use `/forge-status` and `/forge-closeout` for evidence and final verification.

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
2. Near-miss approval text stays blocked; the exact phrase alone changes the marker and permits `/forge-run`.
3. An approved setup task uses only the isolated environment and records smoke-test evidence.
4. A meaningful Claude multi-file change invokes read-only Codex review; critical findings block closeout.
5. An implement task writes only to its separate worktree until Claude explicitly integrates it.
6. Physical G1/robot deployment or motion is converted to a human checklist and never launched.
7. Plan-external dependency/download, sudo, login, and system-change requests pause.
8. `/forge-status` and `/forge-closeout` show evidence, blockers, and every unverified item accurately.
