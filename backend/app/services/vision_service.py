from __future__ import annotations

import io
import json
import logging
from typing import Any

from PIL import Image
from pydantic import BaseModel, ConfigDict, Field, ValidationError

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


class GeminiProviderResponseError(RuntimeError):
    pass


class _GeminiItem(BaseModel):
    model_config = ConfigDict(extra='forbid')

    category: str
    brand: str
    model: str
    condition: str


class _GeminiAnalysis(BaseModel):
    model_config = ConfigDict(extra='forbid')

    summary: str
    problem: str
    confidence: float = Field(ge=0, le=1)


class _GeminiFourRItem(BaseModel):
    model_config = ConfigDict(extra='forbid')

    score: float = Field(ge=0, le=1)
    reason: str


class _GeminiFourR(BaseModel):
    model_config = ConfigDict(extra='forbid')

    reduce: _GeminiFourRItem
    reuse: _GeminiFourRItem
    recycle: _GeminiFourRItem
    riddance: _GeminiFourRItem


class _GeminiVisionResult(BaseModel):
    model_config = ConfigDict(extra='forbid')

    item: _GeminiItem
    analysis: _GeminiAnalysis
    needs_more_information: bool
    questions: list[str]
    four_r: _GeminiFourR


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
        if not self.ready:
            self.load_model()

        try:
            with Image.open(io.BytesIO(image)) as source:
                converted = source.convert('RGB')
                image_buffer = io.BytesIO()
                converted.save(image_buffer, format='PNG')
        except (OSError, ValueError) as exc:
            raise ValueError('The uploaded file is not a supported image.') from exc

        prompt = (
            'Analyze the provided image together with the user message as one request. '
            'Use visual evidence and the user message jointly. Do not infer a specific '
            'internal fault from an external image alone. If there is a swollen or leaking '
            'battery, smoke, fire, burning smell, sparks, exposed high voltage, or severe '
            'liquid damage, prioritize stopping use and professional service; do not give '
            'dangerous repair steps. Use a 0-to-1 confidence value. Set '
            'needs_more_information to false and questions to [] when the evidence is '
            'sufficient; otherwise ask only useful, targeted follow-up questions. Return '
            'only the requested structured result.\n\n'
            f'User message: {user_message.strip() or "No description provided."}'
        )
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
                    response_schema=_GeminiVisionResult,
                    temperature=0.2,
                    max_output_tokens=1200,
                ),
            )
            output_text = response.text
            result = _GeminiVisionResult.model_validate_json(output_text)
        except (ValidationError, json.JSONDecodeError, TypeError, AttributeError) as exc:
            raise GeminiProviderResponseError(
                'Gemini returned a response that did not match the analysis schema.'
            ) from exc

        return {'success': True, **result.model_dump(mode='json')}


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
        if not self.ready:
            self.load_model()

        try:
            with Image.open(io.BytesIO(image)) as source:
                decoded_image = source.convert('RGB')
        except (OSError, ValueError) as exc:
            raise ValueError('The uploaded file is not a supported image.') from exc

        prompt = (
            'Analyze the supplied photo and the user description for a repair and reuse '
            'assessment. Report only details supported by the image or description; use '
            '"unknown" when brand or model cannot be read. Do not claim an internal fault '
            'can be confirmed from an external photo. Return only a JSON object with this '
            'shape: {"item":{"category":"string","brand":"string","model":"string",'
            '"condition":"string"},"analysis":{"summary":"string","problem":"string",'
            '"confidence":0.0},"needs_more_information":true,"questions":["string"],'
            '"four_r":{"reduce":{"score":0.0,"reason":"string"},'
            '"reuse":{"score":0.0,"reason":"string"},'
            '"recycle":{"score":0.0,"reason":"string"},'
            '"riddance":{"score":0.0,"reason":"string"}}}. '
            'All scores and confidence must be between 0 and 1. '
            f'User description: {user_message.strip() or "None provided."}'
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
            payload = json.loads(response[start : end + 1])
        except json.JSONDecodeError as exc:
            raise ValueError('The vision model did not return valid structured analysis.') from exc

        if not isinstance(payload, dict):
            raise ValueError('The vision model returned an invalid analysis object.')
        item = payload.get('item') if isinstance(payload.get('item'), dict) else {}
        analysis = payload.get('analysis') if isinstance(payload.get('analysis'), dict) else {}
        four_r = payload.get('four_r') if isinstance(payload.get('four_r'), dict) else {}
        questions = payload.get('questions')

        return {
            'success': True,
            'item': {
                'category': str(item.get('category') or 'unknown_item'),
                'brand': str(item.get('brand') or 'unknown'),
                'model': str(item.get('model') or 'unknown'),
                'condition': str(item.get('condition') or 'unknown'),
            },
            'analysis': {
                'summary': str(analysis.get('summary') or 'The image was analyzed.'),
                'problem': str(analysis.get('problem') or 'No problem was identified.'),
                'confidence': self._score(analysis.get('confidence')),
            },
            'needs_more_information': bool(payload.get('needs_more_information', False)),
            'questions': [str(question) for question in questions if isinstance(question, str)]
            if isinstance(questions, list)
            else [],
            'four_r': {
                key: {
                    'score': self._score(
                        four_r.get(key, {}).get('score')
                        if isinstance(four_r.get(key), dict)
                        else None
                    ),
                    'reason': str(
                        four_r.get(key, {}).get('reason')
                        if isinstance(four_r.get(key), dict)
                        else 'No assessment available.'
                    ),
                }
                for key in ('reduce', 'reuse', 'recycle', 'riddance')
            },
        }

    @staticmethod
    def _score(value: Any) -> float:
        try:
            return max(0.0, min(1.0, float(value)))
        except (TypeError, ValueError):
            return 0.0


class MockVisionService(BaseVisionService):
    def load_model(self) -> None:
        self.ready = True

    def analyze(self, image: bytes, user_message: str) -> dict[str, Any]:
        if not self.ready:
            self.load_model()
        return {
            'success': True,
            'item': {
                'category': 'unknown_item',
                'brand': 'unknown',
                'model': 'unknown',
                'condition': 'unknown',
            },
            'analysis': {
                'summary': 'Mock provider response; no image model was run.',
                'problem': user_message or 'No problem description was provided.',
                'confidence': 0.0,
            },
            'needs_more_information': True,
            'questions': ['What item is shown, and what issue are you seeing?'],
            'four_r': {
                'reduce': {'score': 0.0, 'reason': 'Mock provider has no assessment.'},
                'reuse': {'score': 0.0, 'reason': 'Mock provider has no assessment.'},
                'recycle': {'score': 0.0, 'reason': 'Mock provider has no assessment.'},
                'riddance': {'score': 0.0, 'reason': 'Mock provider has no assessment.'},
            },
        }


def create_vision_service() -> BaseVisionService:
    provider = settings.vision_provider.strip().lower()
    if provider == 'gemini':
        return GeminiProvider()
    if provider == 'qwen':
        return LocalQwenVisionService()
    if provider == 'mock':
        return MockVisionService()
    raise ValueError(f'Unsupported vision provider: {settings.vision_provider}')
