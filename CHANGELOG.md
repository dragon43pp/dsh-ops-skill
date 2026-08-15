# Changelog

All notable changes to `dsh-ops-skill` are documented here. The project follows a lightweight, evidence-first release policy: a release records only behavior and documentation that have been reviewed for public redaction and reproducibility.

## [Unreleased]

### Added

- Versioned, metadata-only key/value and JSON runtime contracts.
- Non-reversible state-root fingerprints and root-selection origin reporting without path disclosure.
- Protected private snapshots and redacted contract comparisons with explicit review exit code `2`.
- An isolated POSIX-shell regression suite covering contract fields, JSON output, snapshot overwrite protection, diff semantics, redaction, and failure states.
- Public CI coverage for shell syntax and the no-network regression suite.

### Planned

- Community-submitted, fully redacted compatibility reports.

## [0.1.0] — 2026-08-15

### Added

- A portable `SKILL.md` for DSH and folder-based agent systems.
- `scripts/dsh-doctor.sh`, a metadata-only verifier with `verify` and `contract` modes.
- State-contract and symptom-remediation reference documentation.
- A least-privilege Compose state-persistence overlay.
- English-first documentation with a Simplified Chinese guide.
- Architecture, synthetic demonstration, compatibility boundary, security policy, contribution guide, and redaction-focused issue template.

### Security

- The public project does not contain deployment credentials, private endpoints, session content, container IDs, internal paths, or provider configuration values.
- Privileged mode, Docker Socket access, and `SYS_ADMIN` are not recommended or enabled by default.

[Unreleased]: https://github.com/dragon43pp/dsh-ops-skill/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/dragon43pp/dsh-ops-skill/releases/tag/v0.1.0
