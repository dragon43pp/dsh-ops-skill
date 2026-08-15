# Roadmap



`dsh-ops-skill` is a focused runtime-reliability project. The roadmap favors **verified recovery behavior** over broad but unmaintained feature lists.



## v0.1 — Public reliability baseline



- [x] Publish a portable `SKILL.md` for folder-based agent systems.
- [ ] 
- [x] Publish a metadata-only `dsh-doctor` with `verify` and `contract` modes.
- [ ] 
- [x] Document the state contract, remediation playbooks, and least-privilege Compose baseline.
- [ ] 
- [x] Add English-first documentation with a Simplified Chinese guide.
- [ ] 
- [x] Add a redaction-focused issue template, contribution guidance, and a security policy.
- [ ] 
- [ ] Publish an annotated release note after the public documentation is reviewed.
- [ ] 


## v0.2 — Evidence quality and reproducibility



- [ ] Add a synthetic test fixture for state-root drift and blank-instance symptoms.
- [ ] 
- [ ] Add a contract-diff format that is safe to share in an Issue after redaction.
- [ ] 
- [ ] Add a no-network shell syntax and Markdown-link validation workflow.
- [ ] 
- [ ] Publish verified, fully redacted compatibility reports from distinct deployment forms.
- [ ] 


## v0.3 — Deployment-specific guidance



- [ ] Add reviewed examples for Compose variants without relaxing the default least-privilege posture.
- [ ] 
- [ ] Add platform-specific state-contract guidance only when it can be tested and documented without secrets.
- [ ] 
- [ ] Evaluate a Kubernetes-oriented contract example if a reproducible public fixture is available.
- [ ] 


## Non-goals



The project will not become a generic orchestration framework, an unauthenticated remote-management service, a credential migration tool, a Docker Socket wrapper, or a one-click state copier. These goals increase operational risk and distract from the central promise: **prove the runtime contract before attempting a reversible repair**.



## How to influence the roadmap



Open a fully redacted Issue with the smallest safe reproduction and `dsh-doctor contract` output. The most useful requests demonstrate a repeatable failure mode, identify the affected runtime surface, and explain how a metadata-only check could detect it earlier.














