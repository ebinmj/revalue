from __future__ import annotations

import os
from dataclasses import dataclass

from dotenv import load_dotenv

load_dotenv()


@dataclass(slots=True)
class Settings:
    api_host: str = os.getenv('API_HOST', '0.0.0.0')
    api_port: int = int(os.getenv('API_PORT', '8000'))
    model_name: str = os.getenv('MODEL_NAME', 'Qwen/Qwen2.5-VL-3B-Instruct')
    model_path: str | None = os.getenv('MODEL_PATH')
    vision_provider: str = os.getenv('REVALUE_VISION_PROVIDER', 'gemini')
    gemini_api_key: str | None = os.getenv('GEMINI_API_KEY')
    gemini_model: str = os.getenv('GEMINI_MODEL', 'gemini-3.8-flash')
    supabase_url: str | None = os.getenv('SUPABASE_URL')
    supabase_anon_key: str | None = os.getenv('SUPABASE_ANON_KEY')


settings = Settings()
