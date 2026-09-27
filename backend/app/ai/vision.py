"""Qwen vision extraction adapter with a deterministic fallback provider."""

from __future__ import annotations

import base64
import json
import os
from pathlib import Path
from typing import Any, Protocol

from app.api.schemas import AnalyzeRequest, AnalyzeResponse, ProductAnalysis


MODEL_ID = os.getenv("QWEN_VL_MODEL_ID", "Qwen/Qwen2.5-VL-3B-Instruct")


class VisionProvider(Protocol):
    def analyze(self, request: AnalyzeRequest) -> ProductAnalysis:
        ...


class FallbackVisionProvider:
    """Keep the API usable when model weights or runtime dependencies are absent."""

    def analyze(self, request: AnalyzeRequest) -> ProductAnalysis:
        return ProductAnalysis(
            detected_category="Unknown product",
            condition="Condition not confirmed from available input",
            possible_issue=(
                "Possible issue based on the user description: "
                f"{request.description.strip()}"
            ),
            visible_components=[],
            possible_materials=[],
            risk_factors=["Image analysis is unavailable; inspect the item before handling it."],
        )


class QwenVisionProvider:
    def __init__(self, model_id: str = MODEL_ID) -> None:
        self.model_id = model_id
        self._model: Any | None = None
        self._processor: Any | None = None

    def analyze(self, request: AnalyzeRequest) -> ProductAnalysis:
        model, processor = self._load()
        image = _load_image(request.image_reference) if request.image_reference else None
        prompt = _extraction_prompt(request.description)
        messages = [{"role": "user", "content": []}]
        if image is not None:
            messages[0]["content"].append({"type": "image", "image": image})
        messages[0]["content"].append({"type": "text", "text": prompt})

        text = processor.apply_chat_template(
            messages, tokenize=False, add_generation_prompt=True
        )
        inputs = processor(
            text=[text], images=[image] if image is not None else None,
            padding=True, return_tensors="pt",
        ).to(model.device)
        generated = model.generate(**inputs, max_new_tokens=400)
        generated_text = processor.batch_decode(
            generated[:, inputs.input_ids.shape[1]:],
            skip_special_tokens=True,
            clean_up_tokenization_spaces=False,
        )[0]
        return ProductAnalysis.model_validate(_parse_json(generated_text))

    def _load(self) -> tuple[Any, Any]:
        if self._model is None or self._processor is None:
            from transformers import AutoProcessor, Qwen2_5_VLForConditionalGeneration

            self._processor = AutoProcessor.from_pretrained(self.model_id)
            self._model = Qwen2_5_VLForConditionalGeneration.from_pretrained(
                self.model_id, torch_dtype="auto", device_map="auto"
            )
        return self._model, self._processor


def analyze_item(request: AnalyzeRequest) -> AnalyzeResponse:
    """Extract facts with Qwen when enabled; never delegate recommendations to it."""
    provider: VisionProvider = _provider()
    try:
        analysis = provider.analyze(request)
    except Exception:
        analysis = FallbackVisionProvider().analyze(request)
    return AnalyzeResponse.from_product_analysis(analysis)


def _provider() -> VisionProvider:
    if os.getenv("REVALUE_VISION_PROVIDER", "qwen").lower() == "mock":
        return FallbackVisionProvider()
    return QwenVisionProvider()


def _extraction_prompt(description: str) -> str:
    return f"""Extract only observable facts from the product image and user description.
Return one JSON object with exactly these keys:
detected_category, brand_model, condition, visible_components, possible_materials, possible_issue, risk_factors.
Use null for brand_model when it is not visible. Use arrays of strings for list fields.
Use cautious wording such as 'possible issue'. Do not calculate scores or recommendations.
Do not invent prices, regulations, repair instructions, or definitive diagnoses.
User description: {description}"""


def _load_image(reference: str) -> Any:
    from PIL import Image

    if reference.startswith("data:image/"):
        _, encoded = reference.split(",", 1)
        return Image.open(__import__("io").BytesIO(base64.b64decode(encoded))).convert("RGB")
    return Image.open(Path(reference)).convert("RGB")


def _parse_json(text: str) -> dict[str, Any]:
    cleaned = text.strip()
    if cleaned.startswith("```"):
        cleaned = cleaned.split("\n", 1)[1].rsplit("```", 1)[0].strip()
    parsed = json.loads(cleaned)
    if not isinstance(parsed, dict):
        raise ValueError("Vision model output must be a JSON object")
    return parsed