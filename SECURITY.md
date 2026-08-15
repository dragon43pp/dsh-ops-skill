# Security Policy

## Supported Versions

The `main` branch is the supported development version until tagged releases exist.

## Reporting a Vulnerability

Do not open a public issue for a vulnerability that could expose a DSH Web UI, execute code on an untrusted host, reveal credentials, or enable container escape.

Instead, contact the repository maintainer privately through the security contact listed in the repository settings. Include a minimal reproduction with all keys, tokens, URLs, internal addresses, workspace names, session data, and Docker inspect output removed.

## Public-Safety Rules

This repository must not accept examples that:

- enable `--privileged`, Docker Socket, or Linux capabilities by default;
- bind an unauthenticated DSH Web UI to a public network interface;
- include real credentials, environment dumps, private endpoints, or internal infrastructure identifiers;
- export or inspect conversation/session content as part of diagnostics.

The doctor script is intentionally metadata-only. High-privilege execution patterns belong in private, environment-specific operational documentation with a reviewed threat model, not in this public repository.
