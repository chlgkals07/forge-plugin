---
description: Perform final verification and write a human-readable Forge closeout.
disable-model-invocation: true
---

Run `${CLAUDE_PLUGIN_ROOT}/scripts/forge-status.sh --closeout` and inspect the approved plan, task records, worklog, Codex results, and evidence. Run all final verification commands listed in the plan (or explicitly record each command that could not run). Trigger an independent read-only Codex review when the plan requires it or when Claude made a meaningful multi-file/control/safety change. Do not declare completion while required evidence is absent, a review has unresolved critical findings, or a test is unverified. Append the result, risks, and remaining unverified items to `.forge/WORKLOG.md` and present the closeout.
