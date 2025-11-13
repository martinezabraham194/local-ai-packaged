# Implementation Plan

[Overview]
Provide a one-line summary: Fix Caddy routing for openwebui and n8n by removing stale hardcoded extra_hosts, restarting Caddy, and verifying Cloudflare Tunnel routing.

This implementation addresses an operational networking mismatch where the Caddy reverse proxy uses stale hardcoded IPs in docker-compose.yml (extra_hosts). Those entries override Docker DNS and point Caddy to wrong container IPs, causing 502 Bad Gateway errors when Cloudflare Tunnel sends traffic to Caddy. The plan removes the stale static host mappings so Caddy resolves service names through Docker DNS, restarts the Caddy container, and validates end-to-end access via the tunnel. The change is limited, low-risk, and scoped to the local compose stack; no other Caddy stacks or their configuration will be modified.

[Types]  
Describe type-system changes in one sentence: No programming type-system changes required; define a small configuration type for operational checks.

Operational configuration types (for documentation and tests)
- DockerServiceName: string — docker-compose service name (e.g., "open-webui", "n8n", "caddy").
- ContainerIP: string — IPv4 address assigned by Docker (e.g., "172.20.0.10/16").
- HostMapping: object
  - name: DockerServiceName
  - ip: ContainerIP
  - origin: string (why mapping exists, e.g., "legacy-static")
  - status: enum {"stale", "valid"}
- ProbeResult: object
  - service: DockerServiceName
  - reachableFromCaddy: boolean
  - httpStatus: integer|null
  - notes: string|null

Validation rules:
- HostMapping entries with status "stale" must be removed.
- After changes, all services referenced by Caddy must be resolvable by container name from Caddy (DNS test: curl/wget to service_name:port inside Caddy).
- Probes must return reachableFromCaddy=true and httpStatus in 2xx或3xx for web apps.

[Files]
Single-sentence: Modify docker-compose.yml (caddy service), update tasks/active_context.md, and add small test script under scripts/.

Detailed breakdown:
- New files to be created:
  - scripts/verify_caddy_service_resolution.sh — shell script that:
    - runs docker exec caddy wget --spider http://<service>:<port>
    - returns nonzero exit code on failure and prints diagnostics
    - path: scripts/verify_caddy_service_resolution.sh
  - tasks/active_context.md (append) — short summary of the incident and fix applied (path: tasks/active_context.md)
- Existing files to be modified:
  - docker-compose.yml
    - File path: ./docker-compose.yml
    - Specific changes:
      - Remove the caddy service extra_hosts section lines that hardcode IPs:
        - Remove: - "open-webui:172.20.0.13"
        - Remove: - "n8n:172.20.0.10"
      - Confirm no other stale extra_hosts entries exist. If found, document them and remove.
      - Leave all other service and port mappings unchanged.
    - Rationale: allow Docker embedded DNS to resolve service names to correct IPs dynamically.
  - Caddyfile
    - File path: ./Caddyfile
    - Specific changes: none required — Caddyfile already refers to services by name (reverse_proxy open-webui:8080 and n8n:5678). Validate that the site blocks for these hosts are the http:// form (they are).
  - .env
    - File path: .env
    - Specific changes: none required.
  - docs/technical.md
    - File path: docs/technical.md
    - Specific changes:
      - Add a short note under "Cloudflare Tunnel / Caddy origin note" documenting the incident and the fix (remove stale extra_hosts / prefer Docker DNS).
  - tasks/active_context.md
    - File path: tasks/active_context.md
    - Specific changes: append incident timeline, root cause, and verification commands used.
- Files to be deleted or moved:
  - None.
- Configuration file updates:
  - No changes to Caddyfile content required. Add a small comment in docker-compose.yml near the caddy service to warn against hardcoding container IPs.

[Functions]
Single-sentence: Add a small verification function/script and no runtime function changes in services.

Detailed breakdown:
- New functions / scripts:
  - verify_caddy_service_resolution.sh
    - Path: scripts/verify_caddy_service_resolution.sh
    - Purpose: Programmatic probe to test Caddy->service connectivity and print diagnostics.
    - Behavior:
      - Usage: ./scripts/verify_caddy_service_resolution.sh open-webui 8080
      - Steps:
        1. docker exec caddy wget -O- --spider http://$1:$2
        2. If wget connects, print "OK: <service> reachable from caddy at <ip>".
        3. If connection refused, run docker exec caddy nslookup $1 || docker exec caddy getent hosts $1 and print results.
        4. Exit with code 0 on success, non-zero on failure.
- Modified functions:
  - None in application code.
- Removed functions:
  - None.

[Classes]
Single-sentence: No code classes will be added or removed.

Detailed breakdown:
- New classes: None.
- Modified classes: None.
- Removed classes: None.

[Dependencies]
Single-sentence: No new package dependencies required.

Details:
- No additional packages or images required.
- Use existing Docker images and system tools (wget, docker CLI).
- Verify host has docker CLI permissions to exec into caddy.

[Testing]
Single-sentence: Use scripted probes plus manual curl tests to validate Caddy reverse proxy resolution and Cloudflare Tunnel end-to-end behavior.

Test file requirements and steps:
- scripts/verify_caddy_service_resolution.sh — unit-like probe to run inside host CI or locally.
- Manual tests:
  1. From host: curl -v -H "Host: openwebui.marzhome.com" http://localhost:81 and expect 200 or 302 (not 502).
  2. From host: curl -v -H "Host: n8n.marzhome.com" http://localhost:81 and expect 200 (or redirect/landing).
  3. From caddy container: docker exec caddy wget -O- --spider http://open-webui:8080 and docker exec caddy wget -O- --spider http://n8n:5678 — both should report remote file exists or HTTP success.
- Regression scope:
  - Confirm other routes that previously worked are still functional (Flowise, Langfuse, Neo4j).
- Post-change validation:
  - Run cloud tunnel endpoint test (using browser or curl via the public domain).
  - Review caddy logs for errors for 5 minutes after restart.

[Implementation Order]
Single-sentence: Make the change to docker-compose.yml, create verification script, restart Caddy, and verify connectivity.

Numbered steps:
1. Create script scripts/verify_caddy_service_resolution.sh and make executable.
2. Edit ./docker-compose.yml — remove the two extra_hosts entries under the caddy service.
   - Exact lines to remove:
     - extra_hosts:
       - "open-webui:172.20.0.13"
       - "n8n:172.20.0.10"
   - If extra_hosts contains only those two entries, remove the entire extra_hosts block.
   - Add a one-line comment near caddy service: "# DO NOT hardcode container IPs here; Docker DNS should be used."
3. Append short note to docs/technical.md describing the change and why hardcoding is dangerous.
4. Append an entry in tasks/active_context.md recording the investigation summary and the exact commands used to debug.
5. Commit the changes (small atomic commit message: "fix(caddy): remove stale extra_hosts to allow Docker DNS resolution for open-webui and n8n").
6. Restart only the caddy container: docker restart caddy
7. Run verification script and manual curl tests:
   - ./scripts/verify_caddy_service_resolution.sh open-webui 8080
   - ./scripts/verify_caddy_service_resolution.sh n8n 5678
   - curl -v -H "Host: openwebui.marzhome.com" http://localhost:81
   - curl -v -H "Host: n8n.marzhome.com" http://localhost:81
8. Monitor caddy logs for errors: docker logs caddy --follow
9. If any service still fails, revert the change and investigate specific service health (container listening on intended port).
10. When validated, update docs/technical.md and tasks/active_context.md with final notes and mark task done.

Notes / Risk mitigation:
- This change is non-destructive and limited to docker-compose.yml. Rolling back is trivial by restoring the removed lines or checking out the previous commit.
- Do not modify any other Caddy stacks or Caddy configuration outside this repository.
- If a service requires a static IP for other operational reasons, document that and instead configure an explicit Docker network with static assignments rather than extra_hosts.

Operation commands (examples):
- Edit file and restart Caddy:
  - sed -i.bak '/extra_hosts:/,/- "n8n:172.20.0.10"/d' docker-compose.yml
  - docker restart caddy
- Verify from host:
  - curl -v -H "Host: openwebui.marzhome.com" http://localhost:81
  - curl -v -H "Host: n8n.marzhome.com" http://localhost:81
- Verify from caddy:
  - docker exec caddy wget -O- --spider http://open-webui:8080
  - docker exec caddy wget -O- --spider http://n8n:5678
