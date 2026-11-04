"""Interactive CLI for the reusable RAG service."""
import os

if __package__:
    from .rag_service import RagConversation
else:
    from rag_service import RagConversation


def main():
    knowledge_base_id = os.getenv("BEDROCK_KB_ID", "").strip()
    if not knowledge_base_id:
        raise SystemExit("Set BEDROCK_KB_ID before starting the chatbot.")

    import boto3

    region = os.getenv("AWS_REGION", "us-east-1")
    conversation = RagConversation(
        retrieval_client=boto3.client("bedrock-agent-runtime", region_name=region),
        generation_client=boto3.client("bedrock-runtime", region_name=region),
        knowledge_base_id=knowledge_base_id,
        model_id=os.getenv("BEDROCK_MODEL_ARN", "amazon.nova-lite-v1:0"),
    )
    print("EnterpriseIQ AI Assistant")
    print("Type 'exit' to quit.")
    while True:
        try:
            question = input("\nYou: ").strip()
        except (EOFError, KeyboardInterrupt):
            print()
            break
        if question.lower() == "exit":
            break
        if not question:
            continue
        try:
            result = conversation.ask(question)
            print("\nEnterpriseIQ:")
            print(result.answer)
            print("\nSources:")
            for source in result.sources:
                print("-", source)
        except Exception as error:
            print("Request failed:", error)


if __name__ == "__main__":
    main()