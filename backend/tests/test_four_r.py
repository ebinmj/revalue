import unittest

from app.engine.four_r import FourRFacts, evaluate_four_r


class FourREngineTests(unittest.TestCase):
    def test_repairable_laptop_prefers_reduce(self) -> None:
        result = evaluate_four_r(
            FourRFacts(
                repair_cost=3000,
                replacement_cost=25000,
                reusable_component_value=1500,
                recyclable=True,
                hazardous=False,
                condition="Broken but partially functional",
                repairable=True,
            )
        )

        self.assertEqual(result["recommendation"], "Reduce")
        self.assertGreater(result["scores"]["reduce_score"], result["scores"]["reuse_score"])
        self.assertTrue(any("repairable" in reason.lower() for reason in result["reasons"]))

    def test_broken_laptop_with_reusable_components_prefers_reuse(self) -> None:
        result = evaluate_four_r(
            FourRFacts(
                repair_cost=22000,
                replacement_cost=25000,
                reusable_component_value=12000,
                recyclable=True,
                hazardous=False,
                condition="Broken",
                repairable=False,
            )
        )

        self.assertEqual(result["recommendation"], "Reuse")
        self.assertGreater(result["scores"]["reuse_score"], result["scores"]["recycle_score"])
        self.assertTrue(any("component recovery" in reason.lower() for reason in result["reasons"]))

    def test_non_repairable_hazardous_electronic_prefers_riddance(self) -> None:
        result = evaluate_four_r(
            FourRFacts(
                repair_cost=0,
                replacement_cost=10000,
                reusable_component_value=0,
                recyclable=False,
                hazardous=True,
                condition="Unsafe and non-functional",
                repairable=False,
            )
        )

        self.assertEqual(result["recommendation"], "Riddance")
        self.assertEqual(result["scores"]["riddance_score"], 100)
        self.assertTrue(any("hazardous" in reason.lower() for reason in result["reasons"]))

    def test_fully_reusable_product_prefers_reuse(self) -> None:
        result = evaluate_four_r(
            FourRFacts(
                repair_cost=0,
                replacement_cost=10000,
                reusable_component_value=8000,
                recyclable=True,
                hazardous=False,
                condition="Good and fully functional",
                repairable=False,
            )
        )

        self.assertEqual(result["recommendation"], "Reuse")
        self.assertGreater(result["scores"]["reuse_score"], result["scores"]["reduce_score"])
        self.assertTrue(all(0 <= score <= 100 for score in result["scores"].values()))

    def test_result_is_deterministic_and_never_uses_probability_language(self) -> None:
        facts = FourRFacts(
            repair_cost=3000,
            replacement_cost=25000,
            reusable_component_value=1500,
            recyclable=True,
            hazardous=False,
            condition="Partially functional",
            repairable=True,
        )

        first = evaluate_four_r(facts)
        second = evaluate_four_r(facts)

        self.assertEqual(first, second)
        self.assertNotIn("probability", str(first).lower())


if __name__ == "__main__":
    unittest.main()
