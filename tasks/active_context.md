Investigation: Unable to access openwebui.marzhome.com and n8n.marzhome.com via Cloudflare Tunnel.

Summary:
- Symptoms: 502 Bad Gateway in Caddy logs for openwebui and n8n when accessed via cloud tunnel domains.
- Root cause: docker-compose.yml had hardcoded extra_hosts entries in the caddy service pointing to stale container IPs. This overrode Docker DNS and caused Caddy to try connecting to incorrect IPs.
- Fix applied:
  - Removed stale extra_hosts entries from docker-compose.yml.
  - Recreated the caddy container to apply changes.
  - Added scripts/verify_caddy_service_resolution.sh to probe Caddy->service connectivity.
- Verification:
  - From inside the caddy container, wget to open-webui:8080 and n8n:5678 succeeded.
  - curl with Host headers to localhost:81 for openwebui.marzhome.com and n8n.marzhome.com returned HTTP 200.
- Next steps:
  - Monitor caddy logs for errors for 5-10 minutes.
  - If anything regresses, revert the docker-compose.yml changes and investigate service-specific health.

Commands used:
- netstat -plnt | grep LISTEN
- docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
- docker network inspect local-ai-packaged_default --format '{{range .Containers}}{{.Name}}: {{.IPv4Address}}{{"\n"}}{{end}}'
- docker exec caddy wget -O- --spider http://172.20.0.10:8080
- docker exec caddy wget -O- --spider http://172.20.0.15:5678
- docker logs caddy --tail 50
- docker compose -f docker-compose.yml up -d --no-deps --force-recreate caddy
- ./scripts/verify_caddy_service_resolution.sh open-webui 8080
- ./scripts/verify_caddy_service_resolution.sh n8n 5678
- curl -v -H "Host: openwebui.marzhome.com" http://localhost:81
- curl -v -H "Host: n8n.marzhome.com" http://localhost:81
