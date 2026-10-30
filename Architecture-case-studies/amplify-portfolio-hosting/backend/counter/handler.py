"""Anonymous approximate page views. API Gateway supplies CORS."""
import base64
import json
import os

_table = None

def table():
    global _table
    if _table is None:
        import boto3
        from botocore.config import Config
        database = boto3.resource("dynamodb", config=Config(
            connect_timeout=1, read_timeout=2,
            retries={"total_max_attempts": 1, "mode": "standard"}))
        _table = database.Table(os.environ["TABLE_NAME"])
    return _table

def response(status, payload):
    return {"statusCode": status, "headers": {
        "content-type": "application/json", "cache-control": "no-store"},
        "body": json.dumps(payload)}

def handler(event, context):
    method = event.get("requestContext", {}).get("http", {}).get("method", "")
    if event.get("rawPath") != "/views":
        return response(404, {"error": "Not found"})
    if method not in ("GET", "POST"):
        return response(405, {"error": "Method not allowed"})
    if method == "POST":
        headers = {k.lower(): v for k, v in event.get("headers", {}).items()}
        if headers.get("content-type", "").split(";", 1)[0].strip().lower() != "application/json":
            return response(415, {"error": "JSON required"})
        try:
            body = event.get("body") or ""
            if event.get("isBase64Encoded"):
                body = base64.b64decode(body, validate=True).decode("utf-8")
            if not 1 <= len(body.encode("utf-8")) <= 512:
                return response(413, {"error": "Body must contain 1-512 bytes"})
            payload = json.loads(body)
            if not isinstance(payload, dict) or payload != {"page": "home"}:
                return response(400, {"error": "Expected only page=home"})
        except (ValueError, TypeError, UnicodeError):
            return response(400, {"error": "Invalid JSON"})
    elif (event.get("queryStringParameters") or {}) not in ({}, {"page": "home"}):
        return response(400, {"error": "Unknown query"})
    try:
        if method == "POST":
            data = table().update_item(Key={"pk": "PAGE#home"},
                UpdateExpression="ADD #views :one",
                ExpressionAttributeNames={"#views": "views"},
                ExpressionAttributeValues={":one": 1}, ReturnValues="UPDATED_NEW")
            count = data["Attributes"]["views"]
        else:
            data = table().get_item(Key={"pk": "PAGE#home"}, ConsistentRead=True,
                ProjectionExpression="#views", ExpressionAttributeNames={"#views": "views"})
            count = data.get("Item", {}).get("views", 0)
        value = int(count)
        if value < 0 or value > 9007199254740991 or value != count:
            raise ValueError("Invalid counter")
        return response(200, {"page": "home", "views": value})
    except Exception as error:
        print(json.dumps({"event": "counter_error", "category": type(error).__name__,
                          "request_id": getattr(context, "aws_request_id", "local")}))
        return response(503, {"error": "Counter temporarily unavailable"})
