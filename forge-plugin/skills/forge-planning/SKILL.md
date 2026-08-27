---
name: forge-planning
description: Plan a safe Forge workflow using Claude Code plan mode before any autonomous execution.
---

Forge planning is a conversation, not an execution permission. Use plan mode to structure the work visually. Ask focused questions and build the plan interactively.

The plan must cover:
- Goal and success criteria
- Context and assumptions
- Alternatives considered and chosen approach
- Allowed scope
- Forbidden / approval-required actions
- Environment constraints
- Task list — each task needs: owner, inputs/allowed paths, expected deliverable, verification command, fallback/pause condition
- Integration and final verification
- Known risks and unverified items

Task owners: `Claude` | `Codex-investigate` | `Codex-setup` | `Codex-review` | `Codex-implement`

Also persist the plan to `.forge/PLAN.md` so it survives session restarts. `.forge/` initialization is the sole allowed write during planning.

Physical-robot actions (motor enable, deployment, policy launch, motion, teleoperation, actuators, networked hardware) are always human-approval-only — never executable. Convert any such request to a human approval checklist task and state clearly that no launch will occur.

When the plan looks complete, prompt the user: **"준비됐으면 `/forge-run`을 실행해줘."**
