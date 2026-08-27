---
name: forge-execution
description: Execute one approved Forge plan continuously, pausing only for genuinely dangerous actions.
---

Execution starts when `/forge-run` is called and the plan is valid. Treat `.forge/PLAN.md` as the sole source of truth. Work tasks in order, record state and evidence after each task.

**Default: keep going.** Do not ask for permission mid-execution. Make the reasonable call and continue.

**Pause only for:**
- `sudo` or system/kernel/driver/package-manager changes
- Credential, token, SSH key, or auth file access
- New external login or paid service
- Large or unlisted dependency download
- Anything that could affect physical hardware
- A second consecutive failure with the same root cause
- Work clearly outside the approved plan scope

**Never:**
- Run physical robot commands (motor enable, deployment, policy launch, motion, teleoperation, actuators, networked hardware) — convert to human approval checklist
- Use Codex `danger-full-access` or sandbox bypass flags
- Mark a test as complete when it was not actually run — record as unverified

**At completion:** give a concise summary of what was done, evidence, anything unverified, and next steps.
