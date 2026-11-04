"""Offline service tests; no boto3, credentials or AWS calls required."""
import unittest
from unittest.mock import Mock

from backend.rag_service import RagConversation


class RagConversationTests(unittest.TestCase):
    def setUp(self):
        self.retrieval = Mock()
        self.retrieval.retrieve.return_value = {"retrievalResults": [
            {"content": {"text": "RTO is four hours."},
             "location": {"s3Location": {"uri": "s3://example/dr.md"}}},
            {"content": {"text": "Recovery policy."},
             "location": {"s3Location": {"uri": "s3://example/dr.md"}}},
        ]}
        self.generation = Mock()
        self.generation.converse.return_value = {"output": {"message": {
            "role": "assistant", "content": [{"text": "Four hours."}]
        }}}
        self.chat = RagConversation(self.retrieval, self.generation, "test-kb")

    def test_answer_sources_and_preserved_request_contract(self):
        result = self.chat.ask("  What is the RTO?  ")
        self.assertEqual(result.answer, "Four hours.")
        self.assertEqual(result.sources, ("s3://example/dr.md",))
        self.retrieval.retrieve.assert_called_once_with(
            knowledgeBaseId="test-kb",
            retrievalQuery={"text": "What is the RTO?"},
            retrievalConfiguration={"vectorSearchConfiguration": {"numberOfResults": 5}},
        )
        request = self.generation.converse.call_args.kwargs
        self.assertEqual(request["modelId"], "amazon.nova-lite-v1:0")
        self.assertIn("[1] RTO is four hours.", request["messages"][0]["content"][0]["text"])

    def test_history_is_bounded_and_contains_complete_pairs(self):
        self.chat.max_history_turns = 2
        for question in ("first", "second", "third"):
            self.chat.ask(question)
        self.assertEqual([m["role"] for m in self.chat.history],
                         ["user", "assistant", "user", "assistant"])
        self.assertTrue(self.chat.history[0]["content"][0]["text"].endswith("second"))
        request = self.generation.converse.call_args.kwargs
        self.assertEqual(len(request["messages"]), 3)

    def test_one_turn_limit_discards_previous_messages(self):
        self.chat.max_history_turns = 1
        self.chat.ask("first")
        self.chat.ask("second")
        self.assertEqual(len(self.chat.history), 2)
        self.assertEqual(len(self.generation.converse.call_args.kwargs["messages"]), 1)

    def test_failures_do_not_change_history_and_retry_is_valid(self):
        self.chat.ask("first")
        before = self.chat.history
        self.generation.converse.side_effect = RuntimeError("unavailable")
        with self.assertRaises(RuntimeError):
            self.chat.ask("failed")
        self.assertEqual(self.chat.history, before)
        self.generation.converse.side_effect = None
        self.chat.ask("retry")
        self.assertEqual(len(self.chat.history), 4)

    def test_retrieval_failure_does_not_generate_or_save(self):
        self.retrieval.retrieve.side_effect = RuntimeError("unavailable")
        with self.assertRaises(RuntimeError):
            self.chat.ask("question")
        self.generation.converse.assert_not_called()
        self.assertEqual(self.chat.history, [])

    def test_empty_retrieval_is_passed_to_grounded_generation(self):
        self.retrieval.retrieve.return_value = {}
        self.assertEqual(self.chat.ask("unknown").sources, ())
        request = self.generation.converse.call_args.kwargs
        self.assertIn("say so", request["system"][0]["text"])

    def test_multiple_text_blocks_are_returned(self):
        self.generation.converse.return_value["output"]["message"]["content"] = [
            {"text": "First"}, {"text": "Second"}
        ]
        self.assertEqual(self.chat.ask("question").answer, "First\nSecond")

    def test_non_text_response_is_not_saved(self):
        self.generation.converse.return_value["output"]["message"]["content"] = []
        with self.assertRaises(ValueError):
            self.chat.ask("question")
        self.assertEqual(self.chat.history, [])

    def test_invalid_question_never_calls_aws(self):
        for question in ("", "  ", None, 12):
            with self.subTest(question=question), self.assertRaises(ValueError):
                self.chat.ask(question)
        self.retrieval.retrieve.assert_not_called()

    def test_history_is_defensive_and_sessions_are_independent(self):
        self.chat.ask("first")
        external = self.chat.history
        external[0]["content"][0]["text"] = "changed"
        self.assertNotEqual(self.chat.history, external)
        other = RagConversation(self.retrieval, self.generation, "test-kb")
        self.assertEqual(other.history, [])

    def test_invalid_history_limit(self):
        for limit in (0, -1, True, 1.5):
            with self.subTest(limit=limit), self.assertRaises(ValueError):
                RagConversation(self.retrieval, self.generation, "test-kb", max_history_turns=limit)


if __name__ == "__main__":
    unittest.main()
