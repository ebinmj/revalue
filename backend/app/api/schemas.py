from decimal import Decimal
from enum import Enum

from pydantic import BaseModel, ConfigDict, Field


class ListingStatus(str, Enum):
    available = "available"
    reserved = "reserved"
    sold = "sold"
    removed = "removed"


class ProfileUpsertRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    name: str = Field(default="", max_length=120)


class MarketplaceListingCreate(BaseModel):
    model_config = ConfigDict(extra="forbid")

    title: str = Field(min_length=1, max_length=160)
    description: str = Field(default="", max_length=4000)
    category: str = Field(min_length=1, max_length=80)
    condition: str = Field(min_length=1, max_length=80)
    price: Decimal = Field(ge=0, max_digits=12, decimal_places=2)
    currency: str = Field(default="INR", min_length=3, max_length=3)
    image_url: str | None = Field(default=None, max_length=2048)


class MarketplaceListingUpdate(BaseModel):
    model_config = ConfigDict(extra="forbid")

    title: str | None = Field(default=None, min_length=1, max_length=160)
    description: str | None = Field(default=None, max_length=4000)
    category: str | None = Field(default=None, min_length=1, max_length=80)
    condition: str | None = Field(default=None, min_length=1, max_length=80)
    price: Decimal | None = Field(default=None, ge=0, max_digits=12, decimal_places=2)
    currency: str | None = Field(default=None, min_length=3, max_length=3)
    image_url: str | None = Field(default=None, max_length=2048)
    status: ListingStatus | None = None


class ComponentCreate(BaseModel):
    model_config = ConfigDict(extra="forbid")

    component_name: str = Field(min_length=1, max_length=120)
    brand: str | None = Field(default=None, max_length=120)
    model: str | None = Field(default=None, max_length=120)
    condition: str = Field(min_length=1, max_length=80)
    compatibility: str | None = Field(default=None, max_length=500)


class AnalyzeRequest(BaseModel):
    description: str = Field(min_length=1)
    image_reference: str | None = None


class ProductAnalysis(BaseModel):
    """Observable product facts extracted from an image and description."""

    detected_category: str
    brand_model: str | None = None
    condition: str
    visible_components: list[str] = Field(default_factory=list)
    possible_materials: list[str] = Field(default_factory=list)
    possible_issue: str
    risk_factors: list[str] = Field(default_factory=list)


class AnalyzeResponse(ProductAnalysis):
    disclaimer: str

    @classmethod
    def from_product_analysis(cls, analysis: ProductAnalysis) -> "AnalyzeResponse":
        return cls(
            **analysis.model_dump(),
            disclaimer="AI extraction is observational only and does not provide a diagnosis or recommendation.",
        )


class ExplainRequest(BaseModel):
    analysis: ProductAnalysis
    question: str = Field(min_length=1)
    limit: int = Field(default=5, ge=1, le=10)


class ExplanationSource(BaseModel):
    title: str
    source: str
    source_url: str | None = None
    relevance: float


class ExplainResponse(BaseModel):
    explanation: str
    retrieved_sources: list[ExplanationSource]
    disclaimer: str


class RecommendRequest(BaseModel):
    detected_category: str = Field(min_length=1)
    condition: str = Field(min_length=1)
    visible_components: list[str] = Field(default_factory=list)
    risk_factors: list[str] = Field(default_factory=list)


class RecommendationOption(BaseModel):
    path: str
    score: int = Field(ge=0, le=100)
    title: str
    explanation: str
    recommended_action: str


class RecommendResponse(BaseModel):
    best_next_step: str
    why: str
    options: list[RecommendationOption]
    disclaimer: str


class RepairEstimateRequest(BaseModel):
    detected_category: str = Field(min_length=1)
    condition: str = Field(min_length=1)
    possible_issue: str | None = None


class RepairEstimateResponse(BaseModel):
    parts_min: int
    parts_max: int
    labour_min: int
    labour_max: int
    service_min: int
    service_max: int
    repair_total_min: int
    repair_total_max: int
    replacement_from: int
    potential_value_retained_from: int
    disclaimer: str


class MarketplaceMatchRequest(BaseModel):
    query: str = ""
    category: str | None = None


class MarketplaceListing(BaseModel):
    title: str
    price: int
    condition: str
    category: str
    seller: str


class MarketplaceMatchResponse(BaseModel):
    listings: list[MarketplaceListing]
    disclaimer: str


class RepairResearchRequest(BaseModel):
    product: str = Field(min_length=1)
    problem: str = Field(min_length=1)
    symptoms: list[str] = Field(default_factory=list)
    brand: str | None = None
    model: str | None = None
    component: str | None = None


class RepairSource(BaseModel):
    title: str
    url: str
    source: str
    source_type: str
    relevance_score: int = Field(ge=0, le=100)


class RepairPartSummary(BaseModel):
    name: str
    part_number: str | None = None
    brand: str | None = None
    model: str | None = None
    component: str | None = None
    price: str | None = None
    currency: str | None = None
    seller: str | None = None
    url: str | None = None
    compatibility_status: str = "Needs verification"
    source: str | None = None


class RepairGuideSummary(BaseModel):
    title: str
    description: str
    url: str
    source: str
    source_type: str
    relevance_score: int = Field(ge=0, le=100)


class RepairVideoSummary(BaseModel):
    title: str
    channel: str | None = None
    url: str
    thumbnail_url: str | None = None
    duration: str | None = None
    description: str
    relevance_score: int = Field(ge=0, le=100)
    source: str


class RepairResearchResponse(BaseModel):
    product: str
    problem: str
    symptoms: list[str] = Field(default_factory=list)
    possible_causes: list[str] = Field(default_factory=list)
    troubleshooting_steps: list[str] = Field(default_factory=list)
    parts: list[RepairPartSummary] = Field(default_factory=list)
    repair_guides: list[RepairGuideSummary] = Field(default_factory=list)
    videos: list[RepairVideoSummary] = Field(default_factory=list)
    safety_warnings: list[str] = Field(default_factory=list)
    sources: list[RepairSource] = Field(default_factory=list)
    confidence: str = "MEDIUM"
    disclaimer: str = "Evidence-based recommendations only; verify with manufacturer support before repair."


# ---------------------------------------------------------------------------
# Interactive Diagnostic schemas
# ---------------------------------------------------------------------------

class DiagnosticStartRequest(BaseModel):
    description: str = Field(min_length=1)
    image_b64: str | None = None  # full data-URL or raw base64


class DiagnosticFinalRecommendation(BaseModel):
    repairability: str
    repairability_score: int = Field(ge=0, le=100)
    possible_issue: str
    repair_areas: list[str] = Field(default_factory=list)
    repair_explanation: str
    recommended_4r: str
    recommended_action: str
    waste_impact: str


class DiagnosticStartResponse(BaseModel):
    session_id: str
    identified_product: str
    identified_condition: str
    ai_observation: str
    follow_up_questions: list[str]
    is_complete: bool
    final_recommendation: DiagnosticFinalRecommendation | None = None
    disclaimer: str


class DiagnosticContinueRequest(BaseModel):
    session_id: str
    answers: list[str]


class DiagnosticContinueResponse(BaseModel):
    session_id: str
    summary: str
    follow_up_questions: list[str]
    is_complete: bool
    final_recommendation: DiagnosticFinalRecommendation | None = None
    disclaimer: str
