import pytest
from app import config
from app.db import migrate


@pytest.fixture(autouse=True)
def isolated_db(tmp_path, monkeypatch):
    monkeypatch.setattr(config, "MODE", "local")
    monkeypatch.setattr(config, "DATABASE_PATH", str(tmp_path / "test.db"))
    migrate()


@pytest.fixture
def owner():
    return {"sub": "alice", "email": "alice@example.test"}


@pytest.fixture
def quote_input():
    return {"vehicle": "2026 Toyota RAV4", "vehicle_price": "35000", "down_payment": "5000",
            "term_months": "60", "credit_tier": "good"}

