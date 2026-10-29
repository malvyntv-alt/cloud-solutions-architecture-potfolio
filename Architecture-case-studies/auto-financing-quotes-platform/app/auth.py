"""Verify ALB-signed identity, not caller-supplied identity headers."""
import functools
import re
import time
import urllib.request
from . import config


class Unauthorized(Exception):
    pass


@functools.lru_cache(maxsize=16)
def public_key(kid):
    if not re.fullmatch(r"[A-Za-z0-9-]{1,128}", kid):
        raise Unauthorized("Invalid signing key.")
    url = f"https://public-keys.auth.elb.{config.REGION}.amazonaws.com/{kid}"
    with urllib.request.urlopen(url, timeout=3) as response:
        return response.read().decode()


def identity(environ):
    if config.MODE == "local":
        return {"sub": "local-demo-user", "email": "alex@example.test", "name": "Alex Morgan"}
    if not config.ALB_ARN or not config.COGNITO_CLIENT_ID or not config.COGNITO_ISSUER:
        raise Unauthorized("Authentication configuration is incomplete.")
    import jwt
    try:
        token = environ.get("HTTP_X_AMZN_OIDC_DATA", "")
        header = jwt.get_unverified_header(token)
        if header.get("alg") != "ES256" or header.get("signer") != config.ALB_ARN:
            raise Unauthorized("Unexpected identity signer.")
        if header.get("client") != config.COGNITO_CLIENT_ID or header.get("iss") != config.COGNITO_ISSUER:
            raise Unauthorized("Unexpected identity issuer or client.")
        if float(header.get("exp", 0)) <= time.time():
            raise Unauthorized("Session expired.")
        claims = jwt.decode(token, public_key(header["kid"]), algorithms=["ES256"], options={"verify_aud": False})
        if not claims.get("sub") or not claims.get("email") or str(claims.get("email_verified")).lower() != "true":
            raise Unauthorized("A verified email is required.")
        return {"sub": claims["sub"], "email": claims["email"], "name": claims.get("name", "Customer")}
    except Unauthorized:
        raise
    except Exception as error:
        raise Unauthorized("A valid authenticated session is required.") from error
