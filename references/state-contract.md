# DSH State Contract

A DSH container is replaceable only when its state contract is preserved. State is not limited to a volume name: launcher context determines which persistent directory DSH reads.

## Invariants

| Area | Preserve | Verify without exposing secrets |
|---|---|---|
| State root | `HOME` and/or `DSH_HOME` semantics, state mount destination | Check state artifact existence and file counts. |
| Profile | profile names, bundle order, patch locations | Check profile directories and patch file presence. |
| Model configuration | settings and credential references | Check provider/model identifiers only. |
| Conversations | append-only session logs and projection storage | Count files and confirm UI metadata; never read chat content. |
| Workspace | approved workspace mount, runtime user, workdir | Check mount destination and a temporary approved-workspace write test. |
| Process | entrypoint, command, runtime user, port/trusted-host configuration | Compare redacted values before and after replacement. |
| Sandbox | executable availability and host compatibility | Run a no-write sandbox smoke test when explicitly enabled. |

## Machine-Readable Contract

`dsh-doctor contract` emits a versioned, redacted contract in key/value format; `--format json` emits the same public-safe fields as JSON. The contract includes the root-selection origin, a one-way state-root fingerprint, required-artifact booleans, bounded file counts, command availability, and Docker Socket presence. It never emits the state-root value, settings values, session content, endpoint URLs, credential values, or Docker inspection data.

Use protected private snapshots to compare an old runtime with an isolated candidate:

```sh
sh scripts/dsh-doctor.sh snapshot /secure/path/before.contract
sh scripts/dsh-doctor.sh snapshot /secure/path/candidate.contract
sh scripts/dsh-doctor.sh diff /secure/path/before.contract /secure/path/candidate.contract
```

The snapshot command refuses to overwrite an existing file. A `diff` exit code of `0` means no tracked invariant changed; exit code `2` means tracked invariants changed and requires human review. A stable HTTP response must not override a `REVIEW` result.

## Redaction Rules

Never publish any of the following in a GitHub issue, README, CI log, sample output, image, or support request:

- API keys, bearer tokens, password strings, credential file contents, or environment variable values;
- private model base URLs, internal DNS, IP addresses, repository paths, workspace names, or container IDs;
- Docker Socket paths when they reveal a deployment architecture;
- session logs, prompts, tool outputs, screenshots containing conversations, or storage database dumps.

Publish only generic paths such as `/state`, `/workspace`, or `<state-root>` and generic model identifiers such as `provider-a/model-x`.

## Safe Upgrade Sequence

1. Save a private `dsh-doctor snapshot` from the current runtime.
2. Build the candidate image with a pinned DSH version.
3. Start the candidate on an isolated port or isolated environment.
4. Restore the state contract explicitly, including `HOME`/`DSH_HOME`, mount destinations, workdir, entrypoint, and command.
5. Save a candidate snapshot and run `dsh-doctor diff`; stop for human review on exit code `2`.
6. Run `dsh-doctor verify` and the no-write sandbox test if applicable.
7. Confirm the UI shows expected session metadata and model routes.
8. Replace the service only after the previous instance is retained as a rollback target.

## Public Compose Baseline

The public example intentionally provides persistence and health checks, but does not enable privileged mode, Docker Socket, extra capabilities, or public network exposure. Treat those as deployment-specific decisions requiring a separate threat model.
