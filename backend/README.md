# ReValue API

FastAPI backend for the ReValue Flutter app. Product image analysis is isolated
in `app/ai/vision.py`.

## Run locally

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
uvicorn app.main:app --reload
```

The analyze endpoint uses `Qwen/Qwen2.5-VL-3B-Instruct` by default. Set
`QWEN_VL_MODEL_ID` to use another local Hugging Face model, or set
`REVALUE_VISION_PROVIDER=mock` to force the deterministic fallback when model
weights are unavailable. The first Qwen request loads the model into memory.

The API is available at `http://127.0.0.1:8000` and interactive docs are at `/docs`.

## Endpoints

- `GET /health`
- `POST /api/analyze`
- `POST /api/explain`
- `POST /api/recommend`
- `POST /api/repair-estimate`
- `POST /api/marketplace/match`

`POST /api/analyze` returns observational `ProductAnalysis` facts: category,
optional visible brand/model, condition, visible components, possible
materials, possible issue, and risk factors. The vision provider does not
calculate 4R scores, prices, regulations, repair instructions, or definitive
diagnoses. Its output is kept separate from the deterministic ReValue decision
engine and falls back safely if local model loading or inference fails.

`POST /api/explain` retrieves relevant entries from the curated knowledge set
before generating an explanation. The response returns source metadata
separately, and the explanation prompt labels retrieved information separately
from AI reasoning. No crawler is used.

The remaining endpoints are mock data until their respective integrations are
connected.
