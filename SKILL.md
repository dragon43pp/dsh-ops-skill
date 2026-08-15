---
name: dsh-ops-skill
description: Diagnose and safely remediate DeepSeek Harness (DSH) deployment, session, model-routing, sandbox, and container-upgrade issues. Use when DSH shows empty sessions or missing models, Bash/Bubblewrap tools fail, a container upgrade changes behavior, or an agent must inspect a DSH runtime before proposing a fix.
---

# DeepSeek Harness Operations Skill

## Purpose

Diagnose DSH runtime failures without exposing credentials, private model endpoints, conversation content, or internal host details. Prefer read-only evidence first. Treat a repair as a separate, explicitly approved step.

Run `scripts/dsh-doctor.sh` before proposing a deployment change. Read `references/remediation-playbooks.md` only for the matching symptom.

## Guardrails

1. Never print, commit, upload, or paraphrase API keys, credentials files, private model URLs, internal IP addresses, Docker inspect output containing environment secrets, or session contents.
2. Do not delete state, run `docker compose down --volumes`, remove volumes, or rebuild a production container unless the user explicitly approves the exact action and a rollback path exists.
3. Do not enable Docker Socket, `--privileged`, `SYS_ADMIN`, or a broad network bind as a default repair. Explain the risk, isolate it in an explicit opt-in overlay, and verify least privilege first.
4. Preserve the DSH state contract during every upgrade: the same state root, settings, profiles, credentials, sessions, storage, workspace policy, entrypoint, and intended runtime user.
5. Keep diagnosis output metadata-only. Report counts and paths; never read or summarize chat transcripts.

## Fast Workflow

### 1. Identify the symptom

Classify the incident before editing anything.

| Symptom | First hypothesis |
|---|---|
| Empty sidebar, missing model routes, fresh settings | State root changed, commonly `HOME` or `DSH_HOME` drifted during container recreation. |
| `spawn bash ENOENT` | The runtime image lacks Bash or the configured shell path. |
| `SANDBOX_UNAVAILABLE` or Bubblewrap namespace failure | The runner binary, kernel feature, seccomp profile, or capability set is incompatible with the selected sandbox mode. |
| Model timeout, 401, short/truncated replies | Route, base URL, credential reference, timeout, or max-token configuration drifted. |
| Service is up but Web UI is blank/broken | Wrong entrypoint, workdir, profile, trusted-host option, asset/runtime mismatch, or state profile failure. |

### 2. Capture read-only evidence

Run:

```sh
sh scripts/dsh-doctor.sh verify
```

When inspecting a Docker deployment, collect a **redacted contract manifest**. Compare only these fields between the old and candidate containers:

- image digest or tag;
- entrypoint, command, workdir, user, restart policy, and network mode;
- state and workspace mount destinations, not host paths;
- presence of `HOME` and `DSH_HOME`, without values that reveal private locations;
- DSH state artifacts: `settings.yaml`, `profiles/`, `sessions/`, and `storages/`;
- Bash and sandbox runner availability;
- HTTP health response.

Use `docker inspect` only under a redaction procedure. Never paste the full inspect output into an issue, public log, or prompt.

### 3. Make the smallest reversible repair

Choose a playbook from `references/remediation-playbooks.md`. Before an image or container replacement:

1. Save a redacted pre-change contract manifest.
2. Preserve the state volume or bind mount.
3. Preserve `HOME`/`DSH_HOME` semantics and the workdir.
4. Preserve the real entrypoint and command rather than inheriting a base-image default.
5. Start a candidate on an isolated port when possible.
6. Verify HTTP health, state artifacts, model configuration presence, and one safe sandbox invocation.
7. Keep the old container available until all checks pass.

### 4. Verify the user-facing recovery

After the repair, confirm all of the following:

- the UI loads after a hard refresh;
- the intended workspace is selected;
- existing session metadata is visible;
- expected model routes appear in Settings;
- a harmless Code Mode task can list files and create then remove a temporary file in the approved workspace.

Do not claim that history is restored solely because a service returns HTTP 200. Confirm the state root and session metadata first.

## Public Issue Template

For an upstream discussion, publish only a minimal reproduction: DSH version, OS/container base, redacted state-root contract, exact non-sensitive error, expected behavior, and a proposed documentation improvement. Do not publish company integrations, credentials, internal addresses, private workspaces, or raw session data.

## Repository Resources

- `scripts/dsh-doctor.sh` — dependency-light, metadata-only preflight and runtime verifier.
- `references/remediation-playbooks.md` — symptom-to-repair guidance.
- `references/state-contract.md` — upgrade invariants and redaction rules.
- `examples/compose.state-safe.yaml` — safe Compose pattern; intentionally omits privileged execution and Docker Socket access.
