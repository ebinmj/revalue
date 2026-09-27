from __future__ import annotations

from pydantic import BaseModel, Field


class RepairResource(BaseModel):
    title: str
    description: str
    url: str
    source: str
    sourceType: str
    relevanceScore: int = Field(ge=0, le=100)
    publishedDate: str | None = None
    thumbnailUrl: str | None = None


class RepairPart(BaseModel):
    name: str
    partNumber: str | None = None
    brand: str | None = None
    model: str | None = None
    component: str | None = None
    price: str | None = None
    currency: str | None = None
    seller: str | None = None
    url: str | None = None
    compatibilityStatus: str = "Needs verification"
    source: str | None = None


class RepairVideo(BaseModel):
    title: str
    channel: str | None = None
    url: str
    thumbnailUrl: str | None = None
    duration: str | None = None
    description: str
    relevanceScore: int = Field(ge=0, le=100)
    source: str


class RepairResult(BaseModel):
    product: str
    problem: str
    symptoms: list[str] = Field(default_factory=list)
    possible_causes: list[str] = Field(default_factory=list)
    troubleshooting_steps: list[str] = Field(default_factory=list)
    parts: list[RepairPart] = Field(default_factory=list)
    repair_guides: list[RepairResource] = Field(default_factory=list)
    videos: list[RepairVideo] = Field(default_factory=list)
    safety_warnings: list[str] = Field(default_factory=list)
    sources: list[str] = Field(default_factory=list)
    confidence: str = "MEDIUM"
    disclaimer: str = "Evidence-based recommendations only; verify with manufacturer support before repair."
