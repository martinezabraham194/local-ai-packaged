#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <service> <port>"
  exit 2
fi

service="$1"
port="$2"

echo "Probing $service:$port from caddy..."

if docker exec caddy wget -O- --spider "http://$service:$port" >/dev/null 2>&1; then
  echo "OK: $service reachable from caddy:$port"
  exit 0
else
  echo "FAIL: $service not reachable from caddy:$port"
  echo
  echo "DNS resolution inside caddy:"
  docker exec caddy sh -c "nslookup $service 2>/dev/null || getent hosts $service || cat /etc/hosts"
  echo
  echo "caddy last 50 log lines:"
  docker logs caddy --tail 50 || true
  exit 1
fi
