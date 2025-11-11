# Technical Specifications

Project: local-ai-packaged — Cline AI Agent Integration

Overview:
- Runtime: Docker Compose with service profiles (cpu, gpu-nvidia, gpu-amd, none).
- Languages: Python (setup scripts), Bash for ops, various service images.
- CI/CD: Git-based workflows; keep changes small and tested.

Development environment:
- Python >= 3.10
- Docker & docker-compose
- Node.js (optional for frontend tools)
- Recommended IDE: VSCode / VSCode Insiders

Key files:
- docker-compose.yml — service orchestration and profiles
- start_services.py — helper to start stacks with profiles
- .env / .env.example — runtime configuration and secrets (do not commit secrets)

Testing:
- Unit tests: place in test/ with pytest
- Integration: lightweight integration tests using docker-compose --profile
- TDD: follow implement workflow; add tests before non-trivial features

Dependencies & configuration:
- Keep dependency pins minimal in repo; use images defined in docker-compose.yml
- Document configuration flags in config/ and reference in docs/technical.md

Security:
- Never commit secrets; store them in .env (ignored by .gitignore)
- Use Caddy for TLS in production; restrict exposed ports in public profile

Operational notes:
- Update docs/technical.md with any changes to service topology or environment variables.
- Record compatibility notes (OS, GPU) and known caveats.
- Cloudflare Tunnel / Caddy origin note: When terminating TLS via Cloudflare Tunnel (cloudflared) and forwarding plain HTTP to the origin, configure Caddy to avoid automatic HTTPS redirects by using an explicit http:// site block for the origin host. Example:
  http://{$WEBUI_HOSTNAME} {
      reverse_proxy open-webui:8080
  }
  Cloudflared may run on the host or inside a container; running it as a container is optional. Scope http:// site blocks only to hosts behind an external TLS terminator to avoid disabling HTTPS for other sites.
- Operational security: prefer restricting exposed ports (use private profile) and continue to use Caddy-managed TLS in public/production profiles.
