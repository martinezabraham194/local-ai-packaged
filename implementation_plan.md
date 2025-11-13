# Implementation Plan

[Overview]
Enable external access to n8n via Cloudflare Tunnel by routing n8n.marzhome.com to the local Caddy origin on 127.0.0.1:81 and updating configuration, docs, and verification tooling to match the existing Open WebUI tunnel pattern.

This change follows the established Open WebUI pattern where TLS is terminated by Cloudflare Tunnel and Caddy serves the origin over plain HTTP to avoid automatic HTTPS redirects. The scope includes Caddy configuration, environment configuration, a lightweight verification script, and documentation and memory updates to record the change and testing results. This is needed so n8n can be securely exposed at n8n.marzhome.com using the existing Cloudflare Tunnel setup without Caddy forcing an HTTPS redirect that would break the tunnel.

[Types]  
Add an explicit env-var type/validation for the N8N_HOSTNAME environment variable.

- N8N_HOSTNAME: string (DNS host or domain). Validation rules:
  - Non-empty when exposing n8n externally.
  - Must be a valid hostname per RFC 1035 (letters, digits, hyphen, dot-separated labels).
  - Not contain protocol or path (no "http(s)://" or trailing "/").
  - Example valid value: n8n.marzhome.com
- WEBUI_HOSTNAME, FLOWISE_HOSTNAME, etc. unchanged.

[Files]  
Describe file modifications required to implement and document the tunnel.

- New files to be created
  - scripts/verify_n8n_tunnel.sh — Simple verification script that sends a Host header to 127.0.0.1:81 and asserts HTTP 200 or redirects expected for n8n; used by CI or manual checks.
  - docs/runbooks/n8n-cloudflare-tunnel.md — Runbook containing step-by-step deploy and verification instructions for the tunnel.
- Existing files to be modified
  - Caddyfile
    - Change the N8N site block from an auto-HTTPS block to an explicit http:// site block:
      - Replace:
        {$N8N_HOSTNAME} {
          reverse_proxy n8n:5678
        }
      - With:
        http://{$N8N_HOSTNAME} {
          reverse_proxy n8n:5678
        }
    - Rationale: prevents Caddy issuing a 308 auto-HTTPS redirect so Cloudflare Tunnel can terminate TLS externally.
  - .env
    - Uncomment or add the N8N_HOSTNAME assignment:
      - N8N_HOSTNAME=n8n.marzhome.com
    - Ensure other variables (N8N_ENCRYPTION_KEY, N8N_USER_MANAGEMENT_JWT_SECRET) are set (already present).
  - docs/technical.md
    - Add a short section documenting the N8N Cloudflare Tunnel pattern and include the verification curl command and runbook link.
  - .cursor/rules/lessons-learned.mdc
    - Add an entry mirroring the Open WebUI lessons learned, including verification steps and the final resolution (Caddy http:// block).
  - tasks/active_context.md
    - Append an entry describing the change, verification result, and links to the runbook and implementation plan.
- Files to be deleted or moved
  - None.
- Configuration file updates
  - docker-compose.yml: No change required for service definitions. Caddy environment variables already accept N8N_HOSTNAME via .env; ensure .env is updated.
  - If Cloudflare Tunnel runs on host and forwards to 127.0.0.1:81, ensure any host-level firewall or NAT allows loopback forwarding as required.

[Functions]  
Introduce a small verification helper shell script; no service code functions will be modified.

- New functions (script-level)
  - verify_n8n_tunnel (scripts/verify_n8n_tunnel.sh)
    - Signature: executable shell script; usage: scripts/verify_n8n_tunnel.sh
    - Purpose: Send HTTP request to 127.0.0.1:81 with Host: n8n.marzhome.com and check for expected HTTP status and body markers.
- Modified functions
  - None in application code.
- Removed functions
  - None.

[Classes]  
No application classes will be added, modified, or removed.

- New classes: None.
- Modified classes: None.
- Removed classes: None.

[Dependencies]  
No new package dependencies are required; tooling uses existing system tools (curl, sh).

- New packages: none
- System requirements: curl or wget available on host/container used to run verification script (most environments already have curl).
- Integration requirements: Cloudflare Tunnel configured to forward n8n.marzhome.com to 127.0.0.1:81 (external to this repository) and Caddy running inside the compose stack listening on 81 → reverse_proxy n8n:5678.

[Testing]  
Add a manual and script-driven verification step; no automated unit tests required.

- Test files:
  - scripts/verify_n8n_tunnel.sh (executable) — returns 0 on success, non-zero on failure.
- Manual verification steps:
  1. From host: curl -v --header "Host: n8n.marzhome.com" http://127.0.0.1:81/
     - Expected: HTTP/1.1 200 or an HTML login page from n8n or appropriate redirect to / (verify content contains "n8n" or expected login form).
  2. Test Cloudflare Tunnel externally (once configured) by visiting https://n8n.marzhome.com and verifying TLS and functionality.
- CI integration: Add an optional CI step to run scripts/verify_n8n_tunnel.sh after deployment in environments where 127.0.0.1:81 is reachable.

[Implementation Order]  
Apply changes in a small, testable sequence to minimize service disruption.

1. Update .env to set N8N_HOSTNAME=n8n.marzhome.com (local change only).
2. Update Caddyfile: change N8N site block to http://{$N8N_HOSTNAME} { reverse_proxy n8n:5678 }.
3. Create scripts/verify_n8n_tunnel.sh and docs/runbooks/n8n-cloudflare-tunnel.md and update docs/technical.md and .cursor/rules/lessons-learned.mdc and tasks/active_context.md with the planned changes and verification steps.
4. Restart Caddy to pick up the new Caddyfile (.e.g. docker compose restart caddy or docker restart caddy).
5. Run scripts/verify_n8n_tunnel.sh locally to validate expected response from Caddy → n8n.
6. Once verified locally, configure Cloudflare Tunnel (external step) to forward n8n.marzhome.com → 127.0.0.1:81 and perform external validation (browse https://n8n.marzhome.com).
7. Record verification results in .cursor/rules/lessons-learned.mdc and update tasks/active_context.md with timestamps and outcomes.

Notes and edge-cases:
- If the Caddy service is serving other domains with valid TLS via Let's Encrypt, using an explicit http:// site block scoped to the n8n hostname avoids changing HTTPS behavior for other sites.
- If n8n produces absolute redirects with https:// hostnames, test webhook URL behavior to ensure webhooks still work; the N8N_WEBHOOK_URL or WEBHOOK_URL env var is already set to use N8N_HOSTNAME in docker-compose.yml.
- If port 81 is already in use, the Cloudflare Tunnel mapping must be updated to target whichever host port Caddy is listening on for origin HTTP. The pattern used here expects Caddy to accept traffic on 127.0.0.1:81 and proxy it into the compose network to n8n:5678.
