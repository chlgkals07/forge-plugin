# Forge: Loop Engineering + Speed Optimization

Status: approved for implementation
Scope: this design covers only per-task loop policy (goal-bound review-fix
loops) and speed optimizations. Multi-CLI model adapters and cross-model
token-exhaustion handoff are explicitly out of scope — see "Future
directions" at the end.

## Goal and success criteria

- A user can run `/forge-run` on a deep plan, walk away, and come back to
  a result that has actually been checked against the plan's top-level
  Goal/success criteria for the tasks that matter — not just "task
  produced a diff."
- Trivial/low-risk tasks do not pay the cost of a full review-fix cycle
  or a fresh subagent/worktree when it isn't needed.
- Closeout does not redundantly re-run verification that already passed
  during task execution and has not been invalidated since.
- None of this weakens existing safety gates (physical-robot block, pause
  conditions, forbidden actions) in `SAFETY.md` / `forge-guard.sh`.

## Context and assumptions

- Current `forge-execution` skill always routes Claude-owned tasks
  through `superpowers:subagent-driven-development` (fresh implementer +
  reviewer subagent, fix loop) regardless of task risk, and treats that
  as the only place a review-fix loop exists. Codex-owned tasks have no
  standardized review-fix loop tied to the plan's Goal.
- `codex-dispatch.sh` already tolerates worktree reuse (it only runs
  `git worktree add` when the path doesn't already exist), but nothing
  in the planning/execution skills tells Claude to reuse a path across
  tasks, so in practice each implement task tends to get a fresh path.
- `forge-closeout.md` currently says "run all final verification
  commands," with no distinction between already-verified task-level
  evidence and integration-level checks — implying re-running
  everything.
- This is a single-user personal plugin; no backward-compat constraints
  beyond "don't break the existing `/forge`, `/forge-plan`, `/forge-run`,
  `/forge-status`, `/forge-closeout` flows."

## Alternatives considered and chosen approach

1. **Fixed global loop policy** (e.g., always review, or never review
   unless asked) — rejected: doesn't match "some tasks need it, some
   don't," and doesn't let the plan encode the decision once at planning
   time.
2. **User specifies loop policy per task in chat during planning** —
   rejected as the primary mechanism (too much manual overhead every
   plan) but still possible: since `loop_policy` is a plain field in
   `PLAN.md`/`TASKS.md`, a user can hand-edit it after Claude proposes
   values, or ask Claude to change one before approval.
3. **Chosen: Planner (Claude) assigns a `loop_policy` per task during
   plan authoring**, based on task risk/complexity, using explicit
   criteria written into `forge-planning`. Combined with reuse of
   worktrees and skip-if-already-verified at closeout for speed.

## Allowed scope

- Edit only files under `/home/hamin/.claude/plugins/cache/forge/forge/0.1.0/`:
  `templates/PLAN.md`, `templates/TASKS.md`, `skills/forge-planning/SKILL.md`,
  `skills/forge-execution/SKILL.md`, `skills/forge-codex-delegation/SKILL.md`,
  `commands/forge-closeout.md`.
- No changes to `scripts/*.sh` behavior are required for this design
  (worktree reuse already works; no new script logic needed). If a
  script change turns out to be required during implementation, treat it
  as new scope and pause to confirm.
- No changes to `codex-dispatch.sh`'s CLI, no new adapters, no handoff
  logic (future direction only).

## Forbidden / approval-required actions

- No physical-robot-related changes (n/a to this design).
- No change to `forge-guard.sh` approval semantics or the always-forbidden
  list in `SAFETY.md`.
- No change to the meaning of existing task owners
  (`Claude`/`Codex-investigate`/`Codex-setup`/`Codex-review`/`Codex-implement`).

## Environment constraints

- Plugin source lives outside any Git repository
  (`/home/hamin/.claude/plugins/cache/forge/forge/0.1.0`), so this work
  cannot use Git-based verification (diffs/commits) — verification is
  read-back-and-inspect on the edited Markdown files instead.

## Design

### 1. `loop_policy` field (new)

Added to both `templates/PLAN.md` (per `### T...` task) and
`templates/TASKS.md` (per task record):

```
- loop_policy: none | fixed:<N> | until-verified
```

Semantics:
- `none`: implement once, no dedicated review dispatch, move on. For
  Claude-owned tasks this also means **no subagent spawn** — Claude
  implements directly inline.
- `fixed:<N>`: implement → review against both the task's own
  deliverable AND the plan's Goal/success criteria (see Loop contract
  below) → if it fails, one more implement pass with concrete feedback,
  up to N review rounds. Default recommendation `N=2` when Planner
  doesn't have a stronger reason to pick otherwise.
- `until-verified`: repeat implement → review until the task's
  verification command(s) actually pass, hard-capped at 5 rounds. If the
  cap is hit, stop and pause per the existing "second consecutive
  failure, same root cause" rule in `SAFETY.md` / `forge-execution`.

Default when Planner assigns owner `Codex-implement`: minimum
`fixed:1` (never bare `none`) — a Codex-implement diff always gets at
least one look before being accepted, since there's no human in the
loop by default. `Claude`-owned tasks may be `none` when genuinely
trivial (typo fix, single config value, doc line).

### 2. Planner criteria for assigning `loop_policy` (forge-planning)

Written into `skills/forge-planning/SKILL.md` as explicit guidance the
Planner applies while building the task list:

- **`until-verified`**: task changes control/safety-relevant logic,
  touches multiple files/interfaces other tasks depend on, or is hard to
  reverse if wrong.
- **`fixed:2`** (default): typical implementation task — new function,
  bug fix, small feature slice — where a single review pass usually
  suffices but isn't guaranteed to.
  - Planner may pick `fixed:1` or `fixed:3+` when task history in this
    plan suggests otherwise (e.g., a task that's a straightforward
    continuation of an already-reviewed pattern → `fixed:1`).
- **`none`**: single-file, low-blast-radius, trivially verifiable by
  reading the diff (doc typo, comment, one-line config, renaming with no
  behavior change).

### 3. Loop contract section (PLAN.md)

New section in `templates/PLAN.md`, placed before `## Task list`:

```
## Loop contract
<!-- Copied/summarized from Goal and success criteria above. Every
     review dispatched for a task with loop_policy other than `none`
     must check the task's own deliverable AND this contract. -->
```

Planner fills this once per plan (usually a short restatement of the
Goal section's observable success conditions) so review prompts have a
single, stable reference instead of re-deriving "what does success mean"
from the whole plan each time.

### 4. Review-fix loop applies uniformly across owners (forge-execution)

`skills/forge-execution/SKILL.md` changes:

- Route by `loop_policy`, not by owner, for whether a review-fix cycle
  happens at all:
  - `Claude` + `loop_policy: none` → Claude implements directly, no
    subagent spawn.
  - `Claude` + `fixed:N`/`until-verified` → existing
    `subagent-driven-development` path (implementer subagent + reviewer
    subagent + fix loop), loop count bounded by the task's policy.
  - `Codex-implement` + `fixed:N`/`until-verified` → dispatch
    implement, then dispatch a `Codex-review` (or Claude review, see
    below) packet that checks the task deliverable + Loop contract; on
    failure, redispatch implement with the review's concrete feedback,
    up to N rounds / until verified (capped at 5).
  - `Codex-implement` + `fixed:1` → exactly one review pass, no retry
    loop.
- Track rounds in `TASKS.md`'s `- review_rounds: 0` field (new), bump on
  every review dispatch; compare against the task's `loop_policy` cap to
  decide continue vs. pause.

### 5. Review packet requirements (forge-codex-delegation)

`skills/forge-codex-delegation/SKILL.md`: review-mode packets must
include the Loop contract section verbatim (or a task-scoped excerpt) in
addition to the task's own verification command, and the return format
must state explicitly whether the Loop contract's success criteria are
met, not just whether the task's local deliverable looks right.

### 6. Worktree reuse for speed

`skills/forge-execution/SKILL.md` (or `forge-codex-delegation`) adds: for
a sequence of `Codex-implement` tasks that don't need isolation from each
other, the Planner should assign them the same `- worktree: <path>`
value in `TASKS.md`. `codex-dispatch.sh` already no-ops the `git worktree
add` when the path exists, so this is a planning-time convention, not a
script change. Tasks that need isolation (e.g., conflicting file
ranges, or one task's failure shouldn't contaminate another's tree) get
a distinct path — Planner decides this the same way it decides
`loop_policy`.

### 7. Closeout skip-if-verified (forge-closeout)

`commands/forge-closeout.md` changes: before re-running a verification
command, check `TASKS.md` for that task's evidence — if it already
recorded a pass for that exact command and no task touching overlapping
files/paths has run since, skip re-running it and cite the existing
evidence instead. Always run:
- verification commands with no prior recorded pass,
- integration-level checks (checks that only make sense once multiple
  tasks are combined — these have no meaningful "per-task" evidence to
  reuse),
- anything the plan's "Integration and final verification" section
  lists explicitly as closeout-only.

## Task list (for implementation)

### T1 — Add `loop_policy` (and `review_rounds`, `worktree`) fields to templates
- owner: Claude
- inputs / allowed paths: `templates/PLAN.md`, `templates/TASKS.md`
- expected deliverable: both templates show the new fields with inline
  comments explaining allowed values
- verification command(s): manual read-back; confirm `forge-guard.sh`'s
  `validate_plan`/`task_owner` awk/grep logic still matches (field
  addition must not break existing `## Task list` / `### T...` /
  `- owner:` regex expectations)
- fallback / pause condition: if adding fields would require changing
  `forge-guard.sh` parsing, stop and confirm scope before touching scripts
- loop_policy: none

### T2 — Write Planner loop_policy criteria into forge-planning
- owner: Claude
- inputs / allowed paths: `skills/forge-planning/SKILL.md`
- expected deliverable: explicit criteria section (as in Design §2) plus
  the Loop contract section requirement (Design §3) added to the plan
  schema description
- verification command(s): manual read-back for consistency with
  templates/PLAN.md
- fallback / pause condition: none expected
- loop_policy: none

### T3 — Rewrite forge-execution routing by loop_policy
- owner: Claude
- inputs / allowed paths: `skills/forge-execution/SKILL.md`
- expected deliverable: task-owner routing table replaced with
  owner+loop_policy routing (Design §4), worktree reuse guidance (Design
  §6) added
- verification command(s): manual read-back; cross-check against
  `forge-codex-delegation` and `forge-guard.sh` task_owner semantics for
  contradictions
- fallback / pause condition: if this conflicts with `forge-guard.sh`'s
  mode-to-owner allow list (investigate/review/setup/debug/implement),
  stop and confirm
- loop_policy: fixed:1

### T4 — Update forge-codex-delegation review packet requirements
- owner: Claude
- inputs / allowed paths: `skills/forge-codex-delegation/SKILL.md`
- expected deliverable: review packets required to check Loop contract
  (Design §5)
- verification command(s): manual read-back
- fallback / pause condition: none expected
- loop_policy: none

### T5 — Update forge-closeout skip-if-verified logic
- owner: Claude
- inputs / allowed paths: `commands/forge-closeout.md`
- expected deliverable: closeout text distinguishes already-verified
  task evidence from integration-only checks (Design §7)
- verification command(s): manual read-back
- fallback / pause condition: none expected
- loop_policy: none

### T6 — Cross-file consistency pass
- owner: Claude
- inputs / allowed paths: all files touched in T1-T5
- expected deliverable: no contradictions between PLAN.md/TASKS.md field
  names, forge-planning's criteria, forge-execution's routing, and
  forge-codex-delegation's packet requirements
- verification command(s): read all 5 changed files together; grep for
  `loop_policy`, `review_rounds`, `worktree` to confirm consistent usage
- fallback / pause condition: none expected
- loop_policy: fixed:1

## Integration and final verification

- Read all edited files together and confirm: (a) `forge-guard.sh`'s
  plan/task validation regex still matches the new template shape
  (headings unchanged, `### T...` format unchanged, `- owner:` line
  unchanged); (b) no file references a mechanism removed from another
  (e.g., forge-execution no longer says "Claude tasks always use
  subagent-driven-development" unconditionally); (c) `SAFETY.md`'s
  pause/forbidden list is unchanged and still consistent with the new
  pause-on-cap-exceeded behavior for `until-verified`.
- No automated test suite exists for this plugin (it's prompt/template
  content); verification is manual read-back plus the grep check above.

## Known risks and unverified items

- `forge-guard.sh` is not being modified in this pass; if a future task
  wants Forge to *enforce* (not just instruct) `loop_policy`/round caps
  programmatically, that's a script change, out of scope here.
- Effectiveness of the Planner's risk judgment (what counts as
  "trivial" vs "until-verified") is subjective and only validated by
  future usage, not by this design pass.
- Worktree reuse convention relies on the Planner correctly identifying
  which tasks are safe to share a path; no automated isolation check
  exists.

## Future directions (explicitly out of scope now)

- **Multi-CLI model adapters**: per-CLI adapter config (`exec_command`,
  `sandbox_map`, `resume_flag`, `quota_exhausted` patterns,
  `output_format`) so Gemini/Grok/etc. can serve as planner or operator,
  selected per user via a `.forge/MODELS.md`-style config. `codex-dispatch.sh`
  would generalize to a `model-dispatch.sh` reading the selected adapter.
- **Cross-model handoff on quota exhaustion**: dispatcher detects a
  quota-exhausted match (from the adapter's declared patterns) and
  retries the same task packet with the next model in the role's
  fallback order, logging the handoff in `WORKLOG.md`.
