#!/usr/bin/env bash
# =============================================================
# import_workflow.sh — Import the n8n workflow via the REST API
# =============================================================
# Usage:
#   chmod +x scripts/import_workflow.sh
#   ./scripts/import_workflow.sh
#
# Requires n8n to be running (./scripts/setup.sh first).
# Set N8N_API_KEY in .env, or pass as env var:
#   N8N_API_KEY=your_key ./scripts/import_workflow.sh
# =============================================================

set -euo pipefail

# Load .env if present
[ -f ".env" ] && export $(grep -v '^#' .env | xargs)

N8N_BASE="${N8N_BASE:-http://localhost:5678}"
API_KEY="${N8N_API_KEY:-}"
WORKFLOW_FILE="workflow/CS_Engineering_Resume_Dataset_Generator_v3.json"

if [ -z "$API_KEY" ]; then
  echo "ERROR: N8N_API_KEY is not set."
  echo "  Generate one in n8n → Settings → API → Create API Key"
  echo "  Then add it to your .env: N8N_API_KEY=your_key_here"
  exit 1
fi

if [ ! -f "$WORKFLOW_FILE" ]; then
  echo "ERROR: Workflow file not found: $WORKFLOW_FILE"
  exit 1
fi

echo "Importing workflow from $WORKFLOW_FILE ..."

RESPONSE=$(curl -sf -X POST \
  "${N8N_BASE}/api/v1/workflows" \
  -H "X-N8N-API-KEY: ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d @"${WORKFLOW_FILE}")

WORKFLOW_ID=$(echo "$RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin).get('id','unknown'))")

echo "✓ Workflow imported! ID: $WORKFLOW_ID"
echo "  Open: ${N8N_BASE}/workflow/${WORKFLOW_ID}"
