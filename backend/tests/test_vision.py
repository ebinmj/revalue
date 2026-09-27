import os
import unittest

from app.ai.vision import FallbackVisionProvider, _extraction_prompt
from app.api.schemas import AnalyzeRequest


class VisionProviderTests(unittest.TestCase):
    def test_fallback_returns_product_analysis_without_recommendation_or_prices(self) -> None:
        analysis = FallbackVisionProvider().analyze(
            AnalyzeRequest(description="The screen is cracked")
        )

        self.assertEqual(analysis.detected_category, "Unknown product")
        self.assertIn("Possible issue", analysis.possible_issue)
        self.assertNotIn("score", str(analysis).lower())
        self.assertNotIn("price", str(analysis).lower())

    def test_prompt_forbids_decisions_and_requires_cautious_issue_language(self) -> None:
        prompt = _extraction_prompt("It powers on but the display is dim")

        self.assertIn("possible issue", prompt)
        self.assertIn("Do not calculate scores or recommendations", prompt)
        self.assertIn("detected_category", prompt)


if __name__ == "__main__":
    os.environ.setdefault("REVALUE_VISION_PROVIDER", "mock")
    unittest.main()