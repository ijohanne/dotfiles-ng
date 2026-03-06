#!/usr/bin/env bash
set -euo pipefail

SOURCE_HOST="${1:-delirium.unixpimps.net}"
TARGET_HOST="${2:-pakhet.est.unixpimps.net}"
SOURCE_LOCAL_PORT=15984
TARGET_LOCAL_PORT=25984
DUMP_FILE=$(mktemp /tmp/opsplaza-couchdb-XXXXXX.json)

# Fetch couchdb-dump tool
COUCHDB_DUMP_DIR=$(mktemp -d /tmp/couchdb-dump-XXXXXX)
curl -sL "https://raw.githubusercontent.com/danielebailo/couchdb-dump/master/couchdb-dump.sh" \
  -o "${COUCHDB_DUMP_DIR}/couchdb-dump.sh"

cleanup() {
  # Kill SSH tunnels by finding them via port
  lsof -ti ":${SOURCE_LOCAL_PORT}" 2>/dev/null | xargs kill 2>/dev/null || true
  lsof -ti ":${TARGET_LOCAL_PORT}" 2>/dev/null | xargs kill 2>/dev/null || true
  rm -f "$DUMP_FILE"
  rm -rf "$COUCHDB_DUMP_DIR"
}
trap cleanup EXIT

echo "Opening SSH tunnel to source: ${SOURCE_HOST}..."
ssh -fNL "${SOURCE_LOCAL_PORT}:127.0.0.1:5984" "$SOURCE_HOST"

echo "Opening SSH tunnel to target: ${TARGET_HOST}..."
ssh -fNL "${TARGET_LOCAL_PORT}:127.0.0.1:5984" "$TARGET_HOST"

sleep 2

echo "Verifying tunnels..."
curl -sf "http://127.0.0.1:${SOURCE_LOCAL_PORT}/" > /dev/null || { echo "ERROR: Cannot reach source CouchDB"; exit 1; }
curl -sf "http://127.0.0.1:${TARGET_LOCAL_PORT}/" > /dev/null || { echo "ERROR: Cannot reach target CouchDB"; exit 1; }
echo "Both tunnels active."

rm -f "$DUMP_FILE"
echo "Dumping themailer database from source..."
bash "${COUCHDB_DUMP_DIR}/couchdb-dump.sh" \
  -b -H 127.0.0.1 -P "$SOURCE_LOCAL_PORT" -d themailer -f "$DUMP_FILE"

echo "Creating themailer database on target..."
curl -s -X PUT "http://127.0.0.1:${TARGET_LOCAL_PORT}/themailer" || true

echo "Restoring themailer database to target..."
bash "${COUCHDB_DUMP_DIR}/couchdb-dump.sh" \
  -r -H 127.0.0.1 -P "$TARGET_LOCAL_PORT" -d themailer -f "$DUMP_FILE"

echo "Migration complete. Verify: curl http://127.0.0.1:${TARGET_LOCAL_PORT}/themailer"
