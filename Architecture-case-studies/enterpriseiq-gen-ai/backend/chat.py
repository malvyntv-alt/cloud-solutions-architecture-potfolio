"""CLI retrieval smoke test; no application API is deployed in Phase 1."""
import argparse
import json
import boto3
from botocore.config import Config


def retrieve(knowledge_base_id: str, question: str, region: str):
    client = boto3.client(
        "bedrock-agent-runtime",
        region_name=region,
        config=Config(retries={"max_attempts": 10, "mode": "adaptive"}),
    )
    response = client.retrieve(
        knowledgeBaseId=knowledge_base_id,
        retrievalQuery={"text": question},
        retrievalConfiguration={"vectorSearchConfiguration": {"numberOfResults": 5}},
    )
    return [
        {
            "text": r.get("content", {}).get("text", ""),
            "score": r.get("score"),
            "location": r.get("location", {}),
        }
        for r in response.get("retrievalResults", [])
    ]


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--knowledge-base-id", required=True)
    parser.add_argument("--region", default="us-east-1")
    parser.add_argument("--question", default="What is the sample disaster recovery policy?")
    args = parser.parse_args()
    print(json.dumps(retrieve(args.knowledge_base_id, args.question, args.region), indent=2))
