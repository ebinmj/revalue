from app.api.schemas import (
    RecommendationOption,
    RecommendRequest,
    RecommendResponse,
    RepairEstimateRequest,
    RepairEstimateResponse,
)


def recommend_item(request: RecommendRequest) -> RecommendResponse:
    """Return deterministic recommendation scores, not probabilities."""
    options = [
        RecommendationOption(
            path="Reduce",
            score=84,
            title="Repair before replacing",
            explanation="Repair may be more valuable than replacing the entire product.",
            recommended_action="Explore repair and component recovery before disposal.",
        ),
        RecommendationOption(
            path="Reuse",
            score=78,
            title="Recover useful components",
            explanation="Several components may still have recovery or resale value.",
            recommended_action="Recover, donate or resell usable components.",
        ),
        RecommendationOption(
            path="Recycle",
            score=61,
            title="Recover electronic materials",
            explanation="Electronic materials and components can potentially be recovered.",
            recommended_action="Find a certified electronics recycling pathway.",
        ),
        RecommendationOption(
            path="Riddance",
            score=25,
            title="Dispose responsibly as a last resort",
            explanation="Use responsible e-waste disposal only for unrecoverable parts.",
            recommended_action="Use responsible disposal for unrecoverable parts.",
        ),
    ]
    return RecommendResponse(
        best_next_step="Explore repair and component recovery before disposal.",
        why="Repair and component recovery score highest because the item is partially functional and has recoverable parts.",
        options=options,
        disclaimer="Scores are deterministic ReValue Recommendation Scores, not probabilities.",
    )


def estimate_repair(request: RepairEstimateRequest) -> RepairEstimateResponse:
    """Return deterministic mock prices until a pricing backend is connected."""
    is_laptop = "laptop" in request.detected_category.lower()
    if is_laptop:
        parts_min, parts_max = 1200, 2200
        labour_min, labour_max = 800, 1200
        service_min, service_max = 500, 600
        replacement_from = 25000
        retained_from = 21000
    else:
        parts_min, parts_max = 800, 1800
        labour_min, labour_max = 700, 1200
        service_min, service_max = 400, 700
        replacement_from = 15000
        retained_from = 12000

    return RepairEstimateResponse(
        parts_min=parts_min,
        parts_max=parts_max,
        labour_min=labour_min,
        labour_max=labour_max,
        service_min=service_min,
        service_max=service_max,
        repair_total_min=parts_min + labour_min + service_min,
        repair_total_max=parts_max + labour_max + service_max,
        replacement_from=replacement_from,
        potential_value_retained_from=retained_from,
        disclaimer="Mock estimate only. Actual prices depend on product and local provider.",
    )
