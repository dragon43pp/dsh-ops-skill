# Demonstration: diagnose a blank-instance upgrade safely



This walkthrough is synthetic. Host names, provider names, paths, session counts, and error strings are illustrative; no customer deployment data, conversation data, credentials, or container metadata is used.



## Symptom



After recreating a DSH service, the web UI responds successfully but shows a fresh-looking session sidebar and no expected model routes. The first temptation is to copy files from an old volume into the new container. Do not do that.



The symptom is ambiguous. It can mean lost state, but it can also mean that the new process is resolving a different state root because `HOME`, `DSH_HOME`, mount destinations, or its launcher context changed.



## Step 1 — capture metadata only



```sh

sh scripts/dsh-doctor.sh contract

```



Example output:



```text

dsh_doctor_contract_version=1

state_root_present=true

settings_present=true

profiles_present=true

sessions_present=true

storages_present=true

bash_present=true

bwrap_present=true

docker_socket_present=false

```



This output is intentionally small. It confirms presence, not content. Store the before/after output privately when comparing an existing and a candidate runtime.



## Step 2 — verify the candidate before repair



```sh

sh scripts/dsh-doctor.sh verify

```



Illustrative failure pattern:



```text

DSH Doctor (metadata-only)

State root: /state

OK    state root exists

FAIL  state artifact missing: profiles

FAIL  state artifact missing: sessions

FAIL  state artifact missing: storages

OK    command available: node

OK    command available: bash

OK    command available: dsh

WARN  Bubblewrap execution skipped; set DSH_DOCTOR_RUN_SANDBOX=1 for a no-write smoke test

OK    Docker Socket not detected

Result: FAIL (3 failure(s), 1 warning(s))

```



The key finding is not “the data is gone.” It is that the candidate’s selected state root does not contain the expected artifact shape. The response should be to compare the original and candidate launch contracts—not to write into `/state`.



## Step 3 — formulate the smallest reversible plan



A safe change proposal should answer all four questions:



| Question | Example answer |

|---|---|

| What changed? | The candidate resolves `/state`; the baseline used a different persistent mount destination. |

| What will be changed? | Recreate the candidate with the baseline `HOME`/`DSH_HOME` semantics and intended state mount destination. |

| What will not be changed? | No session files, settings values, credential files, or state databases will be copied or edited. |

| How will rollback work? | Preserve the baseline instance and start it again if the candidate fails state-artifact or browser-visible checks. |



Only an operator should authorize the change.



## Step 4 — validate recovery



After the candidate starts, rerun the doctor. If code execution is part of the deployment requirement, enable the optional no-write sandbox smoke test explicitly:



```sh

DSH_DOCTOR_RUN_SANDBOX=1 sh scripts/dsh-doctor.sh verify

```



Then validate the browser surface without exposing any conversation body:



1. Confirm that expected **session metadata** is visible.
2. 
2. Confirm that expected **model route identifiers** are available.
3. 
3. Confirm the required **workspace** opens correctly.
4. 
4. Confirm the intended **code-mode** behavior through a harmless command.
5. 


## Why this is safer than a one-click repair



A blank instance can be a state-selection failure, not a state-loss event. Automated copying can create a second, partially valid state tree and make rollback harder. The purpose of this Skill is to turn an ambiguous incident into evidence, a reversible plan, and an explicit verification gate.



See [Architecture](architecture.md) for the full reliability loop and [Remediation Playbooks](../references/remediation-playbooks.md) for additional symptom paths.





