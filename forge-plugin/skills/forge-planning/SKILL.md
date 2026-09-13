---
name: forge-planning
description: Plan a safe Forge workflow using Claude Code plan mode before any autonomous execution.
---

Forge planning is a conversation, not an execution permission. Use plan mode to structure the work visually. Invoke the `superpowers:brainstorming` skill to run the conversation itself — classify the request (spike/bounded/architectural), ask focused questions one at a time, compare 2-3 approaches with a recommendation, and present the design in sections for approval.

**Handoff from brainstorming to Forge's plan schema:** brainstorming's normal terminal step (write a spec to `docs/superpowers/specs/`, then invoke `writing-plans`) is not used here. The moment the user approves the design inside the brainstorming flow, fold that approved design directly into the Forge plan schema below and write it to `.forge/PLAN.md` — do not create a separate spec file and do not invoke `writing-plans`.

The plan must cover:
- Goal and success criteria
- Context and assumptions
- Alternatives considered and chosen approach
- Allowed scope
- Forbidden / approval-required actions
- Environment constraints
- Loop contract — restate the Goal section's observable success conditions in a form a review dispatch can check directly against; every task with a non-`none` loop_policy is reviewed against this, not just its own local deliverable
- Task list — each task needs: owner, inputs/allowed paths, expected deliverable, verification command, fallback/pause condition, loop_policy, and (Codex-implement only) worktree
- Integration and final verification
- Known risks and unverified items

Task owners: `Claude` | `Codex-investigate` | `Codex-setup` | `Codex-review` | `Codex-implement`

**Assigning `loop_policy` per task (do this while building the task list, not after):**
- `until-verified` — task changes control/safety-relevant logic, touches multiple files/interfaces other tasks depend on, or is hard to reverse if wrong. Repeats implement→review until the task's verification command(s) actually pass; hard-capped at 5 rounds, then pause.
- `fixed:2` (default for ordinary work) — a typical implementation slice (new function, bug fix, small feature) where one review pass usually suffices but isn't guaranteed to. Adjust to `fixed:1` when the task is a straightforward continuation of an already-reviewed pattern in this same plan, or `fixed:3+` for unusually fiddly but non-critical work.
- `none` — single-file, low-blast-radius, trivially verifiable by reading the diff (doc typo, comment, one-line config, pure rename). No review dispatch at all; for a `Claude`-owned task this also means no subagent spawn — Claude implements it directly inline.
- `Codex-implement` tasks always get at least `fixed:1` — never bare `none` — since there's no human in the loop by default for Codex output.

Only assign `worktree: <path>` to `Codex-implement` tasks. Give a sequence of implement tasks the *same* worktree path when they don't need isolation from each other (no conflicting file ranges, one task's failure wouldn't contaminate another's tree) — `codex-dispatch.sh` only creates the worktree once and reuses it after. Give a task its own path only when it genuinely needs isolation.

Also persist the plan to `.forge/PLAN.md` so it survives session restarts. `.forge/` initialization is the sole allowed write during planning.

Physical-robot actions (motor enable, deployment, policy launch, motion, teleoperation, actuators, networked hardware) are always human-approval-only — never executable. Convert any such request to a human approval checklist task and state clearly that no launch will occur.

When the plan looks complete, call `ExitPlanMode` to request approval — the button approval (e.g. "Yes, auto-accept edits") is the sign-off; no separate confirmation phrase is required. After approval, prompt the user: **"준비됐으면 `/forge-run`을 실행해줘."**
