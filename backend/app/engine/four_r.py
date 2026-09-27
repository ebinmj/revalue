from typing import Literal

from pydantic import BaseModel, Field


class FourRFacts(BaseModel):
    """Structured facts consumed by the deterministic 4R decision engine."""

    repair_cost: float = Field(ge=0)
    replacement_cost: float = Field(gt=0)
    reusable_component_value: float = Field(ge=0)
    recyclable: bool
    hazardous: bool
    condition: str = Field(min_length=1)
    repairable: bool


class FourRScores(BaseModel):
    reduce_score: int = Field(ge=0, le=100)
    reuse_score: int = Field(ge=0, le=100)
    recycle_score: int = Field(ge=0, le=100)
    riddance_score: int = Field(ge=0, le=100)


class FourRResult(BaseModel):
    recommendation: Literal["Reduce", "Reuse", "Recycle", "Riddance"]
    scores: FourRScores
    reasons: list[str]


def evaluate_four_r(facts: FourRFacts) -> dict[str, object]:
    """Calculate explainable ReValue scores from structured facts.

    These are deterministic recommendation scores, not probabilities or
    predictions. Each score is built from simple rule contributions below.
    """
    scores = FourRScores(
        reduce_score=_reduce_score(facts),
        reuse_score=_reuse_score(facts),
        recycle_score=_recycle_score(facts),
        riddance_score=_riddance_score(facts),
    )
    score_map = scores.model_dump()
    recommendation_key = max(score_map, key=score_map.get)
    recommendation = {
        "reduce_score": "Reduce",
        "reuse_score": "Reuse",
        "recycle_score": "Recycle",
        "riddance_score": "Riddance",
    }[recommendation_key]

    return FourRResult(
        recommendation=recommendation,
        scores=scores,
        reasons=_reasons(facts, recommendation),
    ).model_dump()


def _reduce_score(facts: FourRFacts) -> int:
    if not facts.repairable:
        return 10

    repair_ratio = facts.repair_cost / facts.replacement_cost
    if repair_ratio <= 0.2:
        return 90
    if repair_ratio <= 0.4:
        return 78
    if repair_ratio <= 0.7:
        return 62
    return 45


def _reuse_score(facts: FourRFacts) -> int:
    value_ratio = facts.reusable_component_value / facts.replacement_cost
    score = 20 + min(60, round(value_ratio * 100))
    condition = facts.condition.lower()
    if any(term in condition for term in ("good", "working", "functional")):
        score += 15
    return min(score, 100)


def _recycle_score(facts: FourRFacts) -> int:
    score = 60 if facts.recyclable else 15
    if facts.hazardous and facts.recyclable:
        score += 20
    return min(score, 100)


def _riddance_score(facts: FourRFacts) -> int:
    score = 15
    if facts.hazardous:
        score += 65
    if not facts.repairable:
        score += 15
    if not facts.recyclable:
        score += 5
    return min(score, 100)


def _reasons(facts: FourRFacts, recommendation: str) -> list[str]:
    reasons = [
        f"{recommendation} has the highest deterministic recommendation score for these facts.",
    ]
    if facts.repairable:
        reasons.append("The item is marked repairable, so repair remains a viable recovery path.")
    if facts.reusable_component_value > 0:
        reasons.append(
            f"Potential component recovery value is {facts.reusable_component_value:g} in the provided estimate."
        )
    if facts.recyclable:
        reasons.append("The item is marked recyclable, so material recovery is available as an option.")
    if facts.hazardous:
        reasons.append("Hazardous handling facts increase the need for a responsible disposal pathway.")
    if facts.repairable and facts.repair_cost < facts.replacement_cost:
        reasons.append("The provided repair cost is below the replacement cost estimate.")
    return reasons
