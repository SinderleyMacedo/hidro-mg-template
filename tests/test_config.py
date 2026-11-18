from hidro_mg.config import schema


def test_schema_uses_default_catalog(monkeypatch):
    monkeypatch.delenv("UC_CATALOG", raising=False)
    assert schema("bronze") == "workspace.bronze"


def test_schema_uses_env_catalog(monkeypatch):
    monkeypatch.setenv("UC_CATALOG", "hidro_mg")
    assert schema("gold") == "hidro_mg.gold"
