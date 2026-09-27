from __future__ import annotations

import io
import logging
from uuid import UUID

from fastapi import APIRouter, Depends, File, Form, HTTPException, Query, Response, UploadFile
from fastapi.concurrency import run_in_threadpool
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

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
    ComponentCreate,
    ListingStatus,
    MarketplaceListingCreate,
    MarketplaceListingUpdate,
    RecommendRequest,
    RecommendResponse,
    RepairEstimateRequest,
    RepairEstimateResponse,
    RepairResearchRequest,
    RepairResearchResponse,
    ProfileUpsertRequest,
)
from app.engine.mock_engine import estimate_repair, recommend_item
from app.search.web_search import PartSearchService, RepairResourceService, VideoSearchService, WebSearchService
from app.services.analysis_service import AnalysisService
from app.services.supabase_marketplace import SupabaseMarketplaceService
from app.services.vision_service import VisionProviderConfigurationError

logger = logging.getLogger("revalue")
router = APIRouter(prefix="/api")
analysis_service = AnalysisService()
marketplace_service = SupabaseMarketplaceService()
bearer_scheme = HTTPBearer(auto_error=False)


def authenticated_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
) -> dict:
    if credentials is None:
        raise HTTPException(status_code=401, detail="A Supabase bearer token is required.")
    user = marketplace_service.authenticate(credentials.credentials)
    return {**user, "_access_token": credentials.credentials}


@router.get("/health")
def health() -> dict[str, object]:
    return {
        "status": "ok",
        "model_loaded": True,
    }


@router.post("/analyze")
async def analyze(
    image: UploadFile = File(...),
    message: str = Form(...),
    mode: str = Form("quick_scan"),
    conversation_id: str | None = Form(default=None),
) -> dict:
    logger.info("REQUEST RECEIVED")
    logger.info("IMAGE RECEIVED")
    logger.info("ANALYSIS STARTED")

    image_bytes = await image.read()
    try:
        result = await run_in_threadpool(
            analysis_service.analyze_image,
            image_bytes,
            message,
            mode,
        )
    except VisionProviderConfigurationError as exc:
        raise HTTPException(status_code=503, detail=str(exc)) from exc
    except ValueError as exc:
        raise HTTPException(status_code=422, detail=str(exc)) from exc
    except Exception as exc:
        logger.exception('Image analysis failed.')
        raise HTTPException(status_code=502, detail='Vision analysis failed.') from exc
    result["conversation_id"] = conversation_id or "demo-conversation"
    result["mode"] = mode

    logger.info("ANALYSIS COMPLETED")
    logger.info("RESPONSE SENT")
    return result


@router.post("/explain", response_model=ExplainResponse)
def explain(request: ExplainRequest) -> ExplainResponse:
    return explain_item(request)


@router.post("/recommend", response_model=RecommendResponse)
def recommend(request: RecommendRequest) -> RecommendResponse:
    return recommend_item(request)


@router.post("/repair-estimate", response_model=RepairEstimateResponse)
def repair_estimate(request: RepairEstimateRequest) -> RepairEstimateResponse:
    return estimate_repair(request)


@router.post("/auth/profile")
def upsert_auth_profile(
    request: ProfileUpsertRequest,
    user: dict = Depends(authenticated_user),
) -> dict:
    return marketplace_service.upsert_profile(
        user["_access_token"],
        user,
        request.name,
    )


@router.get("/marketplace/listings")
def marketplace_listings(
    search: str = Query(default="", max_length=100),
    category: str | None = Query(default=None, max_length=80),
    condition: str | None = Query(default=None, max_length=80),
    status: ListingStatus | None = None,
    mine: bool = False,
    user: dict = Depends(authenticated_user),
) -> dict[str, list[dict]]:
    return {
        "listings": marketplace_service.list_listings(
            user["_access_token"],
            user["id"],
            search=search,
            category=category,
            condition=condition,
            status=status,
            mine=mine,
        )
    }


@router.post("/marketplace/listings", status_code=201)
def create_marketplace_listing(
    request: MarketplaceListingCreate,
    user: dict = Depends(authenticated_user),
) -> dict:
    return marketplace_service.create_listing(
        user["_access_token"],
        user["id"],
        request,
    )


@router.get("/marketplace/listings/{listing_id}")
def get_marketplace_listing(
    listing_id: UUID,
    user: dict = Depends(authenticated_user),
) -> dict:
    return marketplace_service.get_listing(user["_access_token"], str(listing_id))


@router.put("/marketplace/listings/{listing_id}")
def update_marketplace_listing(
    listing_id: UUID,
    request: MarketplaceListingUpdate,
    user: dict = Depends(authenticated_user),
) -> dict:
    return marketplace_service.update_listing(
        user["_access_token"],
        user["id"],
        str(listing_id),
        request,
    )


@router.delete("/marketplace/listings/{listing_id}", status_code=204)
def delete_marketplace_listing(
    listing_id: UUID,
    user: dict = Depends(authenticated_user),
) -> Response:
    marketplace_service.delete_listing(
        user["_access_token"], user["id"], str(listing_id)
    )
    return Response(status_code=204)


@router.post("/marketplace/listings/{listing_id}/components", status_code=201)
def create_listing_component(
    listing_id: UUID,
    request: ComponentCreate,
    user: dict = Depends(authenticated_user),
) -> dict:
    return marketplace_service.create_component(
        user["_access_token"],
        user["id"],
        str(listing_id),
        request,
    )


@router.get("/marketplace/listings/{listing_id}/components")
def get_listing_components(
    listing_id: UUID,
    user: dict = Depends(authenticated_user),
) -> dict[str, list[dict]]:
    return {
        "components": marketplace_service.list_components(
            user["_access_token"],
            str(listing_id),
        )
    }


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
