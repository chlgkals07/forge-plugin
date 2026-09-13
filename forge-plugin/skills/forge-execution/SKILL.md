---
name: forge-execution
description: Execute one approved Forge plan continuously, pausing only for genuinely dangerous actions.
---

Execution starts when `/forge-run` is called and the plan is valid. Treat `.forge/PLAN.md` as the sole source of truth. Work tasks in order, record state and evidence after each task.

**Default: keep going.** Do not ask for permission mid-execution. Make the reasonable call and continue.

**Task owner + `loop_policy` together route execution** (read both fields from `.forge/TASKS.md` before starting a task):

- `Claude` + `loop_policy: none`: implement directly inline. No subagent spawn, no review dispatch. Record evidence and move on.
- `Claude` + `loop_policy: fixed:<N>` or `until-verified`: use the `superpowers:subagent-driven-development` skill — a fresh implementer subagent, followed by a task reviewer (spec compliance + code quality, checked against the plan's Loop contract, not just local diff quality), with its fix loop bounded by the task's cap (`fixed:<N>` → up to N rounds; `until-verified` → repeat until the task's verification command(s) pass, hard-capped at 5 rounds). This task-level review satisfies Forge's review requirement for Claude-owned work; do not additionally route these tasks through Codex review. Its workspace/ledger directory outside `.forge/` is expected execution output, not a scope violation.
- `Codex-investigate` / `Codex-setup`: dispatch via the `forge-codex-delegation` skill (`codex-dispatch.sh`), unchanged — these modes are read-only or isolated-setup and don't carry a review-fix loop.
- `Codex-review`: dispatch via `forge-codex-delegation`, unchanged.
- `Codex-implement` + `loop_policy: fixed:1`: dispatch implement, then exactly one review pass (`Codex-review` or Claude reading the diff directly) against the task deliverable and the Loop contract. No retry loop regardless of outcome — record the result (pass/fail) and, on fail, treat it like any other task failure (see Pause rules).
- `Codex-implement` + `loop_policy: fixed:<N>` (N>1) or `until-verified`: dispatch implement → review against the task deliverable and Loop contract → on failure, redispatch implement with the review's concrete feedback, up to N rounds (`fixed:<N>`) or until the verification command(s) pass, hard-capped at 5 rounds (`until-verified`). Bump `.forge/TASKS.md`'s `review_rounds` on every review dispatch; hitting the cap without success is a pause condition, not a silent stop.
- A sequence of `Codex-implement` tasks sharing the same `worktree` value in `.forge/TASKS.md` should be dispatched to that same path — do not invent a fresh path per task when the plan already assigned a shared one.

**Pause only for:**
- `sudo` or system/kernel/driver/package-manager changes
- Credential, token, SSH key, or auth file access
- New external login or paid service
- Large or unlisted dependency download
- Anything that could affect physical hardware
- A second consecutive failure with the same root cause
- A task's `loop_policy` round cap (`fixed:<N>` or `until-verified`'s 5-round hard cap) is reached without a passing review/verification
- Work clearly outside the approved plan scope

**Never:**
- Run physical robot commands (motor enable, deployment, policy launch, motion, teleoperation, actuators, networked hardware) — convert to human approval checklist
- Use Codex `danger-full-access` or sandbox bypass flags
- Mark a test as complete when it was not actually run — record as unverified

**At completion:** give a concise summary of what was done, evidence, anything unverified, and next steps.
