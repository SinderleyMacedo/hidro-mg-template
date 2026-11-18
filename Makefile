.DEFAULT_GOAL := help
.PHONY: help setup setup-databricks db-auth lint format test check up down clean

VENV   ?= .venv
PYTHON ?= python3
BIN    := $(VENV)/bin
COMPOSE ?= docker compose -f infra/docker-compose.yml

help: ## Lista os alvos disponíveis
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "} {printf "  %-10s %s\n", $$1, $$2}'

setup: ## Cria o ambiente virtual e instala dependências de desenvolvimento
	$(PYTHON) -m venv $(VENV)
	$(BIN)/pip install --upgrade pip
	$(BIN)/pip install -e ".[dev]"
	@test -f .env || cp .env.example .env
	@echo "Ambiente pronto. Ative com: source $(VENV)/bin/activate"

setup-databricks: ## Instala o Databricks Connect (PySpark remoto no Databricks)
	$(BIN)/pip install -e ".[dev,databricks]"

db-auth: ## Login OAuth no workspace (Databricks CLI), host do .env
	databricks auth login --host "$$(grep '^DATABRICKS_HOST=' .env | cut -d= -f2)"

lint: ## Verifica estilo e formatação (ruff)
	$(BIN)/ruff check .
	$(BIN)/ruff format --check .

format: ## Corrige estilo e aplica a formatação (ruff)
	$(BIN)/ruff check --fix .
	$(BIN)/ruff format .

test: ## Roda os testes (pytest)
	$(BIN)/pytest

check: lint test ## Roda lint e testes, o mesmo que a CI

up: ## Sobe os serviços Docker locais (Airflow, Kafka, MCP)
	$(COMPOSE) up -d

down: ## Derruba os serviços Docker locais
	$(COMPOSE) down

clean: ## Remove caches e artefatos de build
	rm -rf .pytest_cache .ruff_cache .mypy_cache build dist *.egg-info
	find . -type d -name __pycache__ -not -path "./$(VENV)/*" -prune -exec rm -rf {} +
