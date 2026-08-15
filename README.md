# DSH Ops Skill

[中文指南](docs/README.zh-CN.md) · [Security](SECURITY.md) · [Contributing](CONTRIBUTING.md)

> **Stop DeepSeek Harness upgrades from booting as a blank instance.**

`dsh-ops-skill` is a portable operational Skill for agents and humans running [DeepSeek Harness (DSH)](https://github.com/deepseek-ai/deepseek-harness). It helps diagnose and safely remediate empty session sidebars, missing model routes, broken Bash/Bubblewrap execution, container upgrade drift, and rollback failures.

It is deliberately **not** a privileged Docker wrapper. The repository ships an AI-readable `SKILL.md`, a dependency-light metadata-only doctor, safe deployment guidance, and a Compose state-contract overlay. Use it from Claude Code, Codex, OpenCode, DSH, or any agent system that can load a folder-based skill.

## Why This Exists

A DSH container can return HTTP 200 while still behaving like a new installation. Profiles, model settings, credentials, session logs, and storage are loaded relative to the DSH state root. If a rebuild changes `HOME`, `DSH_HOME`, a state mount destination, the entrypoint, or the workdir, the UI can show empty sessions and missing model routes even though the original volume still exists.

This skill turns that failure mode into a repeatable workflow:

1. inspect metadata before changing anything;
2. prove the state root and state artifacts are present;
3. compare the old and candidate runtime contract;
4. make the smallest reversible repair;
5. verify the browser-visible recovery, model routes, and code sandbox.

## Quick Start

```sh
git clone https://github.com/<YOUR_GITHUB_HANDLE>/dsh-ops-skill.git
cd dsh-ops-skill
sh scripts/dsh-doctor.sh verify
```

To test Bubblewrap with a no-write command:

```sh
DSH_DOCTOR_RUN_SANDBOX=1 sh scripts/dsh-doctor.sh verify
```

To emit a small, non-secret state contract for pre/post-upgrade comparison:

```sh
sh scripts/dsh-doctor.sh contract
```

The doctor does **not** read chat transcripts, settings values, credentials, Docker inspect output, or session contents.

## Install as an Agent Skill

Add this folder to your agent's skill directory or attach `SKILL.md` and its bundled `scripts/` and `references/` directories to the agent's task context. The primary entry point is:

```text
SKILL.md
```

Tell the agent:

> Use the DSH Ops Skill to inspect this DeepSeek Harness deployment. Run the doctor in read-only mode first. Do not change containers, state volumes, or credentials until you present a redacted diagnosis and rollback plan.

## What It Diagnoses

| Symptom | What the Skill Checks First |
|---|---|
| Empty sessions, fresh Settings, missing models | State root, `HOME`/`DSH_HOME`, `settings.yaml`, profiles, sessions, and storage. |
| `spawn bash ENOENT` | Bash presence in the actual runtime image. |
| `SANDBOX_UNAVAILABLE` | Bubblewrap availability plus an optional no-write namespace smoke test. |
| Model 401, timeout, or truncation | State/profile loading order and non-secret route configuration metadata. |
| Upgrade regression | Entrypoint, command, workdir, state/workspace mounts, and rollback contract. |

## Repository Layout

```text
SKILL.md                              # Agent instructions and guardrails
scripts/dsh-doctor.sh                 # Read-only verifier and contract summary
references/remediation-playbooks.md   # Symptom-specific repair playbooks
references/state-contract.md           # Upgrade invariants and redaction rules
examples/compose.state-safe.yaml      # Compose overlay for explicit state persistence
docs/README.zh-CN.md                  # Chinese guide
```

## Safe Compose Pattern

Merge [`examples/compose.state-safe.yaml`](examples/compose.state-safe.yaml) into your existing Compose service. It makes the state root explicit and separates it from the workspace. It intentionally does **not** add Docker Socket, privileged mode, `SYS_ADMIN`, a public network bind, an image, or a startup command.

```sh
DSH_STATE_DIR=$PWD/.dsh-state DSH_WORKSPACE=$PWD \
  docker compose -f compose.yaml -f examples/compose.state-safe.yaml config
```

Review the rendered configuration before applying it. Preserve your existing entrypoint, command, user, port policy, and trusted-host settings.

## Security Model

This project is designed for **single-tenant, trusted operator environments**. DSH can invoke tools and execute code; do not expose an unauthenticated DSH Web UI to the public Internet.

Never commit or share:

- API keys, tokens, passwords, credential files, or model base URLs;
- private IPs, internal DNS, container IDs, workspace names, or host paths;
- session logs, prompts, screenshots with conversations, or Docker inspect dumps;
- a Docker Socket mount or high-capability deployment as a default example.

See [SECURITY.md](SECURITY.md) for reporting and disclosure rules.

## Compatibility

DSH is in developer preview and changes quickly. Pin a DSH version in each deployment, run the doctor before and after upgrades, and report compatibility results through issues. The skill targets the runtime contract rather than a single DSH release.

## Contributing

Issues and pull requests are welcome for generic, reproducible, fully redacted cases. Please use the issue template and never attach private deployment output. See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT. See [LICENSE](LICENSE).
