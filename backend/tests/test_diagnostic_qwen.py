import unittest

from app.ai.gemini_diagnostic import continue_diagnostic, start_diagnostic


class DiagnosticConversationPhaseOneTests(unittest.TestCase):
    def test_laptop_scenario_identifies_asus_and_asks_targeted_questions(self) -> None:
        result = start_diagnostic(
            None,
            "My ASUS laptop is not turning on.",
        )

        self.assertIn("ASUS", result["identified_product"])
        self.assertIn("laptop", result["identified_product"].lower())
        self.assertTrue(
            any("charging" in question.lower() for question in result["follow_up_questions"])
        )
        self.assertLessEqual(len(result["follow_up_questions"]), 5)

    def test_laptop_follow_up_can_advance_to_summary_and_recommendation(self) -> None:
        session = start_diagnostic(None, "My laptop is not turning on.")
        response = continue_diagnostic(
            session["session_id"],
            [
                "Nothing happens when I press the power button.",
                "The charging indicator lights up when plugged in.",
                "It stopped working suddenly yesterday.",
            ],
        )

        self.assertIn("possible", response["summary"].lower())
        self.assertTrue(response["is_complete"] or response["follow_up_questions"])


if __name__ == "__main__":
    unittest.main()
