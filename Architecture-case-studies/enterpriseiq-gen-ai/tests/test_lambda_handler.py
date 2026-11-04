"""HTTP API contract tests; no AWS calls or boto3 dependency."""
import base64
import json
import unittest
from unittest.mock import Mock, patch

from backend.lambda_handler import lambda_handler, MAX_BODY_BYTES, MAX_QUESTION_CHARS
from backend.rag_service import ChatResult


def event(body, **overrides):
    return {"requestContext": {"http": {"method": "POST"}}, "body": body, **overrides}


class LambdaHandlerTests(unittest.TestCase):
    def setUp(self):
        patcher = patch("backend.lambda_handler._create_conversation")
        self.factory = patcher.start()
        self.addCleanup(patcher.stop)
        self.factory.return_value.ask.return_value = ChatResult("Four hours.", ("s3://example/dr.md",))

    def test_success_contract(self):
        response = lambda_handler(event(json.dumps({"question": " RTO? "})), None)
        self.assertEqual(response["statusCode"], 200)
        self.assertEqual(json.loads(response["body"]), {
            "answer": "Four hours.", "sources": ["s3://example/dr.md"]})
        self.assertEqual(response["headers"]["Cache-Control"], "no-store")
        self.factory.return_value.ask.assert_called_once_with("RTO?")

    def test_base64_utf8_body(self):
        body = base64.b64encode(json.dumps({"question": "Recovery?"}).encode()).decode()
        self.assertEqual(lambda_handler(event(body, isBase64Encoded=True), None)["statusCode"], 200)

    def test_invalid_bodies_never_call_service(self):
        for body in (None, "", "{", "[]", "null", "{}", '{"question": 3}',
                     '{"question":" "}', '{"question":"x","history":[]}',
                     json.dumps({"question": "x" * (MAX_QUESTION_CHARS + 1)}),
                     "x" * (MAX_BODY_BYTES * 2 + 1)):
            with self.subTest(body=str(body)[:40]):
                self.assertEqual(lambda_handler(event(body), None)["statusCode"], 400)
        self.factory.assert_not_called()

    def test_invalid_base64_and_utf8(self):
        for body in ("!!!", base64.b64encode(b"\xff").decode()):
            self.assertEqual(lambda_handler(event(body, isBase64Encoded=True), None)["statusCode"], 400)
        self.factory.assert_not_called()

    def test_decoded_body_size_limit(self):
        body = base64.b64encode(b"x" * (MAX_BODY_BYTES + 1)).decode()
        self.assertEqual(lambda_handler(event(body, isBase64Encoded=True), None)["statusCode"], 400)
        self.factory.assert_not_called()

    def test_method_rejected(self):
        response = lambda_handler(event("{}", requestContext={"http": {"method": "GET"}}), None)
        self.assertEqual(response["statusCode"], 405)
        self.assertEqual(response["headers"]["Allow"], "POST")
        self.factory.assert_not_called()

    def test_configuration_error_is_sanitized(self):
        self.factory.side_effect = RuntimeError("private configuration")
        response = lambda_handler(event('{"question":"RTO?"}'), None)
        self.assertEqual(response["statusCode"], 500)
        self.assertNotIn("private configuration", response["body"])

    def test_upstream_error_is_sanitized(self):
        self.factory.return_value.ask.side_effect = RuntimeError("private document")
        response = lambda_handler(event('{"question":"RTO?"}'), None)
        self.assertEqual(response["statusCode"], 502)
        self.assertNotIn("private document", response["body"])

    def test_each_request_creates_a_new_conversation(self):
        first, second = Mock(), Mock()
        for conversation in (first, second):
            conversation.ask.return_value = ChatResult("Answer", ())
        self.factory.side_effect = [first, second]
        for question in ("first", "second"):
            lambda_handler(event(json.dumps({"question": question})), None)
        self.assertEqual(self.factory.call_count, 2)
        first.ask.assert_called_once_with("first")
        second.ask.assert_called_once_with("second")

    def test_diagnostics_exclude_exception_messages_and_question(self):
        error = RuntimeError("private document and token")
        error.response = {"Error": {"Code": "AccessDeniedException", "Message": "private document"}}
        error.operation_name = "Converse"
        self.factory.return_value.ask.side_effect = error
        with self.assertLogs("backend.lambda_handler", level="ERROR") as logs:
            lambda_handler(event('{"question":"private question"}'), None)
        output = " ".join(logs.output)
        self.assertIn("AccessDeniedException", output)
        self.assertIn("Converse", output)
        self.assertNotIn("private", output)
        self.assertNotIn("token", output)


if __name__ == "__main__":
    unittest.main()
