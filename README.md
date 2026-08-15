# DSH Ops Skill

[中文指南](docs/README.zh-CN.md) · [Architecture](docs/architecture.md) · [Demo](docs/demo.md) · [Compatibility](docs/compatibility.md) · [Roadmap](ROADMAP.md) · [Security](SECURITY.md)

> **The upgrade-safety and runtime-reliability kit for DeepSeek Harness.**
>
> Prove the state contract, diagnose blank-instance failures without exposing sensitive data, and plan the smallest reversible recovery before an upgrade becomes an incident.

DSH Ops Skill is an English-first, portable operational Skill for [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) and other folder-based agent systems. It turns empty session sidebars, missing model routes, spawn bash ENOENT, unavailable sandbox backends, and container upgrade drift into a disciplined **evidence → plan → validation** workflow.

It is intentionally **not** a privileged Docker wrapper, automatic state copier, or official DeepSeek plugin. The repository provides an AI-readable SKILL.md, a metadata-only doctor, recovery playbooks, a least-privilege Compose overlay, and public-safe documentation for Claude Code, Codex, OpenCode, DSH, or similar folder-based Skill systems.

## The operating principle

~~~mermaid
flowchart LR
    A[Capture redacted baseline] --> B[Verify candidate state contract]
    B --> C[Plan the smallest reversible repair]
    C --> D[Operator approval]
    D --> E[Validate browser-visible recovery]
~~~

A DSH service can return HTTP 200 while behaving like a fresh installation. That does not prove state was lost: a new runtime may resolve a different root because HOME, DSH_HOME, a mount destination, the entrypoint, or the workdir changed. This project treats those values as a **state contract** that must be proven before the runtime is replaced or repaired.

| It helps you establish | It deliberately never does |
|---|---|
| Whether the selected state root contains expected artifacts. | Read chats, prompts, session bodies, credentials, or settings values. |
| Whether Bash and Bubblewrap are present in the actual runtime. | Enable privileged mode, Docker Socket access, or SYS_ADMIN by default. |
| Whether a candidate launch contract differs from the baseline. | Copy session files into a guessed destination or overwrite state automatically. |
| Whether a recovery should proceed, stop, or roll back. | Present an incident workaround as a generic security recommendation. |

## 60-second quick start

~~~sh
git clone https://github.com/dragon43pp/dsh-ops-skill.git
cd dsh-ops-skill
sh scripts/dsh-doctor.sh verify
~~~

To emit a compact, non-secret state contract for a private before/after comparison:

~~~sh
sh scripts/dsh-doctor.sh contract
~~~

To run the optional **no-write** Bubblewrap smoke test, explicitly opt in:

~~~sh
DSH_DOCTOR_RUN_SANDBOX=1 sh scripts/dsh-doctor.sh verify
~~~

The doctor reports filesystem presence and executable availability only. It does **not** read session contents, settings values, credential values, model base URLs, Docker inspection output, or storage databases.

## Documentation and evidence

| Document | Purpose |
|---|---|
| [Architecture](docs/architecture.md) | Defines the state contract, evidence loop, and default security posture. |
| [Demonstration](docs/demo.md) | Shows a synthetic blank-instance incident from detection to validation. |
| [Compatibility](docs/compatibility.md) | Separates verified scope, expected scope, and unverified deployment forms. |
| [Remediation Playbooks](references/remediation-playbooks.md) | Maps symptoms to smallest reversible recovery paths. |
| [State Contract](references/state-contract.md) | Lists upgrade invariants and public redaction rules. |
| [Compose overlay](examples/compose.state-safe.yaml) | Makes state and workspace paths explicit without adding privileged defaults. |
| [Roadmap](ROADMAP.md) | States planned work and explicit non-goals. |

## Use as an Agent Skill

Add this folder to an agent skill directory, or attach SKILL.md with its scripts and references directories to the agent task context. Start with this instruction:

> Use the DSH Ops Skill to inspect this DeepSeek Harness deployment. Start in read-only mode. Do not change containers, state volumes, credentials, capabilities, or provider settings until you present a redacted diagnosis and rollback plan.

## Security and compatibility

DSH is in developer preview and can introduce compatibility-breaking changes. This project publishes evidence and boundaries rather than blanket compatibility claims; review the [Compatibility Matrix](docs/compatibility.md) before applying it outside a tested Linux container deployment.

The Compose overlay makes state and workspace paths explicit while setting no-new-privileges and dropping Linux capabilities. It intentionally does **not** add an image, startup command, public port, Docker Socket mount, privileged mode, or SYS_ADMIN. The project is a community companion in the DSH ecosystem; it uses the dsh-plugin topic for discoverability but does not claim official endorsement or implement an official DSH plugin API.

Never commit API keys, tokens, passwords, private URLs, IP addresses, internal DNS names, private paths, container IDs, session logs, prompts, screenshots containing conversations, or raw Docker inspection data. See [SECURITY.md](SECURITY.md) and [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT. See [LICENSE](LICENSE).
