from __future__ import annotations

import io
import json
import logging
from typing import Any

from PIL import Image
from pydantic import ValidationError

from app.api.schemas import QuickScanAnalysisResponse
from app.config import settings

logger = logging.getLogger(__name__)


class BaseVisionService:
    def __init__(self) -> None:
        self.ready = False
        self.model_loaded = False

    def load_model(self) -> None:
        self.ready = True
        self.model_loaded = True

    def analyze(self, image: bytes, user_message: str) -> dict[str, Any]:
        raise NotImplementedError

    def analyze_image(self, image_bytes: bytes, message: str, mode: str) -> dict[str, Any]:
        return self.analyze(image_bytes, message)


class VisionProviderConfigurationError(RuntimeError):
    pass


class VisionProviderResponseError(RuntimeError):
    pass


class GeminiProvider(BaseVisionService):
    def __init__(
        self,
        *,
        api_key: str | None = None,
        model_name: str | None = None,
        client: Any = None,
    ) -> None:
        super().__init__()
        self._api_key = api_key
        self._model_name = model_name or settings.gemini_model
        self._client = client

    def load_model(self) -> None:
        if self.ready:
            return
        api_key = self._api_key or settings.gemini_api_key
        if self._client is None:
            if not api_key:
                raise VisionProviderConfigurationError(
                    'Set GEMINI_API_KEY in the backend environment to enable image analysis.'
                )
            from google import genai

            self._client = genai.Client(api_key=api_key)
        self.ready = True
        logger.info('Gemini vision provider ready: %s.', self._model_name)

    def analyze(self, image: bytes, user_message: str) -> dict[str, Any]:
        try:
            with Image.open(io.BytesIO(image)) as source:
                converted = source.convert('RGB')
                image_buffer = io.BytesIO()
                converted.save(image_buffer, format='PNG')
        except (OSError, ValueError) as exc:
            raise ValueError('The uploaded file is not a supported image.') from exc
        if not self.ready:
            self.load_model()

        prompt = f'''You are the ReValue AI analysis assistant.

    ReValue helps users decide what to do with unwanted, broken, used, or damaged products.
    Analyze the uploaded image together with the user's description as one request.
    Identify a product only when supported by the image and text. Do not invent a brand,
    model, condition, damage, components, or materials. If information is insufficient,
    use lower confidence and ask only useful follow-up questions; use an empty question
    list when more information is not needed.

    Provide recommendations for these recovery paths:
    REDUCE: repair or extend the product's useful life.
    REUSE: give the product or usable components another life.
    RECYCLE: recover useful materials through appropriate recycling.
    RIDDANCE: dispose responsibly when repair, reuse, or recycling are impractical.

    Be cautious about safety. For swollen or leaking batteries, smoke, sparks, burning
    smell, fire, exposed dangerous electrical components, or severe liquid damage,
    prioritize stopping use and professional service. Never give dangerous step-by-step
    repair instructions. Confidence must be exactly high, medium, or low.

    User message: {user_message.strip() or "No description provided."}'''
        try:
            from google.genai import types

            response = self._client.models.generate_content(
                model=self._model_name,
                contents=[
                    prompt,
                    types.Part.from_bytes(
                        data=image_buffer.getvalue(),
                        mime_type='image/png',
                    ),
                ],
                config=types.GenerateContentConfig(
                    response_mime_type='application/json',
                    response_schema=QuickScanAnalysisResponse,
                    temperature=0.2,
                    max_output_tokens=1200,
                ),
            )
            output_text = response.text
            result = QuickScanAnalysisResponse.model_validate_json(output_text)
        except (ValidationError, json.JSONDecodeError, TypeError, AttributeError) as exc:
            raise VisionProviderResponseError(
                'Gemini returned a response that did not match the analysis schema.'
            ) from exc

        return result.model_dump(mode='json')


class LocalQwenVisionService(BaseVisionService):
    def __init__(self, model_name: str | None = None) -> None:
        super().__init__()
        self._model_name = model_name or settings.model_path or settings.model_name
        self._processor: Any = None
        self._model: Any = None
        self._torch: Any = None
        self._device = 'cpu'

    def load_model(self) -> None:
        if self.ready:
            return

        logger.info('Loading vision model...')
        import torch
        from transformers import AutoProcessor, Qwen2_5_VLForConditionalGeneration

        self._torch = torch
        self._device = 'cuda' if torch.cuda.is_available() else 'cpu'
        model_dtype = torch.float16 if self._device == 'cuda' else torch.float32
        self._processor = AutoProcessor.from_pretrained(self._model_name)
        self._model = Qwen2_5_VLForConditionalGeneration.from_pretrained(
            self._model_name,
            torch_dtype=model_dtype,
        ).to(self._device)
        self._model.eval()
        self.model_loaded = True
        self.ready = True
        logger.info('Vision model ready: %s on %s.', self._model_name, self._device)

    def analyze(self, image: bytes, user_message: str) -> dict[str, Any]:
        try:
            with Image.open(io.BytesIO(image)) as source:
                decoded_image = source.convert('RGB')
        except (OSError, ValueError) as exc:
            raise ValueError('The uploaded file is not a supported image.') from exc
        if not self.ready:
            self.load_model()

        prompt = (
            'Analyze the image together with the user message as one request. Do not '
            'invent product details or claim an internal fault from an external image. '
            'Return JSON matching QuickScanAnalysisResponse: identified_item, summary, '
            'possible_problem, confidence (high|medium|low), reduce/reuse/recycle/riddance '
            '(each recommendation and reason), and follow_up_questions. Be cautious about '
            'battery, smoke, fire, sparks, burning smell, exposed electrical hazards, or '
            'severe liquid damage; prioritize professional service and do not give dangerous '
            'repair steps. Ask follow-up questions only when useful. '
            f'User message: {user_message.strip() or "None provided."}'
        )
        messages = [{
            'role': 'user',
            'content': [
                {'type': 'image', 'image': decoded_image},
                {'type': 'text', 'text': prompt},
            ],
        }]
        formatted_prompt = self._processor.apply_chat_template(
            messages,
            tokenize=False,
            add_generation_prompt=True,
        )
        inputs = self._processor(
            text=[formatted_prompt],
            images=[decoded_image],
            return_tensors='pt',
        ).to(self._device)
        with self._torch.inference_mode():
            generated = self._model.generate(**inputs, max_new_tokens=512)
        prompt_length = inputs['input_ids'].shape[1]
        answer_tokens = generated[:, prompt_length:]
        answer = self._processor.batch_decode(
            answer_tokens,
            skip_special_tokens=True,
            clean_up_tokenization_spaces=False,
        )[0]
        return self._parse_response(answer)

    def _parse_response(self, response: str) -> dict[str, Any]:
        start = response.find('{')
        end = response.rfind('}')
        if start < 0 or end < start:
            raise ValueError('The vision model did not return valid structured analysis.')
        try:
            payload = QuickScanAnalysisResponse.model_validate_json(
                response[start : end + 1]
            )
        except (json.JSONDecodeError, ValidationError) as exc:
            raise VisionProviderResponseError(
                'Vision provider returned an invalid analysis response.'
            ) from exc
        return payload.model_dump(mode='json')


def create_vision_service() -> BaseVisionService:
    provider = settings.vision_provider.strip().lower()
    if provider == 'gemini':
        return GeminiProvider()
    if provider == 'qwen':
        return LocalQwenVisionService()
    raise ValueError(f'Unsupported vision provider: {settings.vision_provider}')
