"""marry-lambda: a mission-critical, highly available marriage proposal service.

Deployed once. Intended to run forever. See SLA in the response metadata.
"""

import json

JSON_HEADERS = {
    "Content-Type": "application/json",
    "X-Powered-By": "love",
}


def _respond(status_code, body):
    # Lambda Function URLs expect an HTTP-shaped dict with a *string* body.
    # indent=2 so the proposal reads nicely in a terminal.
    return {
        "statusCode": status_code,
        "headers": JSON_HEADERS,
        "body": json.dumps(body, indent=2),
    }


def lambda_handler(event, context):
    params = event.get("queryStringParameters") or {}
    answer = (params.get("answer") or "").strip().lower()

    if answer == "no":
        return _respond(
            409,
            {
                "error": "invalid state transition",
                "detail": "'no' is not a reachable state from 'hopelessly in love'",
                "currentState": "hopelessly in love",
                "requestedState": "no",
                "allowedTransitions": ["yes", "YES", "obviously"],
                "retryAfter": "whenever you're ready (I'll wait)",
            },
        )

    return _respond(
        200,
        {
            "question": "Will you marry me?",
            "answer": "yes",
            "status": "ENGAGED",
            "confidence": 1.0,
            "consistencyModel": "immediately consistent (no eventual about it)",
            "breakingChange": True,
            "breakingChangeNotes": "single -> married requires a major version bump",
            "idempotent": True,
            "idempotencyNotes": "ask as many times as you like; the answer is cached",
            "ring": {
                "delivered": True,
                "shape": "circle",
                "shapeRationale": "no edge cases",
                "lookupComplexity": "O(1) — it's on your finger",
            },
            "metadata": {
                "loveVersion": "2.0.0",
                "uptime": "since the day we met",
                "sla": "99.999% — the remaining 0.001% covers when I'm hangry",
                "license": "Till Death Do Us Part (perpetual, non-transferable)",
                "deprecations": ["single()", "swiping", "splitting the bill"],
                "coldStarts": 0,
                "region": "wherever you are",
            },
            "_links": {
                "self": {"href": "/", "rel": "proposal"},
                "honeymoon": {"href": "/honeymoon", "rel": "next", "status": "PLANNING"},
                "forever": {"href": "/forever", "rel": "final"},
            },
        },
    )
