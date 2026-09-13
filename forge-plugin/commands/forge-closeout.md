---
description: Perform final verification and write a human-readable Forge closeout.
disable-model-invocation: true
---

Run `${CLAUDE_PLUGIN_ROOT}/scripts/forge-status.sh --closeout` and inspect the approved plan, task records, worklog, Codex results, and evidence.

For each verification command in the plan: if `.forge/TASKS.md` already records a passing result for that exact command under a task, and no task touching overlapping files/paths has run since that evidence was recorded, skip re-running it and cite the existing evidence instead. Always run (never skip): verification commands with no prior recorded pass, integration-level checks that only make sense once multiple tasks are combined (these have no per-task evidence to reuse), and anything `## Integration and final verification` in the plan lists as closeout-only. Explicitly record each command that could not run.

Trigger an independent read-only Codex review when the plan requires it or when Claude made a meaningful multi-file/control/safety change. Do not declare completion while required evidence is absent, a review has unresolved critical findings, or a test is unverified. Append the result, risks, and remaining unverified items to `.forge/WORKLOG.md` and present the closeout.
