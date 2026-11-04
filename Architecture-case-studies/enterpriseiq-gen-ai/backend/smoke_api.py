"""Interactive Cognito SRP sign-in and DEV API check; never persist tokens."""
import argparse
import getpass
import json
import warnings
from urllib.error import HTTPError
from urllib.parse import urlparse
from urllib.request import HTTPRedirectHandler, Request, build_opener


class NoRedirects(HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


def secret(prompt):
    # Refuse getpass's echoing fallback in terminals without hidden input.
    with warnings.catch_warnings():
        warnings.simplefilter("error", getpass.GetPassWarning)
        return getpass.getpass(prompt)


def access_token(srp, password_challenge, prompt=secret):
    try:
        response = srp.authenticate_user()
    except password_challenge:
        print("Cognito requires a new permanent password.")
        password = prompt("New password: ")
        if not password or password != prompt("Confirm new password: "):
            raise ValueError("New passwords must match and must not be empty.")
        response = srp.set_new_password_challenge(password)
    token = response.get("AuthenticationResult", {}).get("AccessToken")
    if not token:
        raise ValueError("Sign-in did not complete. Check for an additional Cognito challenge.")
    return token


def post_question(url, question, token=None):
    parsed = urlparse(url)
    if parsed.scheme != "https" or not parsed.hostname or parsed.username or parsed.password:
        raise ValueError("The API URL must use HTTPS without embedded credentials.")
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    request = Request(url, data=json.dumps({"question": question}).encode(),
                      headers=headers, method="POST")
    opener = build_opener(NoRedirects())
    try:
        with opener.open(request, timeout=40) as response:
            return response.status, response.read().decode("utf-8")
    except HTTPError as error:
        with error:
            return error.code, error.read().decode("utf-8")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--user-pool-id", required=True)
    parser.add_argument("--client-id", required=True)
    parser.add_argument("--url", required=True)
    parser.add_argument("--region", default="us-east-1")
    parser.add_argument("--question", default="What is the example disaster recovery RTO?")
    args = parser.parse_args()
    try:
        from pycognito.aws_srp import AWSSRP
        from pycognito.exceptions import ForceChangePasswordException

        status, _ = post_question(args.url, args.question)
        print(f"Unauthenticated request: HTTP {status} (expected 401)")
        if status != 401:
            raise ValueError("Authentication check failed; expected HTTP 401.")
        srp = AWSSRP(
            username=input("Cognito user email: ").strip(),
            password=secret("Password (temporary password on first sign-in): "),
            pool_id=args.user_pool_id, client_id=args.client_id, pool_region=args.region,
        )
        token = access_token(srp, ForceChangePasswordException)
        print("Sign-in succeeded. Testing authenticated chat...")
        status, body = post_question(args.url, args.question, token)
        print(f"Authenticated request: HTTP {status}")
        if status != 200:
            raise ValueError("Chat request failed. Inspect Lambda/API logs for this request.")
        payload = json.loads(body)
        if not isinstance(payload.get("answer"), str) or not isinstance(payload.get("sources"), list):
            raise ValueError("Unexpected chat response format.")
        print("\nAnswer:", payload["answer"])
        print("Sources:")
        for source in payload["sources"]:
            print("-", source)
    except (KeyboardInterrupt, EOFError):
        raise SystemExit("Sign-in cancelled.") from None
    except Exception as error:
        # SDK/HTTP exception strings can include sensitive request details.
        if isinstance(error, ValueError):
            message = str(error)
        elif isinstance(error, ImportError):
            message = "Install backend/requirements-smoke.txt first."
        else:
            message = f"Operation failed ({type(error).__name__}). Check credentials, connectivity and user status."
        raise SystemExit(message) from None


if __name__ == "__main__":
    main()
