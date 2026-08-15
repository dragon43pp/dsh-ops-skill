# Contributing

Thanks for improving DSH Ops Skill.

## Before Opening an Issue

1. Use the latest `main` branch.
2. Run `sh scripts/dsh-doctor.sh verify`.
3. Reproduce the issue with a pinned DSH version.
4. Remove all secrets and private infrastructure information.

A useful issue includes the DSH version, OS/container base, redacted state-contract output, exact non-sensitive error, expected behavior, and actual behavior. Do not attach session logs or settings files.

## Pull Requests

Keep contributions dependency-light and portable across common POSIX shell environments. New checks must be metadata-only by default and must not perform container mutations, write to state, contact third-party services, or read session content.

Document every new check in English. Add Chinese text when changing user-facing workflow documentation.

## Scope

Good contributions include reproducible deployment checks, safer rollback guidance, redaction improvements, compatibility notes, and test coverage. Out of scope: bundled credentials, private provider integrations, organization-specific deployment scripts, default Docker Socket support, privileged container recipes, or public-network exposure examples.
