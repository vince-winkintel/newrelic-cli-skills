#!/bin/bash

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
HELPER="$REPO_ROOT/scripts/deployment-marker.sh"
TEST_TMP=$(mktemp -d "${TMPDIR:-/tmp}/deployment-marker-test.XXXXXX")
trap 'rm -rf "$TEST_TMP"' EXIT HUP INT TERM

FAKE_BIN="$TEST_TMP/bin"
INVOCATION_FILE="$TEST_TMP/invoked"
mkdir -p "$FAKE_BIN"
export INVOCATION_FILE

cat > "$FAKE_BIN/newrelic" <<'EOF'
#!/bin/bash
set -eu

: > "$INVOCATION_FILE"

if [ "$#" -ne 11 ] ||
   [ "$1" != "apm" ] ||
   [ "$2" != "deployment" ] ||
   [ "$3" != "create" ] ||
   [ "$4" != "--applicationId" ] ||
   [ "$5" != "$EXPECTED_APP_ID" ] ||
   [ "$6" != "--revision" ] ||
   [ "$7" != "$EXPECTED_REVISION" ] ||
   [ "$8" != "--description" ] ||
   [ "$9" != "$EXPECTED_DESCRIPTION" ] ||
   [ "${10}" != "--user" ] ||
   [ "${11}" != "$EXPECTED_USER" ]; then
  printf '%s\n' "deployment-marker.sh did not preserve the expected argv" >&2
  exit 64
fi
EOF
chmod +x "$FAKE_BIN/newrelic"

fail() {
  printf 'not ok - %s\n' "$1" >&2
  exit 1
}

pass() {
  printf 'ok - %s\n' "$1"
}

assert_rejected() {
  name=$1
  app_id=$2
  revision=$3
  description=$4
  user=$5

  rm -f "$INVOCATION_FILE"
  set +e
  PATH="$FAKE_BIN:$PATH" NEW_RELIC_API_KEY=test-key \
    "$HELPER" "$app_id" "$revision" "$description" "$user" \
    >"$TEST_TMP/output" 2>&1
  status=$?
  set -e

  [ "$status" -ne 0 ] || fail "$name: input was accepted"
  [ ! -e "$INVOCATION_FILE" ] || fail "$name: newrelic was invoked"
  pass "$name"
}

NEWLINE_VALUE=$(printf 'rev\ninjected')
TAB_VALUE=$(printf 'description	injected')
RETURN_VALUE=$(printf 'userinjected')

assert_rejected "rejects a nonnumeric application ID" "12x34" "rev" "description" "user"
assert_rejected "rejects control characters in revision" "1234" "$NEWLINE_VALUE" "description" "user"
assert_rejected "rejects control characters in description" "1234" "rev" "$TAB_VALUE" "user"
assert_rejected "rejects control characters in user" "1234" "rev" "description" "$RETURN_VALUE"

SENTINEL="$TEST_TMP/metacharacters-executed"
export SENTINEL
REVISION='rev; touch "$SENTINEL"'
DESCRIPTION='$(touch "$SENTINEL") `touch "$SENTINEL"`'
USER='deploy-bot && touch "$SENTINEL"'
export EXPECTED_APP_ID=1234 EXPECTED_REVISION="$REVISION"
export EXPECTED_DESCRIPTION="$DESCRIPTION" EXPECTED_USER="$USER"
rm -f "$INVOCATION_FILE" "$SENTINEL"

PATH="$FAKE_BIN:$PATH" NEW_RELIC_API_KEY=test-key \
  "$HELPER" "$EXPECTED_APP_ID" "$REVISION" "$DESCRIPTION" "$USER" \
  >"$TEST_TMP/output" 2>&1 || fail "literal metacharacter forwarding: helper failed"

[ -e "$INVOCATION_FILE" ] || fail "literal metacharacter forwarding: newrelic was not invoked"
[ ! -e "$SENTINEL" ] || fail "literal metacharacter forwarding: shell syntax was executed"
pass "forwards shell metacharacters as literal argv"
