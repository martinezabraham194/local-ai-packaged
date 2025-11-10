# Architecture Overview

Project: local-ai-packaged — Cline AI Agent Integration

Summary:
- Modular, containerized stack (Docker Compose) provides services: n8n, Open WebUI, Supabase, Ollama, Flowise, Qdrant/Neo4j, Caddy.
- CLINE rules and memory live in repository to provide AI-assisted workflows and persistent project context.

Components:
- Orchestration: docker-compose.yml for local development and profiles (cpu, gpu-nvidia, gpu-amd, none).
- Services:
  - n8n: workflow engine and agent runtime.
  - Open WebUI: chat interface to interact with local LLMs and agent functions.
  - Supabase/Postgres: database and vector store (optional Qdrant).
  - Ollama: local LLM host.
  - Flowise: low-code agent builder.
  - Caddy: TLS and reverse proxy.
- Documentation: docs/ holds PRD, architecture, technical specs, literature.
- Tasks: tasks/ holds active_context, tasks_plan, and RFCs used as AI memory and task handoff.

Deployment model:
- Development: single-machine, docker compose with profiles for GPU/CPU.
- Production: cloud VM with restricted ports, DNS entries and Caddy for TLS.

Design considerations:
- Separation of concerns: services are isolated into containers; config stored in config/ and .env.
- Observability: capture container logs and store troubleshooting notes in tasks/ and .clinerules/memory.
- Incremental updates: follow the CLINE implement workflow—small commits, tests, and documentation updates.

Operational notes:
- Ensure .env contains secrets; do not commit secrets.
- Keep documentation up-to-date in docs/ and tasks/ active_context.
