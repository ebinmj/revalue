# ReValue API

FastAPI backend for the ReValue Flutter app. Product image analysis is isolated
in `app/ai/vision.py`.

## Run locally

```powershell
Set-Location C:\Users\ebinm\revalue\backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
Copy-Item .env.example .env
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Set `SUPABASE_URL` and `SUPABASE_ANON_KEY` in `backend/.env` before starting
the backend. The same URL and public anon/publishable key are Flutter build
defines. Do not set or expose a service-role key; FastAPI forwards each user's
Supabase access token to PostgREST so row-level security is applied per user.

Before the first run, inspect the existing `profiles`, `listings`, and
`components` tables in the Supabase SQL Editor, then apply
`backend/supabase/schema.sql`. The script creates missing tables, enables RLS,
replaces policies on those three tables, and installs the signup profile trigger.
Existing row data is not deleted.

The Flutter client requires these build defines:

```powershell
Set-Location C:\Users\ebinm\revalue
flutter run `
	--dart-define=SUPABASE_URL=https://<project-ref>.supabase.co `
	--dart-define=SUPABASE_ANON_KEY=<public-anon-or-publishable-key> `
	--dart-define=API_BASE_URL=http://10.0.2.2:8000
```

`10.0.2.2` is for the Android emulator. For a physical phone, use the
development PC's LAN IPv4 address for `API_BASE_URL`, and allow port 8000
through the PC firewall.

`POST /api/analyze` uses the provider abstraction in
`app/services/vision_service.py`; `GeminiProvider` is the default and sends the
uploaded image and user message in one Gemini request. Set `GEMINI_API_KEY` in
the backend environment only. `GEMINI_MODEL` defaults to `gemini-3.8-flash`.
Set `REVALUE_VISION_PROVIDER=qwen` to use the optional local Qwen provider.
There is no automatic mock fallback when Gemini is unavailable.

The API is available at `http://127.0.0.1:8000` and interactive docs are at `/docs`.

## Endpoints

- `GET /health`
- `POST /api/analyze`
- `POST /api/auth/profile`
- `GET /api/marketplace/listings`
- `POST /api/marketplace/listings`
- `GET /api/marketplace/listings/{listing_id}`
- `PUT /api/marketplace/listings/{listing_id}`
- `DELETE /api/marketplace/listings/{listing_id}`
- `POST /api/marketplace/listings/{listing_id}/components`
- `GET /api/marketplace/listings/{listing_id}/components`
- `POST /api/explain`
- `POST /api/recommend`
- `POST /api/repair-estimate`

`POST /api/analyze` returns observational `ProductAnalysis` facts: category,
The analyze response keeps its existing structured `item`, `analysis`,
`questions`, and `four_r` fields. Gemini is instructed to report uncertainty
and avoid dangerous repair procedures; malformed structured output is rejected
instead of replaced with fabricated results.

`POST /api/explain` retrieves relevant entries from the curated knowledge set
before generating an explanation. The response returns source metadata
separately, and the explanation prompt labels retrieved information separately
from AI reasoning. No crawler is used.

For the two-user test, register `userA@example.com`, publish a listing, log out,
then register `userB@example.com` and search for RAM. Both accounts must use the
same Supabase project and the same FastAPI backend URL.
