#!/bin/sh
# Verify N8N Cloudflare Tunnel origin via Caddy (127.0.0.1:81)
HOST="${HOST:-n8n.marzhome.com}"
ORIGIN="${ORIGIN:-http://127.0.0.1:81/}"
TMP_BODY="$(mktemp)"
status=$(curl -s -o "$TMP_BODY" -w "%{http_code}" --header "Host: $HOST" "$ORIGIN") || {
  echo "ERROR: curl failed"
  rm -f "$TMP_BODY"
  exit 2
}
echo "HTTP $status"
if [ "$status" -eq 200 ] || [ "$status" -eq 301 ] || [ "$status" -eq 302 ]; then
  if grep -qi "n8n" "$TMP_BODY"; then
    echo "OK: n8n content detected"
    rm -f "$TMP_BODY"
    exit 0
  else
    echo "WARN: expected n8n content not found (status $status)"
    rm -f "$TMP_BODY"
    exit 3
  fi
else
  echo "FAIL: unexpected status $status"
  rm -f "$TMP_BODY"
  exit 4
fi
