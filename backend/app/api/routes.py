from fastapi import APIRouter, HTTPException

from app.ai.explanation import explain_item
from app.ai.gemini_diagnostic import continue_diagnostic, start_diagnostic
from app.ai.vision import analyze_item
from app.api.schemas import (
    AnalyzeRequest,
    AnalyzeResponse,
    DiagnosticContinueRequest,
    DiagnosticContinueResponse,
    DiagnosticStartRequest,
    DiagnosticStartResponse,
    ExplainRequest,
    ExplainResponse,
    MarketplaceListing,
    MarketplaceMatchRequest,
    MarketplaceMatchResponse,
    RecommendRequest,
    RecommendResponse,
    RepairEstimateRequest,
    RepairEstimateResponse,
)
from app.engine.mock_engine import estimate_repair, recommend_item

router = APIRouter(prefix="/api")


@router.post("/analyze", response_model=AnalyzeResponse)
def analyze(request: AnalyzeRequest) -> AnalyzeResponse:
    return analyze_item(request)


@router.post("/explain", response_model=ExplainResponse)
def explain(request: ExplainRequest) -> ExplainResponse:
    return explain_item(request)


@router.post("/recommend", response_model=RecommendResponse)
def recommend(request: RecommendRequest) -> RecommendResponse:
    return recommend_item(request)


@router.post("/repair-estimate", response_model=RepairEstimateResponse)
def repair_estimate(request: RepairEstimateRequest) -> RepairEstimateResponse:
    return estimate_repair(request)


@router.post("/marketplace/match", response_model=MarketplaceMatchResponse)
def marketplace_match(
    request: MarketplaceMatchRequest,
) -> MarketplaceMatchResponse:
    listings = [
        MarketplaceListing(
            title="16GB DDR4 RAM",
            price=1800,
            condition="Good condition",
            category="Components",
            seller="Mock seller 01",
        ),
        MarketplaceListing(
            title="Laptop Display Panel",
            price=2500,
            condition="Working",
            category="Components",
            seller="Mock seller 02",
        ),
        MarketplaceListing(
            title="65W Laptop Charger",
            price=900,
            condition="Good condition",
            category="Electronics",
            seller="Mock seller 03",
        ),
        MarketplaceListing(
            title="SSD 512GB",
            price=2800,
            condition="Used",
            category="Components",
            seller="Mock seller 04",
        ),
    ]
    query = request.query.strip().lower()
    filtered = [
        listing
        for listing in listings
        if (not query or query in listing.title.lower())
        and (not request.category or listing.category == request.category)
    ]
    return MarketplaceMatchResponse(
        listings=filtered,
        disclaimer="Mock marketplace matches only. No payment, shipping or seller system is connected.",
    )


# ---------------------------------------------------------------------------
# Interactive Diagnostic endpoints
# ---------------------------------------------------------------------------

@router.post("/diagnostic/start", response_model=DiagnosticStartResponse)
def diagnostic_start(request: DiagnosticStartRequest) -> DiagnosticStartResponse:
    """Start a new AI-powered interactive diagnostic session."""
    result = start_diagnostic(
        image_b64=request.image_b64,
        description=request.description,
    )
    return DiagnosticStartResponse(**result)


@router.post("/diagnostic/continue", response_model=DiagnosticContinueResponse)
def diagnostic_continue(request: DiagnosticContinueRequest) -> DiagnosticContinueResponse:
    """Continue an existing diagnostic session with answers to follow-up questions."""
    try:
        result = continue_diagnostic(
            session_id=request.session_id,
            answers=request.answers,
        )
    except ValueError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
    return DiagnosticContinueResponse(**result)
