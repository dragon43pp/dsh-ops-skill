#!/bin/sh
# dsh-doctor: metadata-only DeepSeek Harness runtime diagnostics.
# It never reads session bodies, settings values, credentials, provider URLs,
# raw Docker inspection data, or emits the selected state-root path.
set -u

PROGRAM="dsh-doctor"
CONTRACT_VERSION="2"
FORMAT="text"
FAILURES=0
WARNINGS=0

say() { printf '%s\n' "$*"; }
true_or_false() { "$@" >/dev/null 2>&1 && printf true || printf false; }

usage() {
  cat <<'EOF'
Usage:
  sh scripts/dsh-doctor.sh verify [--format text|json]
  sh scripts/dsh-doctor.sh contract [--format kv|json]
  sh scripts/dsh-doctor.sh snapshot <path>
  sh scripts/dsh-doctor.sh diff <baseline-contract> <candidate-contract> [--format text|json]

All commands are read-only. Snapshot writes a redacted key/value contract only
and refuses to overwrite an existing file. A diff exit code of 2 means tracked
invariants changed and require human review.
EOF
}

bad_usage() {
  say "ERROR $*" >&2
  usage >&2
  exit 64
}

parse_format() {
  if [ "$#" -eq 0 ]; then
    return 0
  fi
  if [ "$#" -eq 2 ] && [ "$1" = "--format" ]; then
    FORMAT="$2"
    return 0
  fi
  bad_usage "unexpected argument: $1"
}

resolve_state_root() {
  if [ -n "${DSH_HOME:-}" ]; then
    ROOT_ORIGIN="dsh_home"
    ROOT="$DSH_HOME"
  elif [ -n "${HOME:-}" ] && [ -d "$HOME/.dsh" ]; then
    ROOT_ORIGIN="home_existing"
    ROOT="$HOME/.dsh"
  elif [ -d /data/.dsh ]; then
    ROOT_ORIGIN="data_fallback"
    ROOT=/data/.dsh
  elif [ -n "${HOME:-}" ]; then
    ROOT_ORIGIN="home_default"
    ROOT="$HOME/.dsh"
  else
    ROOT_ORIGIN="unknown_default"
    ROOT=/unknown/.dsh
  fi
}

count_files() {
  if [ -d "$1" ]; then
    find "$1" -type f 2>/dev/null | wc -l | tr -d ' '
  else
    printf 0
  fi
}

present() {
  if [ -e "$1" ]; then printf true; else printf false; fi
}

directory_present() {
  if [ -d "$1" ]; then printf true; else printf false; fi
}

command_present() {
  if command -v "$1" >/dev/null 2>&1; then printf true; else printf false; fi
}

socket_present() {
  if [ -S "${DSH_DOCTOR_DOCKER_SOCKET_PATH:-/var/run/docker.sock}" ]; then
    printf true
  else
    printf false
  fi
}

detect_hash_algorithm() {
  if command -v sha256sum >/dev/null 2>&1; then
    HASH_ALGORITHM="sha256sum"
  elif command -v shasum >/dev/null 2>&1; then
    HASH_ALGORITHM="shasum-sha256"
  else
    HASH_ALGORITHM="cksum-fallback"
  fi
}

hash_text() {
  case "$HASH_ALGORITHM" in
    sha256sum) printf '%s' "$1" | sha256sum | awk '{print $1}' ;;
    shasum-sha256) printf '%s' "$1" | shasum -a 256 | awk '{print $1}' ;;
    cksum-fallback) printf '%s' "$1" | cksum | awk '{print $1 "-" $2}' ;;
    *) return 1 ;;
  esac
}

collect_contract() {
  ROOT_ORIGIN=""
  ROOT=""
  resolve_state_root
  detect_hash_algorithm
  ROOT_FINGERPRINT="$(hash_text "$ROOT")"
  STATE_ROOT_PRESENT="$(directory_present "$ROOT")"
  SETTINGS_PRESENT="$(present "$ROOT/settings.yaml")"
  PROFILES_PRESENT="$(directory_present "$ROOT/profiles")"
  SESSIONS_PRESENT="$(directory_present "$ROOT/sessions")"
  STORAGES_PRESENT="$(directory_present "$ROOT/storages")"
  SESSION_FILE_COUNT="$(count_files "$ROOT/sessions")"
  PROFILE_FILE_COUNT="$(count_files "$ROOT/profiles")"
  ARTIFACT_FILE_COUNT="$(count_files "$ROOT")"
  NODE_PRESENT="$(command_present node)"
  BASH_PRESENT="$(command_present bash)"
  DSH_PRESENT="$(command_present dsh)"
  BWRAP_PRESENT="$(command_present bwrap)"
  DOCKER_SOCKET_PRESENT="$(socket_present)"
}

contract_kv() {
  collect_contract
  cat <<EOF
dsh_doctor_contract_version=$CONTRACT_VERSION
root_origin=$ROOT_ORIGIN
state_root_fingerprint_algorithm=$HASH_ALGORITHM
state_root_fingerprint=$ROOT_FINGERPRINT
state_root_present=$STATE_ROOT_PRESENT
settings_present=$SETTINGS_PRESENT
profiles_present=$PROFILES_PRESENT
sessions_present=$SESSIONS_PRESENT
storages_present=$STORAGES_PRESENT
session_file_count=$SESSION_FILE_COUNT
profile_file_count=$PROFILE_FILE_COUNT
artifact_file_count=$ARTIFACT_FILE_COUNT
node_present=$NODE_PRESENT
bash_present=$BASH_PRESENT
dsh_present=$DSH_PRESENT
bwrap_present=$BWRAP_PRESENT
docker_socket_present=$DOCKER_SOCKET_PRESENT
EOF
}

contract_json() {
  collect_contract
  cat <<EOF
{"contract_version":$CONTRACT_VERSION,"root_origin":"$ROOT_ORIGIN","state_root_fingerprint_algorithm":"$HASH_ALGORITHM","state_root_fingerprint":"$ROOT_FINGERPRINT","state_root_present":$STATE_ROOT_PRESENT,"settings_present":$SETTINGS_PRESENT,"profiles_present":$PROFILES_PRESENT,"sessions_present":$SESSIONS_PRESENT,"storages_present":$STORAGES_PRESENT,"session_file_count":$SESSION_FILE_COUNT,"profile_file_count":$PROFILE_FILE_COUNT,"artifact_file_count":$ARTIFACT_FILE_COUNT,"node_present":$NODE_PRESENT,"bash_present":$BASH_PRESENT,"dsh_present":$DSH_PRESENT,"bwrap_present":$BWRAP_PRESENT,"docker_socket_present":$DOCKER_SOCKET_PRESENT}
EOF
}

record_check() {
  # $1 key; $2 boolean; $3 severity when absent (fail|warn)
  key="$1"
  value="$2"
  severity="$3"
  if [ "$value" = true ]; then
    [ "$FORMAT" = text ] && say "OK    $key"
  elif [ "$severity" = warn ]; then
    WARNINGS=$((WARNINGS + 1))
    [ "$FORMAT" = text ] && say "WARN  $key"
  else
    FAILURES=$((FAILURES + 1))
    [ "$FORMAT" = text ] && say "FAIL  $key"
  fi
}

verify_text_header() {
  say "DSH Doctor v$CONTRACT_VERSION (metadata-only)"
  say "State root selected: <redacted> (origin=$ROOT_ORIGIN)"
  say "State-root fingerprint: $ROOT_FINGERPRINT"
}

verify() {
  case "$FORMAT" in text|json) ;; *) bad_usage "verify format must be text or json" ;; esac
  collect_contract
  FAILURES=0
  WARNINGS=0
  [ "$FORMAT" = text ] && verify_text_header

  record_check "state_root_present" "$STATE_ROOT_PRESENT" fail
  record_check "settings_present" "$SETTINGS_PRESENT" fail
  record_check "profiles_present" "$PROFILES_PRESENT" fail
  record_check "sessions_present" "$SESSIONS_PRESENT" fail
  record_check "storages_present" "$STORAGES_PRESENT" fail
  record_check "node_present" "$NODE_PRESENT" fail
  record_check "bash_present" "$BASH_PRESENT" fail
  record_check "dsh_present" "$DSH_PRESENT" fail
  record_check "bwrap_present" "$BWRAP_PRESENT" fail

  if [ "$BWRAP_PRESENT" = true ] && [ "${DSH_DOCTOR_RUN_SANDBOX:-0}" = 1 ]; then
    if bwrap --ro-bind / / --proc /proc --dev /dev --unshare-pid /bin/true >/dev/null 2>&1; then
      [ "$FORMAT" = text ] && say "OK    bubblewrap_smoke_test"
      BWRAP_SMOKE="passed"
    else
      FAILURES=$((FAILURES + 1))
      [ "$FORMAT" = text ] && say "FAIL  bubblewrap_smoke_test"
      BWRAP_SMOKE="failed"
    fi
  else
    WARNINGS=$((WARNINGS + 1))
    [ "$FORMAT" = text ] && say "WARN  bubblewrap_smoke_test (skipped; set DSH_DOCTOR_RUN_SANDBOX=1 to opt in)"
    BWRAP_SMOKE="skipped"
  fi

  if [ "$DOCKER_SOCKET_PRESENT" = true ]; then
    WARNINGS=$((WARNINGS + 1))
    [ "$FORMAT" = text ] && say "WARN  docker_socket_present (host-privileged; do not expose to untrusted users)"
  else
    [ "$FORMAT" = text ] && say "OK    docker_socket_absent"
  fi

  if [ "$FORMAT" = json ]; then
    status="pass"
    [ "$FAILURES" -gt 0 ] && status="fail"
    cat <<EOF
{"doctor_version":$CONTRACT_VERSION,"status":"$status","failures":$FAILURES,"warnings":$WARNINGS,"bubblewrap_smoke_test":"$BWRAP_SMOKE","contract":{"root_origin":"$ROOT_ORIGIN","state_root_fingerprint_algorithm":"$HASH_ALGORITHM","state_root_fingerprint":"$ROOT_FINGERPRINT","state_root_present":$STATE_ROOT_PRESENT,"settings_present":$SETTINGS_PRESENT,"profiles_present":$PROFILES_PRESENT,"sessions_present":$SESSIONS_PRESENT,"storages_present":$STORAGES_PRESENT,"session_file_count":$SESSION_FILE_COUNT,"profile_file_count":$PROFILE_FILE_COUNT,"artifact_file_count":$ARTIFACT_FILE_COUNT,"node_present":$NODE_PRESENT,"bash_present":$BASH_PRESENT,"dsh_present":$DSH_PRESENT,"bwrap_present":$BWRAP_PRESENT,"docker_socket_present":$DOCKER_SOCKET_PRESENT}}
EOF
  elif [ "$FAILURES" -gt 0 ]; then
    say "Result: FAIL ($FAILURES failure(s), $WARNINGS warning(s))"
  else
    say "Result: PASS ($WARNINGS warning(s))"
  fi

  [ "$FAILURES" -eq 0 ]
}

snapshot() {
  target="$1"
  [ -n "$target" ] || bad_usage "snapshot path is required"
  [ -e "$target" ] && { say "ERROR snapshot already exists: refusing to overwrite" >&2; exit 73; }
  parent=$(dirname "$target")
  [ -d "$parent" ] || { say "ERROR snapshot parent directory does not exist" >&2; exit 73; }
  umask 077
  contract_kv >"$target" || { rm -f "$target"; say "ERROR unable to write snapshot" >&2; exit 74; }
  say "Snapshot written: $target (redacted contract only)"
}

contract_value() {
  file="$1"
  key="$2"
  awk -F= -v wanted="$key" '
    $1 == wanted { if (found) exit 2; print substr($0, index($0, "=") + 1); found = 1 }
    END { if (!found) exit 1 }
  ' "$file"
}

TRACKED_KEYS="dsh_doctor_contract_version root_origin state_root_fingerprint_algorithm state_root_fingerprint state_root_present settings_present profiles_present sessions_present storages_present session_file_count profile_file_count artifact_file_count node_present bash_present dsh_present bwrap_present docker_socket_present"

validate_contract() {
  file="$1"
  [ -f "$file" ] || return 1
  for key in $TRACKED_KEYS; do
    value=$(contract_value "$file" "$key") || return 1
    [ -n "$value" ] || return 1
  done
  [ "$(contract_value "$file" dsh_doctor_contract_version)" = "$CONTRACT_VERSION" ] || return 1
  return 0
}

diff_contracts() {
  baseline="$1"
  candidate="$2"
  case "$FORMAT" in text|json) ;; *) bad_usage "diff format must be text or json" ;; esac
  validate_contract "$baseline" || { say "ERROR invalid baseline contract" >&2; exit 64; }
  validate_contract "$candidate" || { say "ERROR invalid candidate contract" >&2; exit 64; }

  changed=""
  changed_count=0
  for key in $TRACKED_KEYS; do
    before=$(contract_value "$baseline" "$key")
    after=$(contract_value "$candidate" "$key")
    if [ "$before" != "$after" ]; then
      changed_count=$((changed_count + 1))
      changed="$changed $key"
      [ "$FORMAT" = text ] && say "CHANGED $key (values redacted)"
    fi
  done

  if [ "$FORMAT" = json ]; then
    printf '{"contract_version":%s,"status":"' "$CONTRACT_VERSION"
    if [ "$changed_count" -eq 0 ]; then printf 'unchanged'; else printf 'changed'; fi
    printf '","changed_count":%s,"changed_keys":[' "$changed_count"
    separator=""
    for key in $changed; do
      printf '%s"%s"' "$separator" "$key"
      separator="," 
    done
    printf ']}\n'
  elif [ "$changed_count" -eq 0 ]; then
    say "Result: UNCHANGED (no tracked invariant changed)"
  else
    say "Result: REVIEW ($changed_count tracked invariant(s) changed)"
  fi

  [ "$changed_count" -eq 0 ] && return 0
  return 2
}

MODE="${1:-verify}"
[ "$#" -gt 0 ] && shift

case "$MODE" in
  verify)
    parse_format "$@"
    verify
    ;;
  contract)
    parse_format "$@"
    case "$FORMAT" in
      kv|text) contract_kv ;;
      json) contract_json ;;
      *) bad_usage "contract format must be kv or json" ;;
    esac
    ;;
  snapshot)
    [ "$#" -ge 1 ] || bad_usage "snapshot path is required"
    target="$1"
    shift
    [ "$#" -eq 0 ] || bad_usage "snapshot accepts exactly one path"
    snapshot "$target"
    ;;
  diff)
    [ "$#" -ge 2 ] || bad_usage "diff requires baseline and candidate contracts"
    baseline="$1"
    candidate="$2"
    shift 2
    parse_format "$@"
    diff_contracts "$baseline" "$candidate"
    ;;
  help|--help|-h)
    usage
    ;;
  *)
    bad_usage "unknown command: $MODE"
    ;;
esac
