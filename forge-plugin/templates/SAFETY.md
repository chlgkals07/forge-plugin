# Forge local safety boundaries

## Always prohibited from autonomous execution

- Physical robot motor enable, deployment, policy launch, motion, teleoperation, actuator, or networked hardware control.
- Deleting repositories, environments, data, or user files.
- sudo, driver/kernel/system package-manager, or shell initialization changes.
- Disabling sandbox/approval safeguards or Codex unrestricted permissions.
- Exposing, moving, printing, or committing credentials, tokens, SSH keys, or auth files.

## Pause and ask

Plan-external work; new dependency or large download; external login, paid service, or branch-strategy change; two failures with the same root-cause hypothesis; verification failure requiring architecture change; any hardware ambiguity.

## Approval

Only the exact standalone phrase `계획 확정. 자율 실행해.` approves the current normalized plan. Approval never overrides the always-prohibited list.
