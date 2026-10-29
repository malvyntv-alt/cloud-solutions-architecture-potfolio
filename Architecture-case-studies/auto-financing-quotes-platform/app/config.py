import os
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MODE = os.getenv("APP_MODE", "local")
REGION = os.getenv("AWS_REGION", "us-east-1")
DATABASE_PATH = os.getenv("DATABASE_PATH", str(ROOT / "data" / "quotes.db"))
DATABASE_SECRET_ARN = os.getenv("DATABASE_SECRET_ARN", "")
QUEUE_URL = os.getenv("QUEUE_URL", "")
ALB_ARN = os.getenv("ALB_ARN", "")
COGNITO_CLIENT_ID = os.getenv("COGNITO_CLIENT_ID", "")
COGNITO_ISSUER = os.getenv("COGNITO_ISSUER", "")
PUBLISH_ENABLED = os.getenv("PUBLISH_ENABLED", "true").lower() == "true"
PORT = int(os.getenv("PORT", "8080"))
