# Changelog

All notable, public-safe changes to this project will be documented in this file. The format follows the spirit of [Keep a Changelog](https://keepachangelog.com/), with an emphasis on reproducibility, compatibility boundaries, and redaction.

## [0.1.0] — 2026-08-15

### Added

- A portable, agent-readable SKILL.md for diagnosing DeepSeek Harness runtime-state failures.
- A metadata-only dsh-doctor with read-only verification and state-contract modes.
- State-contract guidance, symptom-to-recovery playbooks, and a minimum-permission Compose overlay.
- English-first documentation, a Simplified Chinese guide, architecture notes, synthetic demonstration, and compatibility matrix.
- A redaction-focused issue template, contribution guidance, MIT license, security policy, and public roadmap.

### Security posture

- No default Docker Socket mount, privileged mode, SYS_ADMIN capability, public bind, or automatic state copy.
- No published credentials, private endpoints, host information, session content, settings values, or raw inspection output.

### Verification boundary

- The project documents evidence and reversible recovery planning; it does not certify DSH versions, provider configuration, or privileged deployment safety.

[0.1.0]: https://github.com/dragon43pp/dsh-ops-skill/releases/tag/v0.1.0
