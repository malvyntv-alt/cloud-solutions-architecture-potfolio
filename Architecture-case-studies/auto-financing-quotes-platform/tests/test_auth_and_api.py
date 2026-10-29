import io
import json
import time
import pytest
from app import auth, config
from app.server import application


def request(path, method="GET", body=None, headers=None):
    encoded = json.dumps(body).encode() if body is not None else b""
    env = {"PATH_INFO": path, "REQUEST_METHOD": method, "CONTENT_TYPE": "application/json",
           "CONTENT_LENGTH": str(len(encoded)), "wsgi.input": io.BytesIO(encoded), **(headers or {})}
    status = []
    result = b"".join(application(env, lambda code, _: status.append(code)))
    return int(status[0].split()[0]), json.loads(result)


def test_api_retries_and_failure_controls(quote_input):
    status, first = request("/api/quotes", "POST", quote_input, {"HTTP_IDEMPOTENCY_KEY": "http-request-key"})
    assert status == 201
    status, second = request("/api/quotes", "POST", quote_input, {"HTTP_IDEMPOTENCY_KEY": "http-request-key"})
    assert status == 200
    assert first["quote"]["id"] == second["quote"]["id"]


def test_aws_mode_rejects_fake_identity_and_demo_routes(monkeypatch):
    monkeypatch.setattr(config, "MODE", "aws")
    monkeypatch.setattr(config, "ALB_ARN", "expected-alb")
    monkeypatch.setattr(config, "COGNITO_CLIENT_ID", "client")
    monkeypatch.setattr(config, "COGNITO_ISSUER", "issuer")
    assert request("/api/quotes", headers={"HTTP_X_AMZN_OIDC_IDENTITY": "admin"})[0] == 401
    monkeypatch.setattr("app.server.identity", lambda _: {"sub": "test", "email": "test@example.test"})
    assert request("/api/demo/fault", "POST", {"name": "sqs_down", "enabled": True})[0] == 404


def test_alb_signature_signer_expiry_and_email(monkeypatch):
    import jwt
    from cryptography.hazmat.primitives.asymmetric import ec
    key = ec.generate_private_key(ec.SECP256R1())
    monkeypatch.setattr(config, "MODE", "aws")
    monkeypatch.setattr(config, "ALB_ARN", "expected-alb")
    monkeypatch.setattr(config, "COGNITO_CLIENT_ID", "client")
    monkeypatch.setattr(config, "COGNITO_ISSUER", "issuer")
    monkeypatch.setattr(auth, "public_key", lambda _: key.public_key())
    header = {"kid": "demo-key", "signer": "expected-alb", "client": "client", "iss": "issuer", "exp": time.time()+60}
    claims = {"sub": "alice", "email": "alice@example.test", "email_verified": "true"}
    token = jwt.encode(claims, key, algorithm="ES256", headers=header)
    assert auth.identity({"HTTP_X_AMZN_OIDC_DATA": token})["sub"] == "alice"
    for change in ({"signer": "another-alb"}, {"exp": time.time()-1}, {"client": "wrong-client"}):
        invalid = jwt.encode(claims, key, algorithm="ES256", headers={**header, **change})
        with pytest.raises(auth.Unauthorized):
            auth.identity({"HTTP_X_AMZN_OIDC_DATA": invalid})
    unverified = jwt.encode({**claims, "email_verified": False}, key, algorithm="ES256", headers=header)
    with pytest.raises(auth.Unauthorized):
        auth.identity({"HTTP_X_AMZN_OIDC_DATA": unverified})


@pytest.mark.parametrize("value", ["NaN", "Infinity", "-100", "hello", "999999999"])
def test_invalid_money_rejected(value, quote_input):
    assert request("/api/quotes/preview", "POST", {**quote_input, "vehicle_price": value})[0] == 400

