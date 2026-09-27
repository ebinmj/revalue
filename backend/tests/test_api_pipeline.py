import io
import os
import unittest
import base64
import json
from contextlib import nullcontext
from types import SimpleNamespace
from unittest.mock import patch

from PIL import Image

os.environ['REVALUE_VISION_PROVIDER'] = 'mock'

from fastapi.testclient import TestClient

from app.config import settings
from app.main import app
from app.services.analysis_service import AnalysisService
from app.services.vision_service import GeminiProvider, LocalQwenVisionService


class FakeModelInputs(dict):
    def to(self, device: str) -> 'FakeModelInputs':
        return self


class FakeGeneratedTokens:
    def __getitem__(self, key: tuple[slice, slice]) -> 'FakeGeneratedTokens':
        return self


class ApiPipelineTests(unittest.TestCase):
    def setUp(self) -> None:
        self.client = TestClient(app)

    def test_health_route_reports_backend_ready(self) -> None:
        response = self.client.get('/api/health')
        self.assertEqual(response.status_code, 200)
        payload = response.json()
        self.assertTrue(payload['status'] == 'ok' or payload['status'] == 'healthy')
        self.assertIn('model_loaded', payload)

    def test_analyze_accepts_multipart_upload_and_returns_structured_data(self) -> None:
        image_bytes = b'fake-image-content'
        response = self.client.post(
            '/api/analyze',
            files={'image': ('laptop.jpg', io.BytesIO(image_bytes), 'image/jpeg')},
            data={'message': 'My laptop is not turning on.', 'mode': 'quick_scan', 'conversation_id': 'abc123'},
            timeout=20,
        )

        self.assertEqual(response.status_code, 200, response.text)
        payload = response.json()
        self.assertTrue(payload['success'])
        self.assertIn('item', payload)
        self.assertIn('analysis', payload)
        self.assertIn('four_r', payload)

    def test_qwen_provider_passes_uploaded_image_to_model_and_parses_json(self) -> None:
        image_buffer = io.BytesIO()
        Image.new('RGB', (12, 8), color='red').save(image_buffer, format='PNG')
        image_bytes = image_buffer.getvalue()

        class FakeProcessor:
            received_image: Image.Image | None = None

            def apply_chat_template(self, messages: list[dict], **kwargs: object) -> str:
                self.received_image = messages[0]['content'][0]['image']
                return 'formatted prompt'

            def __call__(self, **kwargs: object) -> FakeModelInputs:
                self.assert_image(kwargs['images'][0])
                return FakeModelInputs(input_ids=SimpleNamespace(shape=(1, 3)))

            def assert_image(self, image: Image.Image) -> None:
                self.received_image = image

            def batch_decode(self, tokens: FakeGeneratedTokens, **kwargs: object) -> list[str]:
                return [
                    '{"item":{"category":"laptop","brand":"unknown",'
                    '"model":"unknown","condition":"worn"},'
                    '"analysis":{"summary":"Laptop visible.","problem":"No power",'
                    '"confidence":0.8},"needs_more_information":true,"questions":[], '
                    '"four_r":{"reduce":{"score":0.9,"reason":"Repair may be viable."}}}'
                ]

        class FakeModel:
            def generate(self, **kwargs: object) -> FakeGeneratedTokens:
                return FakeGeneratedTokens()

        provider = LocalQwenVisionService()
        processor = FakeProcessor()
        provider._processor = processor
        provider._model = FakeModel()
        provider._torch = SimpleNamespace(inference_mode=nullcontext)
        provider._device = 'cpu'
        provider.ready = True

        result = provider.analyze_image(image_bytes, 'It will not power on.', 'quick_scan')

        self.assertEqual(processor.received_image.size, (12, 8))
        self.assertEqual(result['item']['category'], 'laptop')
        self.assertEqual(result['analysis']['problem'], 'No power')
        self.assertEqual(result['four_r']['reduce']['score'], 0.9)

    def test_gemini_provider_sends_image_and_message_in_one_request(self) -> None:
        image_buffer = io.BytesIO()
        Image.new('RGB', (10, 6), color='red').save(image_buffer, format='PNG')
        image_bytes = image_buffer.getvalue()
        generated_result = {
            'item': {
                'category': 'laptop',
                'brand': 'ASUS',
                'model': 'unknown',
                'condition': 'unknown',
            },
            'analysis': {
                'summary': 'The photo shows an ASUS laptop; the user reports no power.',
                'problem': 'Possible power or charging issue.',
                'confidence': 0.72,
            },
            'needs_more_information': True,
            'questions': ['Does the charging light turn on?'],
            'four_r': {
                'reduce': {'score': 0.8, 'reason': 'Repair may extend its useful life.'},
                'reuse': {'score': 0.5, 'reason': 'Reuse may be possible after assessment.'},
                'recycle': {'score': 0.6, 'reason': 'Recycle if repair is not viable.'},
                'riddance': {'score': 0.2, 'reason': 'Use responsible e-waste disposal.'},
            },
        }

        class FakeInteractions:
            request: dict | None = None

            def generate_content(self, **kwargs: object) -> SimpleNamespace:
                self.request = kwargs
                return SimpleNamespace(text=json.dumps(generated_result))

        models = FakeInteractions()
        provider = GeminiProvider(
            client=SimpleNamespace(models=models),
            model_name='test-model',
        )

        result = provider.analyze(image_bytes, 'My laptop does not turn on.')

        request_input = models.request['contents']
        self.assertIn('My laptop does not turn on.', request_input[0])
        image_part = request_input[1]
        self.assertEqual(image_part.inline_data.mime_type, 'image/png')
        image_data = image_part.inline_data.data
        decoded_image = (
            base64.b64decode(image_data)
            if isinstance(image_data, str)
            else bytes(image_data)
        )
        with Image.open(io.BytesIO(decoded_image)) as received_image:
            self.assertEqual(received_image.size, (10, 6))
            self.assertEqual(received_image.getpixel((0, 0)), (255, 0, 0))
        self.assertEqual(models.request['model'], 'test-model')
        self.assertEqual(models.request['config'].response_mime_type, 'application/json')
        self.assertEqual(result['item']['brand'], 'ASUS')
        self.assertIn('four_r', result)

    def test_gemini_requires_backend_api_key_instead_of_falling_back(self) -> None:
        with (
            patch.object(settings, 'vision_provider', 'gemini'),
            patch.object(settings, 'gemini_api_key', None),
            patch('app.api.routes.analysis_service', AnalysisService()),
        ):
            response = self.client.post(
                '/api/analyze',
                files={'image': ('item.png', io.BytesIO(b'image'), 'image/png')},
                data={'message': 'The item does not turn on.'},
            )

        self.assertEqual(response.status_code, 503)
        self.assertIn('GEMINI_API_KEY', response.json()['detail'])


if __name__ == '__main__':
    unittest.main()
