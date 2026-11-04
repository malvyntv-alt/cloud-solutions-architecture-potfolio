import unittest
from unittest.mock import Mock, patch

from backend.smoke_api import access_token, post_question, NoRedirects


class PasswordChallenge(Exception):
    pass


class SmokeApiTests(unittest.TestCase):
    def test_normal_sign_in_uses_access_token(self):
        srp = Mock()
        srp.authenticate_user.return_value = {"AuthenticationResult": {"AccessToken": "access", "IdToken": "id"}}
        self.assertEqual(access_token(srp, PasswordChallenge), "access")
        srp.set_new_password_challenge.assert_not_called()

    def test_temporary_password_challenge(self):
        srp = Mock()
        srp.authenticate_user.side_effect = PasswordChallenge()
        srp.set_new_password_challenge.return_value = {"AuthenticationResult": {"AccessToken": "access"}}
        prompt = Mock(side_effect=["new-password", "new-password"])
        self.assertEqual(access_token(srp, PasswordChallenge, prompt), "access")
        srp.set_new_password_challenge.assert_called_once_with("new-password")

    def test_password_mismatch_never_submits(self):
        srp = Mock()
        srp.authenticate_user.side_effect = PasswordChallenge()
        with self.assertRaises(ValueError):
            access_token(srp, PasswordChallenge, Mock(side_effect=["one", "two"]))
        srp.set_new_password_challenge.assert_not_called()

    def test_incomplete_sign_in_rejected(self):
        srp = Mock()
        srp.authenticate_user.return_value = {"ChallengeName": "SMS_MFA"}
        with self.assertRaises(ValueError):
            access_token(srp, PasswordChallenge)

    def test_insecure_urls_rejected(self):
        for url in ("http://example.com/chat", "https://user:pass@example.com/chat"):
            with self.subTest(url=url), self.assertRaises(ValueError):
                post_question(url, "question", "token")

    def test_redirects_disabled(self):
        self.assertIsNone(NoRedirects().redirect_request(None, None, 302, "", {}, "https://elsewhere"))

    @patch("backend.smoke_api.build_opener")
    def test_bearer_header_and_json_request(self, build):
        response = build.return_value.open.return_value.__enter__.return_value
        response.status = 200
        response.read.return_value = b'{"answer":"ok","sources":[]}'
        status, body = post_question("https://example.com/chat", "RTO?", "token")
        self.assertEqual(status, 200)
        request = build.return_value.open.call_args.args[0]
        self.assertEqual(request.get_header("Authorization"), "Bearer token")
        self.assertIn(b"RTO?", request.data)


if __name__ == "__main__":
    unittest.main()
