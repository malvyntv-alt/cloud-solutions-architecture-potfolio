"""Reusable Retrieve + Converse service; inject AWS clients for local testing.

Create a separate conversation for each session. Calls must be sequential.
"""
from copy import deepcopy
from dataclasses import dataclass


@dataclass(frozen=True)
class ChatResult:
    answer: str
    sources: tuple[str, ...]


class RagConversation:
    def __init__(self, retrieval_client, generation_client, knowledge_base_id,
                 model_id="amazon.nova-lite-v1:0", max_history_turns=5):
        if not knowledge_base_id or not knowledge_base_id.strip():
            raise ValueError("A Knowledge Base ID is required.")
        if not model_id or not model_id.strip():
            raise ValueError("A model ID is required.")
        if isinstance(max_history_turns, bool) or not isinstance(max_history_turns, int) or max_history_turns < 1:
            raise ValueError("max_history_turns must be a positive integer.")
        self.retrieval_client = retrieval_client
        self.generation_client = generation_client
        self.knowledge_base_id = knowledge_base_id
        self.model_id = model_id
        self.max_history_turns = max_history_turns
        self._history = []

    @property
    def history(self):
        """Return a copy to protect stored conversation state."""
        return deepcopy(self._history)

    def ask(self, question: str) -> ChatResult:
        if not isinstance(question, str) or not question.strip():
            raise ValueError("Question must be a non-empty string.")
        question = question.strip()
        results = self.retrieval_client.retrieve(
            knowledgeBaseId=self.knowledge_base_id,
            retrievalQuery={"text": question},
            retrievalConfiguration={
                "vectorSearchConfiguration": {"numberOfResults": 5}
            },
        ).get("retrievalResults", [])
        context = "\n\n".join(
            f"[{i}] {r.get('content', {}).get('text', '')}"
            for i, r in enumerate(results, 1)
        )
        user_message = {"role": "user", "content": [{
            "text": f"Context:\n{context}\n\nQuestion: {question}"
        }]}
        # Reserve room for this turn and commit only after a valid answer.
        prior_messages = 2 * (self.max_history_turns - 1)
        messages = deepcopy(self._history[-prior_messages:]) if prior_messages else []
        messages.append(user_message)
        response = self.generation_client.converse(
            modelId=self.model_id,
            system=[{"text": (
                "Answer using only the provided context. "
                "If the context does not contain the answer, say so."
            )}],
            messages=messages,
        )
        message = response["output"]["message"]
        answer = "\n".join(
            block["text"] for block in message["content"] if "text" in block
        )
        if message.get("role") != "assistant" or not answer.strip():
            raise ValueError("The model did not return a text answer.")
        sources = tuple(sorted({
            uri for result in results
            if (uri := result.get("location", {}).get("s3Location", {}).get("uri"))
        }))
        self._history = deepcopy(messages + [message])
        return ChatResult(answer=answer, sources=sources)
