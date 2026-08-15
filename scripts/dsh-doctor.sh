#!/bin/sh

# dsh-doctor: metadata-only DeepSeek Harness runtime preflight.

# It never reads session content, settings values, credentials, or Docker state.

set -u



MODE="${1:-verify}"

FAILURES=0

WARNINGS=0



say() { printf '%s\n' "$*"; }

ok() { say "OK    $*"; }

warn() { WARNINGS=$((WARNINGS + 1)); say "WARN  $*"; }

fail() { FAILURES=$((FAILURES + 1)); say "FAIL  $*"; }



state_root() {

  if [ -n "${DSH_HOME:-}" ]; then
  
    printf '%s\n' "$DSH_HOME"
    
  elif [ -n "${HOME:-}" ] && [ -d "$HOME/.dsh" ]; then
  
    printf '%s\n' "$HOME/.dsh"
    
  elif [ -d /data/.dsh ]; then
  
    printf '%s\n' /data/.dsh
    
  else
  
    printf '%s\n' "${HOME:-/unknown}/.dsh"
    
  fi
  
}



count_files() {

  find "$1" -type f 2>/dev/null | wc -l | tr -d ' '
  
}



check_command() {

  if command -v "$1" >/dev/null 2>&1; then
  
    ok "command available: $1"
    
  else
  
    fail "command missing: $1"
    
  fi
  
}



verify() {

  ROOT="$(state_root)"
  
  say "DSH Doctor (metadata-only)"
  
  say "State root: $ROOT"
  
  say "HOME configured: $([ -n "${HOME:-}" ] && printf yes || printf no)"
  
  say "DSH_HOME configured: $([ -n "${DSH_HOME:-}" ] && printf yes || printf no)"
  


  if [ -d "$ROOT" ]; then
  
    ok "state root exists"
    
  else
  
    fail "state root does not exist; verify HOME/DSH_HOME and the persistent mount"
    
  fi
  


  for item in settings.yaml profiles sessions storages; do
  
    if [ -e "$ROOT/$item" ]; then
    
      ok "state artifact present: $item"
      
    else
    
      fail "state artifact missing: $item"
      
    fi
    
  done
  


  if [ -d "$ROOT/sessions" ]; then
  
    say "Session log files: $(count_files "$ROOT/sessions")"
    
  fi
  
  if [ -d "$ROOT/profiles" ]; then
  
    say "Profile files: $(count_files "$ROOT/profiles")"
    
  fi
  


  check_command node
  
  check_command bash
  
  check_command dsh
  


  if command -v bwrap >/dev/null 2>&1; then
  
    ok "command available: bwrap"
    
    if [ "${DSH_DOCTOR_RUN_SANDBOX:-0}" = "1" ]; then
    
      if bwrap --ro-bind / / --proc /proc --dev /dev --unshare-pid /bin/true >/dev/null 2>&1; then
      
        ok "Bubblewrap smoke test passed"
        
      else
      
        fail "Bubblewrap smoke test failed; inspect kernel user namespaces, seccomp, and capabilities"
        
      fi
      
    else
    
      warn "Bubblewrap execution skipped; set DSH_DOCTOR_RUN_SANDBOX=1 for a no-write smoke test"
      
    fi
    
  else
  
    fail "command missing: bwrap; confined workspace-write Bash cannot run on this host"
    
  fi
  


  if [ -S /var/run/docker.sock ]; then
  
    warn "Docker Socket is mounted; treat this runtime as host-privileged and do not expose it to untrusted users"
    
  else
  
    ok "Docker Socket not detected"
    
  fi
  


  if [ "$FAILURES" -gt 0 ]; then
  
    say "Result: FAIL ($FAILURES failure(s), $WARNINGS warning(s))"
    
    return 1
    
  fi
  
  say "Result: PASS ($WARNINGS warning(s))"
  
  return 0
  
}



contract() {

  ROOT="$(state_root)"
  
  say "dsh_doctor_contract_version=1"
  
  say "state_root_present=$([ -d "$ROOT" ] && printf true || printf false)"
  
  say "settings_present=$([ -f "$ROOT/settings.yaml" ] && printf true || printf false)"
  
  say "profiles_present=$([ -d "$ROOT/profiles" ] && printf true || printf false)"
  
  say "sessions_present=$([ -d "$ROOT/sessions" ] && printf true || printf false)"
  
  say "storages_present=$([ -d "$ROOT/storages" ] && printf true || printf false)"
  
  say "bash_present=$(command -v bash >/dev/null 2>&1 && printf true || printf false)"
  
  say "bwrap_present=$(command -v bwrap >/dev/null 2>&1 && printf true || printf false)"
  
  say "docker_socket_present=$([ -S /var/run/docker.sock ] && printf true || printf false)"
  
}



case "$MODE" in

  verify) verify ;;
  
  contract) contract ;;
  
  *)
  
    say "Usage: sh dsh-doctor.sh {verify|contract}"
    
    exit 64
    
    ;;
    
esac



















































































