#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
DOCTOR="$ROOT/scripts/dsh-doctor.sh"
TMP=$(mktemp -d "${TMPDIR:-/tmp}/dsh-doctor-test.XXXXXX")
trap 'rm -rf "$TMP"' EXIT HUP INT TERM

pass_count=0
fail() {
  printf 'FAIL %s\n' "$*" >&2
  exit 1
}
pass() {
  pass_count=$((pass_count + 1))
  printf 'ok %s\n' "$1"
}
assert_contains() {
  value="$1"
  expected="$2"
  label="$3"
  printf '%s' "$value" | grep -F "$expected" >/dev/null 2>&1 || fail "$label: expected '$expected'"
  pass "$label"
}
assert_not_contains() {
  value="$1"
  unexpected="$2"
  label="$3"
  if printf '%s' "$value" | grep -F "$unexpected" >/dev/null 2>&1; then
    fail "$label: unexpectedly exposed '$unexpected'"
  fi
  pass "$label"
}
expect_status() {
  expected="$1"
  shift
  set +e
  "$@" >/dev/null 2>&1
  actual=$?
  set -e
  [ "$actual" -eq "$expected" ] || fail "expected status $expected, got $actual: $*"
  pass "exit status $expected: $1"
}

mkdir -p "$TMP/state/profiles" "$TMP/state/sessions" "$TMP/state/storages" "$TMP/bin"
: >"$TMP/state/settings.yaml"
: >"$TMP/state/profiles/web.patch.yml"
: >"$TMP/state/sessions/session.meta"
: >"$TMP/state/storages/index.meta"

for command in node bash dsh bwrap; do
  cat >"$TMP/bin/$command" <<'EOF'
#!/bin/sh
exit 0
EOF
  chmod +x "$TMP/bin/$command"
done

export PATH="$TMP/bin:$PATH"
export DSH_HOME="$TMP/state"
export DSH_DOCTOR_DOCKER_SOCKET_PATH="$TMP/not-a-socket"

contract=$(sh "$DOCTOR" contract)
assert_contains "$contract" "dsh_doctor_contract_version=2" "contract version"
assert_contains "$contract" "root_origin=dsh_home" "contract root origin"
assert_contains "$contract" "session_file_count=1" "contract session count"
assert_not_contains "$contract" "$TMP/state" "contract redacts state path"

json=$(sh "$DOCTOR" contract --format json)
assert_contains "$json" '"contract_version":2' "contract JSON version"
assert_contains "$json" '"root_origin":"dsh_home"' "contract JSON origin"
assert_not_contains "$json" "$TMP/state" "contract JSON redacts state path"

sh "$DOCTOR" snapshot "$TMP/baseline.contract" >/dev/null
pass "snapshot creates baseline"
expect_status 73 sh "$DOCTOR" snapshot "$TMP/baseline.contract"

: >"$TMP/state/profiles/second.patch.yml"
sh "$DOCTOR" snapshot "$TMP/candidate.contract" >/dev/null
pass "snapshot creates candidate"
expect_status 2 sh "$DOCTOR" diff "$TMP/baseline.contract" "$TMP/candidate.contract"
diff_json=$(sh "$DOCTOR" diff "$TMP/baseline.contract" "$TMP/candidate.contract" --format json || true)
assert_contains "$diff_json" '"status":"changed"' "diff JSON changed status"
assert_contains "$diff_json" '"profile_file_count"' "diff reports changed invariant"
assert_not_contains "$diff_json" "$TMP/state" "diff redacts state path"

expect_status 0 sh "$DOCTOR" diff "$TMP/baseline.contract" "$TMP/baseline.contract"
: >"$TMP/invalid.contract"
expect_status 64 sh "$DOCTOR" diff "$TMP/invalid.contract" "$TMP/candidate.contract"

rm "$TMP/state/settings.yaml"
verify_json=$(sh "$DOCTOR" verify --format json || true)
assert_contains "$verify_json" '"status":"fail"' "verify JSON failure status"
assert_contains "$verify_json" '"settings_present":false' "verify JSON missing setting"
assert_not_contains "$verify_json" "$TMP/state" "verify JSON redacts state path"

printf 'PASS %s regression checks\n' "$pass_count"
