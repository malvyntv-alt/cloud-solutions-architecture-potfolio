import json
import logging
import mimetypes
import os
import threading
import time
from http import HTTPStatus
from pathlib import Path
from socketserver import ThreadingMixIn
from wsgiref.simple_server import WSGIServer, make_server
from . import config
from .auth import identity, Unauthorized
from .db import connect, migrate
from .domain import calculate, ValidationError
from .quotes import save, list_quotes, events

logging.basicConfig(level=logging.INFO, format="%(message)s")
log = logging.getLogger(__name__)


def response(start, code, body, content_type="application/json"):
    encoded = (json.dumps(body) if content_type == "application/json" else body).encode("utf-8")
    headers = [("Content-Type", content_type + "; charset=utf-8"), ("Content-Length", str(len(encoded))),
               ("X-Content-Type-Options", "nosniff"), ("Referrer-Policy", "same-origin"),
               ("X-Frame-Options", "DENY"), ("Cache-Control", "no-store"),
               ("Content-Security-Policy", "default-src 'self'; script-src 'self'; style-src 'self'; img-src 'self' data:; connect-src 'self'; frame-ancestors 'none'; base-uri 'self'; form-action 'self'")]
    if config.MODE == "aws":
        headers.append(("Strict-Transport-Security", "max-age=31536000"))
    start(f"{code} {HTTPStatus(code).phrase}", headers)
    return [encoded]


def application(environ, start):
    path, method = environ.get("PATH_INFO", "/"), environ["REQUEST_METHOD"]
    request_id = str(__import__("uuid").uuid4())
    try:
        if path == "/healthz" and method == "GET":
            return response(start, 200, {"status": "alive"})
        user = identity(environ)
        payload = {}
        if method == "POST":
            # JSON + same-origin fetch required; blocks cross-site form submissions.
            if not environ.get("CONTENT_TYPE", "").startswith("application/json"):
                return response(start, 415, {"error": "JSON content type is required."})
            size = int(environ.get("CONTENT_LENGTH") or 0)
            if size < 1 or size > 16384:
                return response(start, 413, {"error": "Request body must contain 1â€“16384 bytes."})
            payload = json.loads(environ["wsgi.input"].read(size))
            if not isinstance(payload, dict):
                raise ValidationError("Expected a JSON object.")
        if path == "/api/session" and method == "GET":
            return response(start, 200, {**user, "mode": config.MODE, "region": config.REGION})
        if path == "/api/quotes/preview" and method == "POST":
            return response(start, 200, calculate(payload))
        if path == "/api/quotes" and method == "POST":
            quote, created = save(payload, user, environ.get("HTTP_IDEMPOTENCY_KEY", ""))
            log.info(json.dumps({"event": "quote_saved", "quote_id": quote["id"], "request_id": request_id, "created": created}))
            return response(start, 201 if created else 200, {"quote": quote, "created": created})
        if path == "/api/quotes" and method == "GET":
            return response(start, 200, {"quotes": list_quotes(user["sub"])})
        if path == "/api/events" and method == "GET":
            return response(start, 200, {"events": events(user["sub"])})
        if path == "/api/system" and method == "GET":
            with connect() as db:
                pending = db.one("""SELECT COUNT(*) AS count, MIN(e.created_at) AS oldest FROM outbox_events e
                    JOIN quotes q ON q.id=e.quote_id WHERE q.owner_id=? AND e.published_at IS NULL""", (user["sub"],))
            settings = {}
            if config.MODE == "local":
                with connect() as db:
                    settings = {row["key"]: row["value"] == "true" for row in db.all("SELECT * FROM demo_settings")}
            return response(start, 200, {"mode": config.MODE, "pending": pending["count"],
                "oldest_age_seconds": round(time.time()-pending["oldest"]) if pending["oldest"] else 0, "faults": settings})
        if path == "/api/inbox" and method == "GET":
            if config.MODE != "local":
                return response(start, 200, {"messages": [], "note": "AWS mode sends to your verified account email through SES."})
            with connect() as db:
                messages = db.all("SELECT * FROM demo_inbox WHERE owner_id=? ORDER BY created_at DESC LIMIT 100", (user["sub"],))
            return response(start, 200, {"messages": messages})
        if path == "/api/demo/fault" and method == "POST" and config.MODE == "local":
            if payload.get("name") not in ("sqs_down", "email_down", "ambiguous_ack") or not isinstance(payload.get("enabled"), bool):
                raise ValidationError("Unknown failure control.")
            with connect(write=True) as db:
                db.execute("""INSERT INTO demo_settings(key,value) VALUES (?,?) ON CONFLICT(key) DO UPDATE SET value=excluded.value""",
                    (payload["name"], str(payload["enabled"]).lower()))
                if not payload["enabled"]:
                    db.execute("UPDATE outbox_events SET available_at=0 WHERE published_at IS NULL")
            return response(start, 200, {"ok": True})
        if path == "/api/demo/tick" and method == "POST" and config.MODE == "local":
            local_tick()
            return response(start, 200, {"ok": True})
        if path.startswith("/api/"):
            return response(start, 404, {"error": "Not found."})
        if method != "GET":
            return response(start, 405, {"error": "Method not allowed."})
        filenames = {"/": "index.html", "/app.js": "app.js", "/styles.css": "styles.css"}
        if path not in filenames:
            return response(start, 404, {"error": "Not found."})
        file = config.ROOT / "web" / filenames[path]
        return response(start, 200, file.read_text(encoding="utf-8"), mimetypes.guess_type(file.name)[0] or "text/plain")
    except Unauthorized as error:
        return response(start, 401, {"error": str(error)})
    except (ValidationError, json.JSONDecodeError, ValueError) as error:
        return response(start, 400, {"error": str(error)})
    except Exception as error:
        log.error(json.dumps({"event": "request_failed", "request_id": request_id, "category": type(error).__name__}))
        return response(start, 503, {"error": "Temporarily unavailable. Retry with the same idempotency key.", "request_id": request_id})


_tick_lock = threading.Lock()


def local_tick():
    from .publisher import publish_one
    from .notifications import local_consume_one
    with _tick_lock:
        for _ in range(10):
            if not publish_one():
                break
        for _ in range(20):
            try:
                if not local_consume_one():
                    break
            except Exception:
                break


def local_loop():
    while True:
        try:
            local_tick()
        except Exception as error:
            log.warning("local_worker_failed: %s", type(error).__name__)
        time.sleep(2)


class ThreadedServer(ThreadingMixIn, WSGIServer):
    daemon_threads = True


def main():
    logging.basicConfig(level=logging.INFO, format="%(message)s")
    if config.MODE != "local":
        raise SystemExit("Use gunicorn for AWS; local dev server refuses APP_MODE=aws.")
    migrate()
    threading.Thread(target=local_loop, daemon=True).start()
    print(f"Local preview: http://127.0.0.1:{config.PORT}", flush=True)
    with make_server("127.0.0.1", config.PORT, application, server_class=ThreadedServer) as httpd:
        httpd.serve_forever()


if __name__ == "__main__":
    main()
