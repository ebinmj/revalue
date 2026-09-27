import unittest

from app.ai.explanation import FallbackExplanationProvider, build_explanation_prompt, explain_item
from app.api.schemas import ExplainRequest, ProductAnalysis
from app.knowledge.rag import HashEmbedder, KnowledgeRetriever, LocalVectorStore, curated_knowledge_records


class RagTests(unittest.TestCase):
    def setUp(self) -> None:
        records = curated_knowledge_records()
        self.retriever = KnowledgeRetriever(LocalVectorStore(records, HashEmbedder()))
        self.analysis = ProductAnalysis(
            detected_category="Laptop",
            condition="Partially functional",
            possible_issue="Possible charging issue",
            visible_components=["SSD", "RAM", "Battery"],
            possible_materials=["Aluminium", "Plastic"],
            risk_factors=["Possible battery risk"],
        )

    def test_curated_dataset_has_requested_shape_and_size(self) -> None:
        records = curated_knowledge_records()

        self.assertGreaterEqual(len(records), 20)
        self.assertLessEqual(len(records), 50)
        self.assertTrue(all(record.title and record.content for record in records))
        self.assertTrue(all(record.timestamp.tzinfo is not None for record in records))

    def test_local_retrieval_returns_relevant_laptop_sources(self) -> None:
        results = self.retriever.retrieve("laptop battery and charging issue", limit=3)

        self.assertEqual(len(results), 3)
        self.assertTrue(any("Battery" in result.record.title for result in results))

    def test_prompt_distinguishes_retrieved_information_from_reasoning(self) -> None:
        request = ExplainRequest(
            analysis=self.analysis,
            question="What should I check before recovery?",
        )
        results = self.retriever.retrieve("battery laptop recovery", limit=2)
        prompt = build_explanation_prompt(request, results)

        self.assertIn("Retrieved information", prompt)
        self.assertIn("AI reasoning", prompt)
        self.assertIn("[RETRIEVED SOURCE 1]", prompt)
        self.assertIn("Do not invent prices", prompt)

    def test_explanation_returns_sources_with_local_provider(self) -> None:
        request = ExplainRequest(
            analysis=self.analysis,
            question="Can the components be recovered?",
        )
        response = explain_item(request, self.retriever, FallbackExplanationProvider())

        self.assertEqual(len(response.retrieved_sources), 5)
        self.assertIn("retrieved source information", response.explanation.lower())
        self.assertIn("Retrieved sources", response.disclaimer)


if __name__ == "__main__":
    unittest.main()
