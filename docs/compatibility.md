# Compatibility and Verification Status



DeepSeek Harness is in developer preview and its runtime behavior can change quickly. This project therefore publishes **verification evidence and boundaries**, not blanket compatibility promises.



## Current compatibility matrix



| Surface | Status | Scope | Evidence required before promotion |

|---|---|---|---|

| Folder-based agent skill systems | Expected | Claude Code, Codex, OpenCode, DSH, and similar systems that can load `SKILL.md` with its bundled files. | Agent can read `SKILL.md` and invoke the bundled shell script from its workspace. |

| POSIX `/bin/sh` | Verified by design | `scripts/dsh-doctor.sh` uses POSIX shell syntax and does not require Bash for its own execution. | Run `sh scripts/dsh-doctor.sh verify`. |

| DSH runtime state contract | Verified concept | State-root, profile, session, storage, executable, and Socket-presence checks. | Redacted before/after contract plus browser-visible validation. |

| Bash availability diagnosis | Verified by design | Detects a missing `bash` executable; it does not install Bash. | Doctor output and isolated candidate test. |

| Bubblewrap availability diagnosis | Verified by design | Detects `bwrap`; optional smoke test is disabled unless `DSH_DOCTOR_RUN_SANDBOX=1`. | Explicit no-write smoke-test result. |

| Docker Compose overlay | Example only | Explicit state/workspace paths, `no-new-privileges`, and `cap_drop: ALL`. | Rendered `docker compose config` reviewed by the operator. |

| Docker Socket, privileged mode, `SYS_ADMIN` | Not a default | Never supplied by the public overlay or doctor. | A deployment-specific threat model and explicit operator approval. |

| Kubernetes, Nomad, systemd, non-Linux runtimes | Unverified | May use the same contract ideas but need runtime-specific examples. | Reproducible, fully redacted community report and review. |



## Verification protocol



A compatibility report must distinguish **observed** behavior from **expected** behavior. Use this sequence:



1. Record the DSH version or commit and deployment form, without publishing private image registries or host paths.
2. 
2. Run `sh scripts/dsh-doctor.sh contract` before and after a candidate replacement; keep any full environment details private.
3. 
3. State whether the candidate shows expected session metadata, model-route identifiers, and workspace behavior in the browser.
4. 
4. If code mode matters, run the optional no-write Bubblewrap smoke test and state the result.
5. 
5. Open an Issue only with fully redacted output and the smallest safe reproduction.
6. 


## What this project does not certify



This repository does not certify that a particular DSH build is production-ready, that any provider configuration is correct, that an existing session can be restored from arbitrary files, or that a privileged sandbox profile is safe. It does not read provider settings, session content, credentials, or storage databases to make such claims.



## Reporting a new environment



Use the included [issue template](../.github/ISSUE_TEMPLATE/bug_report.md). A useful compatibility contribution includes the following public-safe fields:



| Field | Example public-safe value |

|---|---|

| DSH release | `developer-preview build <redacted>` |

| Host family | `Linux container host` |

| Deployment form | `Compose with named volume` |

| Doctor result | `verify: pass; sandbox smoke test: skipped` |

| Browser validation | `session metadata and model identifiers visible` |

| Limitations | `No privileged capabilities tested` |



Never include access tokens, private URLs, IP addresses, internal DNS names, container IDs, private paths, session logs, prompts, screenshots containing conversations, or raw Docker inspection output.






