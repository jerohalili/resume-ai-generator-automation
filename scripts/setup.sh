#!/usr/bin/env bash
# =============================================================
# setup.sh — First-time setup for the Resume Dataset Generator
# =============================================================
# Usage:
#   chmod +x scripts/setup.sh
#   ./scripts/setup.sh
# =============================================================

set -euo pipefail

BOLD="\033[1m"
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"

info()    { echo -e "${GREEN}[INFO]${RESET}  $*"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET}  $*"; }
error()   { echo -e "${RED}[ERROR]${RESET} $*"; exit 1; }
section() { echo -e "\n${BOLD}=== $* ===${RESET}"; }

# ── 1. Check dependencies ───────────────────────────────────
section "Checking dependencies"

command -v docker   >/dev/null 2>&1 || error "Docker not found. Install from https://docs.docker.com/get-docker/"
command -v docker   >/dev/null 2>&1 && docker compose version >/dev/null 2>&1 || \
  error "Docker Compose v2 not found. Update Docker Desktop or install the plugin."

info "Docker: $(docker --version)"
info "Docker Compose: $(docker compose version)"

# ── 2. Copy .env if missing ─────────────────────────────────
section "Environment file"

if [ ! -f ".env" ]; then
  cp .env.example .env
  warn ".env created from .env.example — fill in your credentials before continuing."
  warn "Open .env and set all YOUR_* / changeme values, then re-run this script."
  exit 0
else
  info ".env already exists, skipping copy."
fi

# Quick sanity check — warn if defaults are still present
if grep -q "changeme\|your_" .env 2>/dev/null; then
  warn "Some .env values still look like placeholders. Double-check before running."
fi

# ── 3. Pull images ──────────────────────────────────────────
section "Pulling Docker images (this may take a while)"
docker compose pull

# ── 4. Start services ───────────────────────────────────────
section "Starting services"
docker compose up -d

# ── 5. Wait for n8n ─────────────────────────────────────────
section "Waiting for n8n to be ready"
MAX=30; COUNT=0
until curl -sf http://localhost:5678/healthz >/dev/null 2>&1; do
  sleep 2; COUNT=$((COUNT+1))
  [ $COUNT -ge $MAX ] && error "n8n did not start in time. Check: docker compose logs n8n"
  echo -n "."
done
echo ""
info "n8n is up!"

# ── 6. Print summary ────────────────────────────────────────
section "Setup complete"
echo -e "
  ${BOLD}Services${RESET}
  ┌─────────────────────────────────────────────┐
  │  n8n          →  http://localhost:5678       │
  │  AnythingLLM  →  http://localhost:3001       │
  │  ComfyUI      →  http://localhost:8188       │
  └─────────────────────────────────────────────┘

  ${BOLD}Next steps${RESET}
  1. Open n8n and import the workflow:
       workflow/CS_Engineering_Resume_Dataset_Generator_v3.json
  2. Set credentials in n8n (HTTP Header Auth for Reactive Resume,
     Google Drive OAuth2, AnythingLLM API key).
  3. In AnythingLLM, create a workspace named 'resume-generator'
     and load your LLM model.
  4. In ComfyUI, place your image model in models/checkpoints/.
  5. Click 'Execute Workflow' in n8n and watch it run!
"
