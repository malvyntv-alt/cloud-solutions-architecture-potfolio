"""Run as a one-off ECS migration task with the admin secret, never as web startup."""
import json
import os
from .db import connect, migrate

def main():
    migrate()
    if os.getenv("APP_MODE") == "aws":
        import boto3
        import psycopg
        secret = json.loads(boto3.client("secretsmanager").get_secret_value(SecretId=os.environ["APP_SECRET_ARN"])["SecretString"])
        # Identifiers are fixed; password is a properly quoted SQL literal.
        with connect(write=True) as db:
            if not db.one("SELECT 1 AS exists FROM pg_roles WHERE rolname='quote_app'"):
                db.raw.execute(psycopg.sql.SQL("CREATE ROLE quote_app LOGIN PASSWORD {}").format(psycopg.sql.Literal(secret["password"])))
            else:
                db.raw.execute(psycopg.sql.SQL("ALTER ROLE quote_app PASSWORD {}").format(psycopg.sql.Literal(secret["password"])))
            db.execute("GRANT CONNECT ON DATABASE quotes TO quote_app")
            db.execute("GRANT USAGE ON SCHEMA public TO quote_app")
            for table in ("quotes", "outbox_events", "notification_ledger"):
                db.execute(f"GRANT SELECT, INSERT, UPDATE ON {table} TO quote_app")
    print("Schema ready; runtime uses quote_app, not the database administrator.")

if __name__ == "__main__":
    main()
