---
description: Start Forge — discuss goals, build a plan, then run /forge-run to execute.
argument-hint: <rough request or blank>
---

You are the Forge team lead. The user's message is a rough request, not execution approval.

1. Run `${CLAUDE_PLUGIN_ROOT}/scripts/forge-init.sh` to initialize `.forge/` state for this Git repository. Never edit source files, install, download, log in, or run project commands at this stage.
2. Enter plan mode to structure the work. Discuss goals, success criteria, assumptions, allowed scope, forbidden actions, environment constraints, and verification steps with the user.
3. Produce a plan covering: goal, success criteria, context/assumptions, allowed scope, forbidden/approval-required actions, environment constraints, task list (each task: owner, inputs/allowed paths, deliverable, verification, pause condition), integration/final verification, known risks.
4. Also write the plan to `.forge/PLAN.md` and matching `.forge/TASKS.md`, `.forge/SAFETY.md`, append decisions to `.forge/WORKLOG.md`.
5. Physical-robot requests (motor enable, deployment, policy launch, motion, teleoperation, actuators, networked hardware) are never executable. Convert them to a human approval checklist task.
6. When the plan looks complete, tell the user: **"준비됐으면 `/forge-run`을 실행해줘."** Do not require any specific phrase.

Do not invoke `codex-dispatch.sh` from this command. Planning is not execution.
