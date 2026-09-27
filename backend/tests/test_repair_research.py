import unittest

from app.search.web_search import PartSearchService, VideoSearchService, WebSearchService


class RepairResearchPipelineTests(unittest.TestCase):
    def test_specific_model_query_is_generated_for_asus_laptop(self) -> None:
        results = WebSearchService().search(
            brand="ASUS",
            model="TUF F15 FX506HC",
            problem="Laptop does not turn on",
            symptom="Charging indicator is on",
            component="battery",
        )

        self.assertTrue(results)
        self.assertTrue(any("ASUS" in item["title"] or item["source"] == "ASUS" for item in results))
        self.assertTrue(any("FX506HC" in item["title"] or "FX506HC" in item["url"] for item in results))

    def test_part_search_returns_source_backed_results(self) -> None:
        parts = PartSearchService().search(
            brand="ASUS",
            model="TUF F15 FX506HC",
            component="Battery",
        )

        self.assertTrue(parts)
        self.assertTrue(any(part["source"] for part in parts))
        self.assertTrue(any(part["compatibilityStatus"] for part in parts))

    def test_video_search_returns_relevant_tutorial_links(self) -> None:
        videos = VideoSearchService().search(
            brand="ASUS",
            model="TUF F15 FX506HC",
            issue="battery replacement",
        )

        self.assertTrue(videos)
        self.assertTrue(any("youtube" in video["url"].lower() or "youtu" in video["url"].lower() for video in videos))


if __name__ == "__main__":
    unittest.main()
