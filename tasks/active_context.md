# Active Development Context

Project: local-ai-packaged — Cline AI Agent Integration

Current focus:
- Add CLINE rules directory and memory templates to the repository.
- Scaffold docs/ and tasks/ memory files so the AI can initialize project context.

Recent decisions:
- Use standard rules template adapted from Bhartendu-Kumar/rules_template.
- Create minimal placeholder files and .gitkeep markers to preserve directories in git.

Next steps:
- Populate tasks/tasks_plan.md with backlog and milestones.
- Create tasks/rfc/ for RFC documents.
- Create supporting directories (src, test, utils, config, data) and add .gitkeep files.
- Run the initialization prompt in Cline to let the AI populate memory files.

Timestamp: 2025-11-10 18:07:40 (local)

Recent updates:
- 2025-11-11 00:58:51 (local) - Disabled automatic HTTPS for Open WebUI in Caddyfile; changed site block to HTTP-only:
  http://{$WEBUI_HOSTNAME} {
      reverse_proxy open-webui:8080
  }
  Restarted the caddy container and verified HTTP/1.1 200 from http://127.0.0.1:81/ with Host: openwebui.marzhome.com. Caddy now forwards plain HTTP (suitable for Cloudflare Tunnel which terminates TLS).

Next steps:
- Append concise entry to .cursor/rules/lessons-learned.mdc documenting the incident and fix.
- Update docs/technical.md operational notes to reference Cloudflare Tunnel usage and Caddy HTTP-only site configuration.
- Commit changes and push to remote repository.
