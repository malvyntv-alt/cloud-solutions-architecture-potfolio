import base64
import importlib.util
import io
import json
import threading
import unittest
from concurrent.futures import ThreadPoolExecutor
from contextlib import redirect_stdout
from decimal import Decimal
from pathlib import Path

spec = importlib.util.spec_from_file_location("counter", Path(__file__).resolve().parents[1] / "backend/counter/handler.py")
counter = importlib.util.module_from_spec(spec)
spec.loader.exec_module(counter)

class FakeTable:
    def __init__(self):
        self.count = 0
        self.calls = []
        self.lock = threading.Lock()
    def update_item(self, **kwargs):
        with self.lock:
            self.calls.append(kwargs)
            self.count += kwargs["ExpressionAttributeValues"][":one"]
            return {"Attributes": {"views": Decimal(self.count)}}
    def get_item(self, **kwargs):
        return {"Item": {"views": Decimal(self.count)}} if self.count else {}

def event(method="POST", payload=None):
    return {"rawPath": "/views", "requestContext": {"http": {"method": method}},
            "headers": {"content-type": "application/json"},
            "body": json.dumps({"page": "home"} if payload is None else payload)}

class CounterTests(unittest.TestCase):
    def setUp(self):
        counter._table = FakeTable()
    def test_empty_read_and_increment_then_read(self):
        self.assertEqual(json.loads(counter.handler(event("GET"), None)["body"])["views"], 0)
        self.assertEqual(json.loads(counter.handler(event(), None)["body"])["views"], 1)
        self.assertEqual(json.loads(counter.handler(event("GET"), None)["body"])["views"], 1)
    def test_update_contract_is_atomic_and_repeated_requests_count(self):
        counter.handler(event(), None)
        counter.handler(event(), None)
        self.assertEqual(counter._table.count, 2)
        self.assertEqual(counter._table.calls[0]["UpdateExpression"], "ADD #views :one")
        self.assertEqual(counter._table.calls[0]["Key"], {"pk": "PAGE#home"})
    def test_parallel_requests_use_a_single_counter_key(self):
        with ThreadPoolExecutor(max_workers=8) as pool:
            results = list(pool.map(lambda _: counter.handler(event(), None), range(40)))
        self.assertTrue(all(r["statusCode"] == 200 for r in results))
        self.assertEqual(counter._table.count, 40)
    def test_rejects_unknown_pages_and_extra_personal_fields(self):
        for body in [{"page": "other"}, {"page": "home", "email": "test@example.test"}, [], "home"]:
            with self.subTest(body=body):
                self.assertEqual(counter.handler(event(payload=body), None)["statusCode"], 400)
        self.assertEqual(counter._table.count, 0)
    def test_rejects_bad_json_type_and_size(self):
        value = event()
        value["body"] = "{"
        self.assertEqual(counter.handler(value, None)["statusCode"], 400)
        value["body"] = "x" * 513
        self.assertEqual(counter.handler(value, None)["statusCode"], 413)
        value["headers"] = {"content-type": "text/plain"}
        self.assertEqual(counter.handler(value, None)["statusCode"], 415)
    def test_base64_request(self):
        value = event()
        value["isBase64Encoded"] = True
        value["body"] = base64.b64encode(value["body"].encode()).decode()
        self.assertEqual(counter.handler(value, None)["statusCode"], 200)
        value["body"] = "!!!!"
        self.assertEqual(counter.handler(value, None)["statusCode"], 400)
    def test_rejects_unknown_route_method_and_query(self):
        value = event()
        value["rawPath"] = "/admin"
        self.assertEqual(counter.handler(value, None)["statusCode"], 404)
        self.assertEqual(counter.handler(event("DELETE"), None)["statusCode"], 405)
        value = event("GET")
        value["queryStringParameters"] = {"page": "private"}
        self.assertEqual(counter.handler(value, None)["statusCode"], 400)
    def test_database_failure_is_generic_and_has_no_error_details(self):
        class Broken:
            def update_item(self, **kwargs):
                raise RuntimeError("PRIVATE_VALUE_SHOULD_NOT_LEAK")
        counter._table = Broken()
        log = io.StringIO()
        with redirect_stdout(log):
            result = counter.handler(event(), None)
        self.assertEqual(result["statusCode"], 503)
        self.assertNotIn("PRIVATE_VALUE", json.dumps(result) + log.getvalue())
        self.assertEqual(json.loads(log.getvalue())["category"], "RuntimeError")
    def test_corrupt_count_returns_unavailable(self):
        counter._table.count = -3
        with redirect_stdout(io.StringIO()):
            self.assertEqual(counter.handler(event("GET"), None)["statusCode"], 503)

if __name__ == "__main__":
    unittest.main()
