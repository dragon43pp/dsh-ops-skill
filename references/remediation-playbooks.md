# Remediation Playbooks



Use this file only after running `scripts/dsh-doctor.sh verify`. Capture a redacted before/after contract before changing a deployment.



## Empty Sessions, Missing Models, or Fresh Settings



**Likely cause:** the new runtime booted from a different `HOME` or `DSH_HOME`, or the state volume was not mounted at the path selected by the launcher.



1. Stop before writing to the new empty state directory.
2. 
2. Identify the previous state mount and its intended in-container state root.
3. 
3. Check that the existing state root contains `settings.yaml`, `profiles/`, `sessions/`, and `storages/`.
4. 
4. Recreate the candidate with the same `HOME`/`DSH_HOME` semantics and state mount destination.
5. 
5. Preserve the previous container until the candidate passes HTTP, state-artifact, and model-route presence checks.
6. 
6. Hard-refresh the UI and select the original workspace before declaring recovery complete.
7. 


Do not copy session files into a newly guessed path. Correct the launch contract first.



## `spawn bash ENOENT`



**Likely cause:** the image has no Bash or the shell executor points to a missing executable.



1. Confirm the actual process image, not merely the host image.
2. 
2. Install Bash in a derived image rather than mutating a live container.
3. 
3. Preserve the original entrypoint, command, workdir, user, environment, and mounts when rebuilding.
4. 
4. Test `bash --version` in an isolated candidate before replacing the running service.
5. 


Do not solve this by silently switching the agent to unrestricted `sh`; that changes the tool contract and may break code-mode expectations.



## Bubblewrap or Local Sandbox Unavailable



**Likely cause:** `bwrap` is absent, user namespaces are unavailable, or the Docker seccomp/capability profile blocks namespace creation.



1. Confirm `bwrap --version`.
2. 
2. Run the doctor with `DSH_DOCTOR_RUN_SANDBOX=1` for a no-write test.
3. 
3. Inspect the selected DSH sandbox backend and its fail-closed error.
4. 
4. Prefer a separate, narrowly-scoped runner or host-level sandbox support.
5. 
5. If a capability or seccomp change is unavoidable, make it an explicit opt-in deployment overlay, document its threat model, and keep it disabled by default.
6. 


Never make `--privileged`, Docker Socket, or `SYS_ADMIN` a generic recommendation for public deployments.



## Model Route Failure, 401, Timeout, or Truncation



**Likely cause:** provider configuration did not load from the expected state root, a credential reference differs, or runtime limits changed.



1. Verify the state root before touching model settings.
2. 
2. Check only provider identifiers, model identifiers, and non-secret limits; never print credentials or base URLs from a public support log.
3. 
3. Compare the old and candidate provider configuration layer order.
4. 
4. Validate one low-cost non-sensitive completion against the target route.
5. 
5. Record the configured max-token and timeout values along with the observed finish reason.
6. 


## Upgrade or Rebuild Safety Contract



Before replacing a container, compare these redacted fields with the candidate:



- image tag/digest;
- 
- entrypoint and command;
- 
- workdir and runtime user;
- 
- state and workspace mount destinations;
- 
- `HOME` and `DSH_HOME` presence;
- 
- port and trusted-host configuration;
- 
- state artifact presence;
- 
- Bash and sandbox smoke-test result.
- 


Keep the old instance stopped but available until the candidate passes all checks. Roll back by starting the preserved instance; do not recreate it from memory.





























