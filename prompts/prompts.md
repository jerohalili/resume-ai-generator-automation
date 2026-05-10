# LLM Prompts Reference

This document explains the two LLM calls made per candidate during dataset generation.
The prompts are built dynamically in n8n code nodes and sent to AnythingLLM's `/api/v1/workspace/{workspace}/chat` endpoint.

---

## LLM Call 1 — Basics, Experience & Education

**Node:** `Build LLM Call 1 Prompt` → `LLM Call 1: Basics + Experience + Education`

### System instruction (embedded in message)

```
Output ONLY raw JSON, no markdown, no explanation.
```

### Dynamic prompt template

```
Generate realistic resume data for: {name}, {title},
{yearsExp} yrs exp, specialty: {specialty}, location: {location}.
Replace every FILL value with realistic content. Return:
{schema}
```

### JSON schema sent to the LLM

```json
{
  "basics": {
    "name": "<injected from profile>",
    "label": "<injected job title>",
    "email": "<injected>",
    "phone": "<injected>",
    "location": { "city": "FILL", "region": "FILL", "country": "US" },
    "summary": "FILL: 2-sentence keyword-rich summary",
    "url": { "label": "", "href": "https://linkedin.com/in/FILL" }
  },
  "experience": [
    {
      "id": "exp1",
      "company": "FILL",
      "position": "FILL",
      "date": "FILL",
      "location": "FILL",
      "summary": "FILL: 2 bullet achievements",
      "visible": true
    },
    {
      "id": "exp2",
      "company": "FILL",
      "position": "FILL",
      "date": "FILL",
      "location": "FILL",
      "summary": "FILL: 2 bullet achievements",
      "visible": true
    }
  ],
  "education": [
    {
      "id": "edu1",
      "institution": "FILL",
      "studyType": "FILL",
      "area": "FILL",
      "date": "FILL",
      "score": "FILL",
      "summary": "",
      "visible": true
    }
  ]
}
```

### Response handling
- Strips `\`\`\`json` fences before parsing
- Applies a JSON repair function to close any truncated brackets/braces
- Fixes malformed key syntax (e.g. `"key "value"` → `"key": "value"`)

---

## LLM Call 2 — Skills, Projects & Certifications

**Node:** `Build LLM Call 2 Prompt` → `LLM Call 2: Skills + Projects + Certs`

### Dynamic prompt template

```
Output ONLY raw JSON, no markdown, no explanation.
Generate realistic skills, projects and certifications for:
{name}, {title}, specialty: {specialty}.
Replace every FILL value with realistic content. Return:
{schema}
```

### JSON schema sent to the LLM

```json
{
  "skills": [
    { "id": "sk1", "name": "FILL", "description": "FILL", "level": 4, "keywords": ["FILL", "FILL"], "visible": true },
    { "id": "sk2", "name": "FILL", "description": "FILL", "level": 4, "keywords": ["FILL", "FILL"], "visible": true },
    { "id": "sk3", "name": "FILL", "description": "FILL", "level": 3, "keywords": ["FILL"],          "visible": true }
  ],
  "projects": [
    {
      "id": "pr1",
      "name": "FILL",
      "description": "FILL",
      "date": "FILL",
      "url": { "label": "GitHub", "href": "https://github.com/FILL/FILL" },
      "summary": "FILL",
      "keywords": ["FILL"],
      "visible": true
    },
    {
      "id": "pr2",
      "name": "FILL",
      "description": "FILL",
      "date": "FILL",
      "url": { "label": "GitHub", "href": "https://github.com/FILL/FILL" },
      "summary": "FILL",
      "keywords": ["FILL"],
      "visible": true
    }
  ],
  "certifications": [
    {
      "id": "cert1",
      "name": "FILL",
      "issuer": "FILL",
      "date": "FILL",
      "url": { "label": "", "href": "" },
      "summary": "",
      "visible": true
    }
  ]
}
```

### Response handling
- Same JSON repair + fence-stripping as Call 1
- Merged with Call 1 output in `Assemble Full Resume` node before Reactive Resume patch

---

## ComfyUI Headshot Prompt

**Node:** `ComfyUI: Generate Headshot`

The positive prompt is built from the candidate's profile and uses the ethnic group `promptDesc` field for photorealism diversity:

```
professional LinkedIn headshot of a {promptDesc} {gender} software engineer,
plain light background, business casual attire, natural lighting,
photorealistic, high resolution, 512x512
```

**Negative prompt:**
```
cartoon, anime, illustration, watermark, text, blurry, low quality,
extra limbs, disfigured
```

**Model:** Configurable via `COMFYUI_MODEL` env var (e.g. `z_image_turbo_bf16.safetensors`)

---

## Reactive Resume API Flow

| Step | Endpoint | Description |
|------|----------|-------------|
| 1 | `POST /api/openapi/resumes` | Create blank resume, get `id` |
| 2 | `PATCH /api/openapi/resumes/{id}` | JSON Patch: inject all resume data |
| 3 | `GET /api/openapi/resume-export/{id}` | Export as PDF URL |

The PATCH body uses RFC 6902 JSON Patch operations (`replace`) on paths like:
- `/data/basics`
- `/data/summary`
- `/data/sections/experience`
- `/data/sections/education`
- `/data/sections/skills`
- `/data/sections/projects`
- `/data/sections/certifications`
