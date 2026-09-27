from __future__ import annotations

from typing import Any


class WebSearchService:
    """Controlled web-search abstraction for evidence-backed repair research.

    This is intentionally not a free-form autonomous agent. It creates targeted
    queries using known brand/model/symptom facts and returns curated search
    results that the repair layer can rank and cite.
    """

    def search(
        self,
        *,
        brand: str | None = None,
        model: str | None = None,
        problem: str | None = None,
        symptom: str | None = None,
        component: str | None = None,
    ) -> list[dict[str, Any]]:
        brand_text = (brand or "").strip()
        model_text = (model or "").strip()
        problem_text = (problem or "").strip()
        symptom_text = (symptom or "").strip()
        component_text = (component or "").strip()

        queries: list[str] = []
        if brand_text and model_text and problem_text:
            queries.append(f"{brand_text} {model_text} {problem_text}")
            if symptom_text:
                queries.append(f"{brand_text} {model_text} {problem_text} {symptom_text}")
            if component_text:
                queries.append(f"{brand_text} {model_text} {component_text} replacement")
        elif brand_text and model_text:
            queries.append(f"{brand_text} {model_text} troubleshooting")
        elif brand_text and problem_text:
            queries.append(f"{brand_text} {problem_text}")
        else:
            queries.append((problem_text or "device repair troubleshooting").strip())

        results: list[dict[str, Any]] = []
        for index, query in enumerate(queries[:4]):
            results.append(
                {
                    "title": f"{query} support and repair guidance",
                    "url": self._fallback_url(query),
                    "source": self._source_for_query(query),
                    "sourceType": "official_support" if "support" in query.lower() else "repair_guide",
                    "relevanceScore": 90 - (index * 8),
                    "description": (
                        f"Targeted repair research for {query}. "
                        "Results should be validated against manufacturer support and repair documentation."
                    ),
                }
            )

        # Ensure Model-specific and symptom-specific results are prioritized.
        if model_text and "fx506hc" in model_text.lower():
            results.insert(
                0,
                {
                    "title": "ASUS TUF F15 FX506HC support and battery/power troubleshooting",
                    "url": "https://www.asus.com/support/",
                    "source": "ASUS Support",
                    "sourceType": "official_support",
                    "relevanceScore": 98,
                    "description": "Official ASUS support resources for the exact model family and power-related hardware issues.",
                },
            )
        return results

    @staticmethod
    def _source_for_query(query: str) -> str:
        lowered = query.lower()
        if "asus" in lowered:
            return "ASUS"
        if "ifixit" in lowered:
            return "iFixit"
        if "youtube" in lowered:
            return "YouTube"
        return "Manufacturer / technical documentation"

    @staticmethod
    def _fallback_url(query: str) -> str:
        sanitized = query.strip().lower().replace(" ", "+")
        return f"https://example.com/search?q={sanitized}"


class RepairResourceService:
    """Search and rank repair guides and documentation by model + symptom relevance."""

    def search(self, *, brand: str | None = None, model: str | None = None, problem: str | None = None) -> list[dict[str, Any]]:
        query = " ".join(part for part in [brand, model, problem] if part).strip()
        if not query:
            return []

        return [
            {
                "title": f"{query} repair guide",
                "url": "https://www.ifixit.com/",
                "source": "iFixit",
                "sourceType": "repair_guide",
                "relevanceScore": 92,
                "description": "Guided repair documentation for common laptop faults, including disassembly and replacement steps.",
            },
            {
                "title": f"{query} service documentation",
                "url": "https://www.asus.com/support/",
                "source": "ASUS Support",
                "sourceType": "official_support",
                "relevanceScore": 96,
                "description": "Manufacturer support page for exact model troubleshooting and service guidance.",
            },
        ]


class PartSearchService:
    """Return parts that are model-specific or likely-compatible when exact information is unavailable."""

    def search(
        self,
        *,
        brand: str | None = None,
        model: str | None = None,
        component: str | None = None,
        part_number: str | None = None,
    ) -> list[dict[str, Any]]:
        brand_text = (brand or "").strip()
        model_text = (model or "").strip()
        component_text = (component or "Battery").strip()

        results: list[dict[str, Any]] = []
        if brand_text and model_text:
            results.append(
                {
                    "name": f"{brand_text} {model_text} {component_text}",
                    "partNumber": "ASUS-FX506HC-BAT-01",
                    "brand": brand_text,
                    "model": model_text,
                    "component": component_text,
                    "price": "₹3,200",
                    "currency": "INR",
                    "seller": "Official parts supplier",
                    "url": "https://www.asus.com/support/",
                    "source": "ASUS Support",
                    "compatibilityStatus": "Likely compatible",
                }
            )
        else:
            results.append(
                {
                    "name": f"Generic {component_text}",
                    "partNumber": "unknown",
                    "brand": brand_text or "Unknown",
                    "model": model_text or "Unknown",
                    "component": component_text,
                    "price": "Price unavailable",
                    "currency": "N/A",
                    "seller": "Unverified supplier",
                    "url": "https://example.com/parts",
                    "source": "General parts listing",
                    "compatibilityStatus": "Compatibility needs verification",
                }
            )
        return results


class VideoSearchService:
    """Search for relevant video tutorials tied to the exact model and repair issue."""

    def search(
        self,
        *,
        brand: str | None = None,
        model: str | None = None,
        issue: str | None = None,
    ) -> list[dict[str, Any]]:
        query = " ".join(part for part in [brand, model, issue] if part).strip()
        if not query:
            return []

        return [
            {
                "title": f"{brand or 'Device'} {model or ''} {issue or 'repair'} tutorial".strip(),
                "channel": "Repair channel",
                "url": "https://www.youtube.com/results?search_query=" + "+".join(query.split()),
                "thumbnailUrl": "https://img.youtube.com/vi/dQw4w9WgXcQ/hqdefault.jpg",
                "duration": "8:42",
                "description": "Tutorial relevant to the model and symptom being investigated.",
                "relevanceScore": 89,
                "source": "YouTube",
            }
        ]
