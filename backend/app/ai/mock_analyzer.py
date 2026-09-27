from app.api.schemas import AnalyzeRequest, AnalyzeResponse


def analyze_item(request: AnalyzeRequest) -> AnalyzeResponse:
    """Return deterministic placeholder analysis until an AI adapter is added."""
    return AnalyzeResponse(
        detected_category="Laptop",
        condition="Broken / partially functional",
        possible_issue="Possible power-related issue",
        visible_components=["RAM", "SSD", "Display", "Keyboard", "Battery", "Charger"],
        possible_materials=["Plastic", "Aluminium", "Copper", "Electronic components"],
        risk_factors=["Battery may require careful handling"],
        disclaimer="Mock analysis only. This is not an AI diagnosis.",
    )
