import json
import os
import sqlite3
import threading
import time
from contextlib import contextmanager
from pathlib import Path
from . import config

_secret = None
_secret_at = 0
_secret_lock = threading.Lock()


def credentials():
    global _secret, _secret_at
    with _secret_lock:
        if _secret is None or time.time() - _secret_at > 300:
            import boto3
            response = boto3.client("secretsmanager", region_name=config.REGION).get_secret_value(SecretId=config.DATABASE_SECRET_ARN)
            _secret = json.loads(response["SecretString"])
            _secret_at = time.time()
        return _secret


class Connection:
    def __init__(self, raw, postgres):
        self.raw, self.postgres = raw, postgres

    def execute(self, query, params=()):
        return self.raw.execute(query.replace("?", "%s") if self.postgres else query, params)

    def one(self, query, params=()):
        row = self.execute(query, params).fetchone()
        return dict(row) if row else None

    def all(self, query, params=()):
        return [dict(row) for row in self.execute(query, params).fetchall()]


@contextmanager
def connect(write=False):
    if config.MODE == "aws":
        import psycopg
        from psycopg.rows import dict_row
        secret = credentials()
        raw = psycopg.connect(host=os.getenv("DATABASE_HOST", secret.get("host")), port=5432,
                               dbname="quotes", user=secret["username"], password=secret["password"],
                               sslmode="verify-full", sslrootcert=os.getenv("RDS_CA_BUNDLE", "/app/rds-ca.pem"),
                               connect_timeout=5, row_factory=dict_row,
                               options="-c statement_timeout=5000 -c lock_timeout=2000")
    else:
        Path(config.DATABASE_PATH).parent.mkdir(parents=True, exist_ok=True)
        raw = sqlite3.connect(config.DATABASE_PATH, timeout=10)
        raw.row_factory = sqlite3.Row
        raw.execute("PRAGMA journal_mode=WAL")
        raw.execute("PRAGMA foreign_keys=ON")
        if write:
            raw.execute("BEGIN IMMEDIATE")
    try:
        yield Connection(raw, config.MODE == "aws")
        raw.commit()
    except Exception:
        raw.rollback()
        raise
    finally:
        raw.close()


def migrate():
    sql = (config.ROOT / "migrations" / "001_initial.sql").read_text(encoding="utf-8")
    with connect(write=True) as connection:
        for statement in sql.split(";"):
            if statement.strip():
                connection.execute(statement)
