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
    RepairResearchRequest,
    RepairResearchResponse,
)
from app.engine.mock_engine import estimate_repair, recommend_item
from app.search.web_search import PartSearchService, RepairResourceService, VideoSearchService, WebSearchService

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

@router.post("/repair/research", response_model=RepairResearchResponse)
def repair_research(request: RepairResearchRequest) -> RepairResearchResponse:
    """Search and rank targeted repair resources for a known model and symptom profile."""
    brand = request.brand or "ASUS"
    model = request.model or "TUF F15 FX506HC"

    web_results = WebSearchService().search(
        brand=brand,
        model=model,
        problem=request.problem,
        symptom=", ".join(request.symptoms),
        component=request.component,
    )
    repair_guides = RepairResourceService().search(
        brand=brand,
        model=model,
        problem=request.problem,
    )
    parts = PartSearchService().search(
        brand=brand,
        model=model,
        component=request.component or "Battery",
    )
    videos = VideoSearchService().search(
        brand=brand,
        model=model,
        issue=request.problem,
    )

    possible_causes = [
        "Power delivery / battery issue",
        "DC-in / charger input issue",
        "Motherboard power circuit fault (needs validation)",
    ]
    troubleshooting_steps = [
        "Verify the charger and charging indicator status.",
        "Follow the exact model troubleshooting steps from manufacturer support.",
        "Inspect battery and power delivery only if the device is safe to handle.",
    ]
    safety_warnings = [
        "If the battery is swollen, smoking, or physically damaged, stop and seek qualified service.",
        "Do not open the device or handle lithium batteries if there is visible damage or heat."
    ]

    sources = [
        RepairSource(
            title=item["title"],
            url=item["url"],
            source=item["source"],
            source_type=item["sourceType"],
            relevance_score=item["relevanceScore"],
        )
        for item in web_results
    ]

    repair_guide_items = [
        RepairGuideSummary(
            title=item["title"],
            description=item["description"],
            url=item["url"],
            source=item["source"],
            source_type=item["sourceType"],
            relevance_score=item["relevanceScore"],
        )
        for item in repair_guides
    ]

    part_items = [
        RepairPartSummary(
            name=item["name"],
            part_number=item.get("partNumber"),
            brand=item.get("brand"),
            model=item.get("model"),
            component=item.get("component"),
            price=item.get("price"),
            currency=item.get("currency"),
            seller=item.get("seller"),
            url=item.get("url"),
            compatibility_status=item.get("compatibilityStatus", "Needs verification"),
            source=item.get("source"),
        )
        for item in parts
    ]

    video_items = [
        RepairVideoSummary(
            title=item["title"],
            channel=item.get("channel"),
            url=item["url"],
            thumbnail_url=item.get("thumbnailUrl"),
            duration=item.get("duration"),
            description=item.get("description"),
            relevance_score=item.get("relevanceScore", 80),
            source=item.get("source"),
        )
        for item in videos
    ]

    return RepairResearchResponse(
        product=request.product,
        problem=request.problem,
        symptoms=request.symptoms,
        possible_causes=possible_causes,
        troubleshooting_steps=troubleshooting_steps,
        parts=part_items,
        repair_guides=repair_guide_items,
        videos=video_items,
        safety_warnings=safety_warnings,
        sources=sources,
        confidence="MEDIUM",
    )
