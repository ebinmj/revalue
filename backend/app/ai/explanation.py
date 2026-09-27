"""Source-grounded explanation generation for ReValue."""

from __future__ import annotations

import os
from typing import Any, Protocol

from app.api.schemas import ExplainRequest, ExplainResponse, ExplanationSource
from app.knowledge.rag import KnowledgeRetriever, RetrievedKnowledge, get_retriever


class ExplanationProvider(Protocol):
    def generate(self, prompt: str) -> str:
        ...


class FallbackExplanationProvider:
    """A useful local answer when a generative model is unavailable."""

    def generate(self, prompt: str) -> str:
        question = prompt.split("User question:", 1)[-1].split("\n", 1)[0].strip()
        return (
            f"For '{question}', review the retrieved source information before taking action. "
            "The available facts describe possibilities, not a definitive diagnosis. "
            "Use a qualified repair or recycling provider when the item, battery, or data may be unsafe."
        )


class QwenExplanationProvider:
    def __init__(self, model_id: str | None = None) -> None:
        self.model_id = model_id or os.getenv(
            "QWEN_VL_MODEL_ID", "Qwen/Qwen2.5-VL-3B-Instruct"
        )
        self._model: Any | None = None
        self._processor: Any | None = None

    def generate(self, prompt: str) -> str:
        model, processor = self._load()
        messages = [{"role": "user", "content": [{"type": "text", "text": prompt}]}]
        text = processor.apply_chat_template(
            messages, tokenize=False, add_generation_prompt=True
        )
        inputs = processor(text=[text], padding=True, return_tensors="pt").to(model.device)
        generated = model.generate(**inputs, max_new_tokens=500)
        return processor.batch_decode(
            generated[:, inputs.input_ids.shape[1]:],
            skip_special_tokens=True,
            clean_up_tokenization_spaces=False,
        )[0].strip()

    def _load(self) -> tuple[Any, Any]:
        if self._model is None or self._processor is None:
            from transformers import AutoProcessor, Qwen2_5_VLForConditionalGeneration

            self._processor = AutoProcessor.from_pretrained(self.model_id)
            self._model = Qwen2_5_VLForConditionalGeneration.from_pretrained(
                self.model_id, torch_dtype="auto", device_map="auto"
            )
        return self._model, self._processor


def explain_item(
    request: ExplainRequest,
    retriever: KnowledgeRetriever | None = None,
    provider: ExplanationProvider | None = None,
) -> ExplainResponse:
    retriever = retriever or get_retriever()
    retrieved = retriever.retrieve(_retrieval_query(request), limit=request.limit)
    prompt = build_explanation_prompt(request, retrieved)
    provider = provider or _provider()
    try:
        explanation = provider.generate(prompt)
    except Exception:
        explanation = FallbackExplanationProvider().generate(prompt)
    return ExplainResponse(
        explanation=explanation,
        retrieved_sources=[_source(item) for item in retrieved],
        disclaimer=(
            "Retrieved sources are shown separately from AI reasoning. "
            "This is informational guidance, not a technical diagnosis or unsafe repair instruction."
        ),
    )


def build_explanation_prompt(
    request: ExplainRequest, retrieved: list[RetrievedKnowledge]
) -> str:
    sources = "\n\n".join(
        f"[RETRIEVED SOURCE {index}]\n"
        f"Title: {item.record.title}\nCategory: {item.record.category}\n"
        f"Source: {item.record.source}\nURL: {item.record.source_url or 'none'}\n"
        f"Content: {item.record.content}"
        for index, item in enumerate(retrieved, start=1)
    )
    return f"""You are ReValue's explanation assistant.
Use the retrieved source information below as evidence. Clearly distinguish:
1. Retrieved information: state only what the sources say and name the source.
2. AI reasoning: cautiously connect those facts to this item's observations.
Do not invent prices, regulations, or technical diagnoses. Do not give unsafe repair instructions.
Use 'possible issue' for uncertain faults. If the sources do not answer something, say so.

Product observations: {request.analysis.model_dump_json()}
User question: {request.question}

Retrieved source information:
{sources or 'No relevant sources were retrieved.'}

Return a concise explanation with headings 'Retrieved information' and 'AI reasoning'."""


def _retrieval_query(request: ExplainRequest) -> str:
    return " ".join(
        [
            request.question,
            request.analysis.detected_category,
            request.analysis.condition,
            request.analysis.possible_issue,
            " ".join(request.analysis.visible_components),
            " ".join(request.analysis.risk_factors),
        ]
    )


def _provider() -> ExplanationProvider:
    if os.getenv("REVALUE_EXPLANATION_PROVIDER", "qwen").lower() == "mock":
        return FallbackExplanationProvider()
    return QwenExplanationProvider()


def _source(item: RetrievedKnowledge) -> ExplanationSource:
    return ExplanationSource(
        title=item.record.title,
        source=item.record.source,
        source_url=item.record.source_url,
        relevance=round(item.score, 4),
    )