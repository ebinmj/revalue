"""Interactive AI diagnostic system powered by Google Gemini.

Flow
----
1. /api/diagnostic/start
   - Receives: image_b64, initial_description
   - Returns:  session_id, identified_product, follow_up_questions (list[str]),
               is_complete=False

2. /api/diagnostic/continue
   - Receives: session_id, answers (list[str] mapping to the previous questions)
   - Returns:  follow_up_questions (list[str]) OR final_recommendation
               is_complete=True when recommendation is ready

Design principle
----------------
"AI Understands. Database Knows. ReValue Decides. Flutter Delivers."

Gemini is used ONLY for:
  - Visual understanding of the image
  - Generating contextual follow-up questions
  - Summarising findings from user answers

It does NOT decide the 4R path. That stays in the ReValue engine.
"""

from __future__ import annotations

import base64
import json
import logging
import os
import uuid
from typing import Any

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# In-memory session store (replace with Redis/DB for production)
# ---------------------------------------------------------------------------
_sessions: dict[str, dict[str, Any]] = {}

MAX_ROUNDS = 3  # Maximum follow-up rounds before forcing a conclusion


# ---------------------------------------------------------------------------
# Schema helpers (plain dicts; Pydantic models live in schemas.py)
# ---------------------------------------------------------------------------

def _empty_session(session_id: str, image_b64: str | None, description: str) -> dict[str, Any]:
    return {
        "session_id": session_id,
        "image_b64": image_b64,
        "initial_description": description,
        "conversation": [],   # list of {role, text}
        "round": 0,
        "identified_product": None,
        "is_complete": False,
        "final_recommendation": None,
    }


# ---------------------------------------------------------------------------
# Gemini provider
# ---------------------------------------------------------------------------

def _api_key() -> str | None:
    try:
        from dotenv import load_dotenv
        load_dotenv()
    except ImportError:
        pass
    return os.getenv("GEMINI_API_KEY")


def _gemini_available() -> bool:
    return bool(_api_key())


def _call_gemini(prompt_parts: list[Any]) -> str:
    """Call Gemini with a list of prompt parts (text strings and/or image blobs)."""
    import google.generativeai as genai  # type: ignore[import-untyped]

    genai.configure(api_key=_api_key())
    model = genai.GenerativeModel(
        model_name=os.getenv("GEMINI_MODEL", "gemini-1.5-flash"),
        generation_config={
            "temperature": 0.4,
            "max_output_tokens": 1024,
            "response_mime_type": "application/json",
        },
        safety_settings=[
            {"category": "HARM_CATEGORY_DANGEROUS_CONTENT", "threshold": "BLOCK_ONLY_HIGH"},
        ],
    )
    response = model.generate_content(prompt_parts)
    return response.text


def _image_part(image_b64: str) -> Any:
    """Build a Gemini inline_data part from a base64 image string."""
    import google.generativeai as genai  # type: ignore[import-untyped]

    # Strip data-URL prefix if present
    if "," in image_b64:
        header, data = image_b64.split(",", 1)
        mime = header.split(";")[0].replace("data:", "") or "image/jpeg"
    else:
        data = image_b64
        mime = "image/jpeg"

    return {
        "inline_data": {
            "mime_type": mime,
            "data": data,
        }
    }


# ---------------------------------------------------------------------------
# Prompt builders
# ---------------------------------------------------------------------------

_SYSTEM_CONTEXT = """You are ReValue's AI diagnostic assistant.
ReValue helps people decide what to do with broken, old or unwanted items before
throwing them away. Your role is to:
1. Identify the item from the image and description.
2. Ask targeted follow-up questions to understand the problem better.
3. After gathering enough information, summarise findings and give a repair/recovery
   recommendation aligned with the 4R framework: Reduce (repair), Reuse, Recycle, Riddance.

Rules:
- Ask at most 3 follow-up questions per round.
- Be concise and helpful.
- Do NOT invent prices, regulations, or technical diagnoses.
- Use 'possible issue' for uncertain faults.
- Always return valid JSON matching the exact schema described in the prompt.
"""

_START_PROMPT_TEMPLATE = """
{system_context}

The user has uploaded a photo and provided this initial description:
"{description}"

Step 1 – Identify the item from the photo.
Step 2 – Ask up to 3 targeted follow-up questions to better understand the problem.

Return a JSON object with exactly these keys:
{{
  "identified_product": "<product name, brand/model if visible, e.g. 'Dell Inspiron Laptop'>",
  "identified_condition": "<brief condition, e.g. 'Broken / partially functional'>",
  "ai_observation": "<1–2 sentences of what you can see or infer>",
  "follow_up_questions": ["<question 1>", "<question 2>", "<question 3>"],
  "is_complete": false
}}
"""

_CONTINUE_PROMPT_TEMPLATE = """
{system_context}

Context so far:
- Product: {product}
- Initial description: "{description}"
- Previous Q&A:
{qa_history}

Latest answers from the user:
{latest_answers}

Round: {round} of {max_rounds}

{"Since this is the final round, " if is_final else ""}
{"provide a comprehensive final recommendation." if is_final else "Ask up to 3 more focused follow-up questions OR conclude if you have enough information."}

Return a JSON object with exactly these keys:
{{
  "summary": "<brief summary of findings so far>",
  "follow_up_questions": [],  // empty list if is_complete is true
  "is_complete": true or false,
  "final_recommendation": {{   // include only when is_complete is true, else null
    "repairability": "<Highly repairable | Potentially repairable | Difficult to repair | Not worth repairing>",
    "repairability_score": <integer 0-100>,
    "possible_issue": "<most likely root cause>",
    "repair_areas": ["<component 1>", "<component 2>"],
    "repair_explanation": "<2-3 sentences explaining why repair makes or doesn't make sense>",
    "recommended_4r": "<Reduce | Reuse | Recycle | Riddance>",
    "recommended_action": "<specific action the user should take>",
    "waste_impact": "<1 sentence on environmental benefit if repaired/reused>"
  }}
}}
"""


# ---------------------------------------------------------------------------
# Mock fallback
# ---------------------------------------------------------------------------

def _mock_start_response(description: str) -> dict[str, Any]:
    """Deterministic response when Gemini is unavailable."""
    return {
        "identified_product": "Electronic Device",
        "identified_condition": "Broken / partially functional",
        "ai_observation": (
            "I can see an electronic item that appears to have some damage or fault. "
            "Let me ask a few questions to better understand the problem."
        ),
        "follow_up_questions": [
            "How long have you had this device and when did the problem start?",
            "Does the device show any lights, sounds, or signs of power when you try to turn it on?",
            "Has the device been dropped, exposed to water, or had any physical damage recently?",
        ],
        "is_complete": False,
    }


def _mock_continue_response(round_num: int, is_final: bool) -> dict[str, Any]:
    if not is_final:
        return {
            "summary": "I'm gathering more details to assess the repairability.",
            "follow_up_questions": [
                "How old is the device approximately?",
                "Has it been repaired before, and if so what was fixed?",
            ],
            "is_complete": False,
            "final_recommendation": None,
        }
    return {
        "summary": (
            "Based on the information provided, the device has a power or component-level fault "
            "that may be repairable."
        ),
        "follow_up_questions": [],
        "is_complete": True,
        "final_recommendation": {
            "repairability": "Potentially repairable",
            "repairability_score": 70,
            "possible_issue": "Possible power circuit or battery fault",
            "repair_areas": ["Battery", "Charging port", "Power circuit"],
            "repair_explanation": (
                "The symptoms you described suggest a power-related fault which is often repairable "
                "at a fraction of replacement cost. A qualified technician should inspect the device."
            ),
            "recommended_4r": "Reduce",
            "recommended_action": "Take the device to a qualified repair technician for diagnosis.",
            "waste_impact": "Repairing this device could extend its useful life by 2–4 years and prevent up to 15 kg of e-waste.",
        },
    }


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

def start_diagnostic(image_b64: str | None, description: str) -> dict[str, Any]:
    """Start a new diagnostic session. Returns initial identification + follow-up questions."""
    session_id = str(uuid.uuid4())
    session = _empty_session(session_id, image_b64, description)

    if _gemini_available():
        try:
            prompt_parts: list[Any] = []
            if image_b64:
                prompt_parts.append(_image_part(image_b64))
            prompt_parts.append(
                _START_PROMPT_TEMPLATE.format(
                    system_context=_SYSTEM_CONTEXT,
                    description=description,
                )
            )
            raw = _call_gemini(prompt_parts)
            result = _parse_json(raw)
        except Exception as exc:
            logger.warning("Gemini start_diagnostic failed: %s — using mock", exc)
            result = _mock_start_response(description)
    else:
        result = _mock_start_response(description)

    session["identified_product"] = result.get("identified_product", "Unknown device")
    session["conversation"].append(
        {"role": "assistant", "text": json.dumps(result)}
    )
    _sessions[session_id] = session

    return {
        "session_id": session_id,
        "identified_product": result.get("identified_product", "Unknown device"),
        "identified_condition": result.get("identified_condition", "Unknown condition"),
        "ai_observation": result.get("ai_observation", ""),
        "follow_up_questions": result.get("follow_up_questions", []),
        "is_complete": False,
        "final_recommendation": None,
        "disclaimer": (
            "AI observations are preliminary and do not constitute a technical diagnosis. "
            "ReValue is an assistive tool — consult a qualified professional before taking action."
        ),
    }


def continue_diagnostic(session_id: str, answers: list[str]) -> dict[str, Any]:
    """Continue a diagnostic session with the user's answers. Returns next questions or final result."""
    session = _sessions.get(session_id)
    if session is None:
        raise ValueError(f"Session '{session_id}' not found. It may have expired.")

    session["round"] += 1
    round_num = session["round"]
    is_final = round_num >= MAX_ROUNDS

    # Append user answers to conversation
    session["conversation"].append({"role": "user", "answers": answers})

    # Build Q&A history text
    qa_lines: list[str] = []
    prev_questions: list[str] = []
    for entry in session["conversation"]:
        if entry["role"] == "assistant":
            try:
                parsed = json.loads(entry["text"])
                prev_questions = parsed.get("follow_up_questions", [])
            except Exception:
                pass
        elif entry["role"] == "user":
            user_answers = entry.get("answers", [])
            for q, a in zip(prev_questions, user_answers):
                qa_lines.append(f"  Q: {q}\n  A: {a}")
            prev_questions = []
    qa_history = "\n".join(qa_lines) or "  (no prior Q&A)"

    latest_answers_text = "\n".join(f"  - {a}" for a in answers)

    if _gemini_available():
        try:
            prompt = _CONTINUE_PROMPT_TEMPLATE.format(
                system_context=_SYSTEM_CONTEXT,
                product=session["identified_product"],
                description=session["initial_description"],
                qa_history=qa_history,
                latest_answers=latest_answers_text,
                round=round_num,
                max_rounds=MAX_ROUNDS,
                is_final=is_final,
            )
            raw = _call_gemini([prompt])
            result = _parse_json(raw)
        except Exception as exc:
            logger.warning("Gemini continue_diagnostic failed: %s — using mock", exc)
            result = _mock_continue_response(round_num, is_final)
    else:
        result = _mock_continue_response(round_num, is_final)

    # Force completion if max rounds reached
    if is_final and not result.get("is_complete"):
        result["is_complete"] = True
        if not result.get("final_recommendation"):
            result["final_recommendation"] = _mock_continue_response(round_num, True)["final_recommendation"]

    session["is_complete"] = result.get("is_complete", False)
    session["final_recommendation"] = result.get("final_recommendation")
    session["conversation"].append({"role": "assistant", "text": json.dumps(result)})

    return {
        "session_id": session_id,
        "summary": result.get("summary", ""),
        "follow_up_questions": result.get("follow_up_questions", []),
        "is_complete": result.get("is_complete", False),
        "final_recommendation": result.get("final_recommendation"),
        "disclaimer": (
            "AI findings are based on available information and are not a technical diagnosis. "
            "Consult a qualified professional before taking action."
        ),
    }


def _parse_json(text: str) -> dict[str, Any]:
    cleaned = text.strip()
    if cleaned.startswith("```"):
        cleaned = cleaned.split("\n", 1)[1].rsplit("```", 1)[0].strip()
    parsed = json.loads(cleaned)
    if not isinstance(parsed, dict):
        raise ValueError("Gemini output must be a JSON object")
    return parsed
