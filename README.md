# CS + Engineering Resume Dataset Generator (v4)

An **n8n automation workflow** that generates synthetic, photorealistic, demographically diverse resume datasets for CS and Engineering roles — complete with AI-written content, AI-generated headshots, formatted PDFs, and structured JSON uploads to Google Drive.

---

## What It Does

For each run the workflow generates **2 candidate profiles** end-to-end:

```
Define Profiles → LLM Call 1 → LLM Call 2 → Assemble Resume
    → ComfyUI Headshot → Reactive Resume (create + patch + PDF)
    → Google Drive (JSON + PDF + headshot)
```

| Step | Tool | Output |
|------|------|--------|
| Profile generation | n8n Code node | Name, title, specialty, location, email |
| Resume content (basics, experience, education) | AnythingLLM (local LLM) | JSON via chat API |
| Resume content (skills, projects, certs) | AnythingLLM (local LLM) | JSON via chat API |
| Headshot image | ComfyUI (Stable Diffusion) | PNG via API |
| Resume rendering + PDF export | Reactive Resume v5 API | PDF + hosted resume |
| Storage | Google Drive API | JSON + PDF + headshot per candidate |

---

## Stack

| Service | Role | Default Port |
|---------|------|-------------|
| [n8n](https://n8n.io) | Workflow orchestrator | 5678 |
| [AnythingLLM](https://anythingllm.com) | Local LLM server (Llama 3.1 or any GGUF model) | 3001 |
| [ComfyUI](https://github.com/comfyanonymous/ComfyUI) | Image generation (Stable Diffusion) | 8188 |
| [Reactive Resume](https://rxresu.me) | Resume builder + PDF export | Cloud (rxresu.me) |
| Google Drive | Dataset storage | Cloud |

---

## Prerequisites

- **Docker + Docker Compose v2**
- **NVIDIA GPU** (recommended for ComfyUI; CPU-only works but is very slow)
- A [Reactive Resume](https://rxresu.me) account with an API key
- A Google Cloud project with Drive API enabled (OAuth2 credentials)
- A GGUF-compatible LLM model loaded into AnythingLLM
- A Stable Diffusion checkpoint model placed in ComfyUI's `models/checkpoints/`

---

## Quick Start

```bash
# 1. Clone the repo
git clone https://github.com/YOUR_USERNAME/YOUR_REPO.git
cd YOUR_REPO

# 2. Run setup (copies .env.example → .env, pulls images, starts services)
chmod +x scripts/setup.sh
./scripts/setup.sh

# 3. Edit .env with your credentials
nano .env

# 4. Re-run setup after filling .env
./scripts/setup.sh

# 5. Import the n8n workflow (needs N8N_API_KEY in .env)
chmod +x scripts/import_workflow.sh
./scripts/import_workflow.sh

# 6. Open n8n and configure credentials, then hit "Execute Workflow"
open http://localhost:5678
```

---

## Project Structure

```
├── .env.example                          # Environment variable template
├── .github/
│   └── workflows/
│       └── generate_dataset.yml          # GitHub Actions scheduled trigger
├── docker-compose.yml                    # Full local stack (n8n + AnythingLLM + ComfyUI)
├── prompts/
│   └── prompts.md                        # LLM prompt templates + schema reference
├── scripts/
│   ├── setup.sh                          # First-time setup helper
│   └── import_workflow.sh               # Import workflow via n8n REST API
├── workflow/
│   └── CS_Engineering_Resume_Dataset_Generator_v3.json   # n8n workflow export
└── README.md
```

---

## n8n Credentials to Configure

After importing the workflow, set up these credentials inside n8n (**Settings → Credentials**):

| Credential | Type | Notes |
|------------|------|-------|
| Reactive Resume | HTTP Header Auth | Header: `x-api-key`, Value: your API key |
| AnythingLLM | HTTP Header Auth | Header: `Authorization`, Value: `Bearer YOUR_KEY` |
| Google Drive | OAuth2 | Use your Google Cloud Console client ID + secret |

---

## Workflow Node Overview

```
Execute Workflow (manual trigger)
  └── Define 2 Candidate Profiles       ← randomizes name, title, ethnicity, specialty
        └── Build LLM Call 1 Prompt
              └── LLM Call 1: Basics + Experience + Education
                    └── Parse LLM Call 1
                          └── Build LLM Call 2 Prompt
                                └── LLM Call 2: Skills + Projects + Certs
                                      └── Assemble Full Resume
                                            └── Has Photo?
                                                 ├── [YES] ComfyUI: Generate Headshot
                                                 │         └── Wait 150s for Image
                                                 │               └── HTTP: Get ComfyUI History
                                                 │                     └── Parse ComfyUI History
                                                 │                           └── HTTP: Download ComfyUI Image
                                                 │                                 └── Drive: Upload Headshot
                                                 │                                       └── HTTP: Make Headshot Public
                                                 │                                             └── Build Image URL ──┐
                                                 │                                                                    ↓
                                                 └── [NO]  No Photo (pass-through) ──────────────────────────────────┘
                                                                                           ↓
                                                                              Build RR Payload
                                                                                └── RR: Create Resume
                                                                                      └── Parse Create + Build Patch
                                                                                            └── RR: Patch Data
                                                                                                  └── Wait 15s (printer)
                                                                                                        └── RR: Export PDF
                                                                                                              └── HTTP: Download PDF
                                                                                                                    └── Prep for Drive
                                                                                                                          ├── Drive: Upload PDF
                                                                                                                          └── Drive: Upload JSON
```

---

## Candidate Profile Diversity

The `Define 2 Candidate Profiles` node randomly selects from a weighted pool of ethnic groups, each with culturally matched first names, last names, and a ComfyUI prompt descriptor for headshot generation. Groups include:

- East Asian, South Asian, Southeast Asian
- Black / African American, Hispanic / Latino
- Middle Eastern, White / European, Mixed / Multiracial

Gender is randomly assigned (M/F) per candidate. Specialties rotate across CS tracks (ML/AI, Backend, Frontend, DevOps, Security, Mobile) and Engineering disciplines (Mechanical, Civil, Electrical, Chemical, Aerospace, Biomedical).

---

## GitHub Actions: Scheduled Trigger

The included workflow (`.github/workflows/generate_dataset.yml`) triggers n8n on a schedule via the n8n REST API.

**Required GitHub Secrets** (Settings → Secrets → Actions):

| Secret | Description |
|--------|-------------|
| `N8N_BASE_URL` | Your n8n instance URL (e.g. `https://n8n.yourdomain.com`) |
| `N8N_API_KEY` | n8n Settings → API → Create API Key |
| `N8N_WORKFLOW_ID` | ID of the imported workflow (shown in URL after import) |

> **Note:** For scheduled triggers to reach a local n8n instance, expose it via a tunnel (e.g. [Cloudflare Tunnel](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/)) or deploy n8n to a cloud VM.

---

## Environment Variables

See [`.env.example`](.env.example) for the full list. Key variables:

| Variable | Description |
|----------|-------------|
| `ANYTHINGLLM_API_KEY` | API key from AnythingLLM settings |
| `ANYTHINGLLM_WORKSPACE` | Workspace slug (e.g. `resume-generator`) |
| `COMFYUI_MODEL` | Checkpoint filename in ComfyUI's models folder |
| `REACTIVE_RESUME_API_KEY` | From rxresu.me → Settings → API Keys |
| `GDRIVE_CLIENT_ID` / `GDRIVE_CLIENT_SECRET` | Google Cloud Console OAuth2 |
| `GDRIVE_FOLDER_ID` | Target Drive folder ID (from folder URL) |

---

## License

MIT — use freely, attribution appreciated.
