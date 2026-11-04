"""API Gateway HTTP API adapter. Authentication is enforced by the future gateway.

Package backend as a Python package and set handler to
backend.lambda_handler.lambda_handler. This endpoint is intentionally stateless.
"""
import base64
import binascii
import json
import logging
import os
import re

from .rag_service import RagConversation


MAX_BODY_BYTES = 32_768
MAX_QUESTION_CHARS = 4_000
LOGGER = logging.getLogger(__name__)


def _log_failure(stage, error, context):
    def identifier(value):
        return value if isinstance(value, str) and re.fullmatch(r"[A-Za-z0-9_.:-]{1,128}", value) else "unknown"

    details = getattr(error, "response", {})
    if not isinstance(details, dict):
        details = {}
    sdk_error = details.get("Error", {})
    code = sdk_error.get("Code") if isinstance(sdk_error, dict) else None
    LOGGER.error("chat_failure stage=%s type=%s code=%s operation=%s request_id=%s",
                 stage, identifier(type(error).__name__), identifier(code),
                 identifier(getattr(error, "operation_name", None)),
                 identifier(getattr(context, "aws_request_id", None)))


def _response(status, payload):
    return {
        "statusCode": status,
        "headers": {"Content-Type": "application/json", "Cache-Control": "no-store"},
        "body": json.dumps(payload),
    }


def _question(event):
    body = event.get("body")
    if not isinstance(body, str) or not body:
        raise ValueError("Request body must be a JSON object.")
    # Reject oversized encoded bodies before allocating decoded content.
    if len(body) > MAX_BODY_BYTES * 2:
        raise ValueError("Request body is too large.")
    if event.get("isBase64Encoded", False):
        try:
            raw = base64.b64decode(body, validate=True)
        except (ValueError, binascii.Error):
            raise ValueError("Request body contains invalid base64.") from None
    else:
        raw = body.encode("utf-8")
    if len(raw) > MAX_BODY_BYTES:
        raise ValueError("Request body is too large.")
    try:
        payload = json.loads(raw.decode("utf-8"))
    except (ValueError, UnicodeError):
        raise ValueError("Request body must contain valid UTF-8 JSON.") from None
    if not isinstance(payload, dict) or set(payload) != {"question"}:
        raise ValueError("Provide a JSON object containing only 'question'.")
    question = payload["question"]
    if not isinstance(question, str) or not question.strip():
        raise ValueError("Question must be a non-empty string.")
    question = question.strip()
    if len(question) > MAX_QUESTION_CHARS:
        raise ValueError(f"Question must be at most {MAX_QUESTION_CHARS} characters.")
    return question


def _create_conversation():
    import boto3

    region = os.getenv("AWS_REGION", "us-east-1")
    return RagConversation(
        retrieval_client=boto3.client("bedrock-agent-runtime", region_name=region),
        generation_client=boto3.client("bedrock-runtime", region_name=region),
        knowledge_base_id=os.environ["BEDROCK_KB_ID"],
        model_id=os.getenv("BEDROCK_MODEL_ARN", "amazon.nova-lite-v1:0"),
        max_history_turns=1,
    )


def lambda_handler(event, context):
    method = event.get("requestContext", {}).get("http", {}).get("method")
    if method != "POST":
        response = _response(405, {"error": "method_not_allowed", "message": "Use POST."})
        response["headers"]["Allow"] = "POST"
        return response
    try:
        question = _question(event)
    except (ValueError, UnicodeError) as error:
        return _response(400, {"error": "invalid_request", "message": str(error)})
    try:
        conversation = _create_conversation()
    except Exception as error:
        _log_failure("configuration", error, context)
        return _response(500, {"error": "configuration_error", "message": "Chat service is unavailable."})
    try:
        result = conversation.ask(question)
    except Exception as error:
        _log_failure("upstream", error, context)
        # Do not expose SDK exceptions, document content or user questions.
        return _response(502, {"error": "upstream_error", "message": "Unable to answer. Please try again."})
    return _response(200, {"answer": result.answer, "sources": list(result.sources)})
