"""Configuração única, lida de variáveis de ambiente."""

import os


def catalog() -> str:
    return os.getenv("UC_CATALOG", "workspace")


def schema(layer: str) -> str:
    """Nome qualificado do schema de uma camada (raw, bronze, silver, gold)."""
    return f"{catalog()}.{layer}"
