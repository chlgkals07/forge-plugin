<!-- forge-status: draft -->
<!-- forge-approval: pending -->
# <project/task title>

## Goal and success criteria
<!-- State observable success conditions. -->

## Context and assumptions

## Alternatives considered and chosen approach

## Allowed scope
<!-- Exact repositories, branches, directories, and operations. -->

## Forbidden / approval-required actions
- Physical robot commands are always forbidden to autonomous execution.
- sudo, system changes, credentials, new login, and plan-external work require a pause and human approval.

## Environment constraints

## Loop contract
<!-- Restate the observable success conditions from "Goal and success
     criteria" above, in a form a review dispatch can check directly.
     Every task with loop_policy other than `none` must be reviewed
     against this contract, not just its own local deliverable. -->

## Task list
### T1 — <title>
- owner: Claude
- inputs / allowed paths: <paths>
- expected deliverable: <deliverable>
- verification command(s): <command>
- fallback / pause condition: <condition>
- loop_policy: none | fixed:<N> | until-verified
<!-- none: implement once, no review dispatch (Claude tasks: no subagent spawn).
     fixed:<N>: implement -> review vs Loop contract -> up to N feedback/redo rounds.
     until-verified: repeat until verification passes, hard-capped at 5 rounds, then pause.
     Codex-implement tasks: minimum fixed:1, never bare none. -->
- worktree: <path, optional>
<!-- Only for Codex-implement tasks. Reuse the same path across tasks that
     don't need isolation from each other; codex-dispatch.sh no-ops the
     worktree creation when the path already exists. -->

## Integration and final verification

## Known risks and unverified items
- None known; update this section as evidence arrives.
