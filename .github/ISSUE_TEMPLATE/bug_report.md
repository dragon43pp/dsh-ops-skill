---

name: Bug report

about: Report a reproducible, fully redacted DSH operations issue

title: "[bug]: "

labels: bug

---



## Summary



Describe the DSH symptom in one sentence.



## Expected behavior



What should have happened?



## Actual behavior



What happened instead? Include the exact non-sensitive error if available.



## Environment



- DSH version:
- 
- Host OS / container base:
- 
- Deployment type: Docker / Compose / Kubernetes / bare process
- 
- Agent surface: DSH Web / Headless / another agent using this Skill
- 


## Redacted doctor output



Paste output from:



```sh

sh scripts/dsh-doctor.sh contract

```



## Reproduction steps



List the smallest safe reproduction.



## Security checklist



- [ ] I removed API keys, tokens, passwords, and credential-file content.
- [ ] 
- [ ] I removed private URLs, IP addresses, DNS names, host paths, workspace names, and container IDs.
- [ ] 
- [ ] I did not attach session logs, prompts, screenshots containing conversations, or raw Docker inspect output.
- [ ] 







