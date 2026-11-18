# CLAUDE.md

Guia para o Claude Code neste repositório. Este arquivo é a base reutilizável dos repositórios do portfólio "Hidro MG" (engenharia de dados e IA sobre dados públicos de água de Minas Gerais e IBGE). Ao copiar o modelo, preencha a seção "Decisões deste repositório" e mantenha o resto.

## Regras inegociáveis

1. **Só dados públicos.** Nenhum dado, credencial, nome de sistema ou estrutura de cliente entra neste repositório, nem em exemplos, testes, notebooks ou mensagens de commit.
2. **Sem segredos no Git.** Tokens, senhas e chaves ficam em `.env` (ignorado pelo Git). O `.env.example` traz só nomes de variáveis e valores fictícios.
3. **Não afirme sem verificar.** Detalhes de APIs, formatos de arquivo e limites do Databricks Free Edition devem ser confirmados na fonte oficial. O que não foi confirmado fica marcado como `TODO(verificar)` no código ou na documentação.
4. **Licença MIT.** Não adicione código ou dados com licença incompatível.

## Contexto do portfólio

- Tema único: qualidade da água, vazão e clima em Minas Gerais, com IBGE como dimensão de município e população.
- Fontes: IGAM (qualidade da água), ANA HidroWebService (vazão, nível, chuva), INMET (clima), IBGE API de Agregados v3 (municípios e população), CONAMA 357/430 e DN COPAM/CERH (limites legais).
- Cruzamento das fontes: por estação ou ponto (coordenadas), município (código IBGE) e tempo.
- Plataforma: Databricks Free Edition (serverless, Unity Catalog, Jobs, Apps). Airflow, Kafka e servidor MCP rodam em Docker local.
- Ferramentas: **PySpark no Databricks**, com o **VS Code ligado ao workspace** (extensão Databricks para VS Code + Databricks Connect; Databricks Asset Bundles para jobs). O código é escrito e versionado localmente e executado no compute serverless do workspace.

## Arquitetura medalhão (Unity Catalog)

| Schema | Conteúdo |
| --- | --- |
| `raw` | Volumes com os arquivos de origem, sem alteração |
| `bronze` | Uma tabela por fonte, mais metadados de carga (origem, data, hash) |
| `silver` | Dados limpos e padronizados, com chave estação para município |
| `gold` | `fato_qualidade_agua`, `fato_vazao`, `fato_clima`, `dim_estacao`, `dim_municipio`, `dim_parametro`, violações dos limites |
| `ops` (opcional) | Histórico de execuções de jobs |
| `dq` (opcional) | Resultados do `hidrodq` |

Regras: cada camada só lê da anterior; bronze é imutável e reprocessável; transformações são idempotentes; nomes de catálogo e schema vêm de variáveis de ambiente, nunca ficam fixos no código.

## Desenvolvimento com PySpark no Databricks

- Código Spark vive em `src/`; um único módulo cria a sessão (`DatabricksSession` localmente via Databricks Connect, `SparkSession` quando roda dentro do Databricks).
- Autenticação por OAuth (`make db-auth`), sem token em arquivo. O `.env` guarda host e ID de compute (`auto` = serverless).
- Free Edition só tem compute serverless. Segundo a documentação oficial, o Databricks Connect para serverless exige Python 3.12 local nas versões 16.4 a 18.x (15.4 usa 3.11).
- Testes unitários não dependem do workspace nem de rede; testes de integração com Spark ficam marcados e rodam só localmente.
- `TODO(verificar)`: o Free Edition permite Databricks Connect, CLI/API e Asset Bundles? A página oficial de limitações não menciona. Testar na Fase 0 e registrar em ADR.
- `TODO(verificar)`: versão serverless usada hoje pelo Free Edition (define a versão do `databricks-connect` no extra `databricks`).

## Estrutura do repositório

```
README.md            problema, diagrama, como rodar em um comando, resultados
CLAUDE.md            este arquivo
docs/                documentação; docs/adr/ guarda decisões de arquitetura
src/                 código-fonte do pacote Python
pipelines/           jobs e pipelines (Databricks Jobs, Airflow, etc.)
notebooks/           exploração; nada de lógica que só exista aqui
tests/               testes com pytest
infra/               Docker Compose, configurações de ambiente
.github/workflows/   CI
Makefile             atalhos de desenvolvimento
pyproject.toml       dependências e configuração de ferramentas
.env.example         variáveis de ambiente de exemplo
```

## Comandos

Use sempre o Makefile:

| Comando | O que faz |
| --- | --- |
| `make setup` | Cria o ambiente virtual e instala dependências (incluindo as de desenvolvimento) |
| `make setup-databricks` | Instala também o Databricks Connect |
| `make db-auth` | Login OAuth no workspace (Databricks CLI) |
| `make lint` | Roda `ruff check` e `ruff format --check` |
| `make format` | Aplica `ruff format` e `ruff check --fix` |
| `make test` | Roda `pytest` |
| `make check` | `lint` + `test` (o mesmo que a CI executa) |
| `make up` / `make down` | Sobe e derruba os serviços Docker locais (Airflow, Kafka, MCP), quando o repositório os usa |
| `make clean` | Remove caches e artefatos de build |

Antes de concluir qualquer tarefa, rode `make check`.

## Convenções de código

- Python 3.12 ou superior, com type hints em funções públicas.
- Formatação e lint com `ruff`; não desative regras sem justificar em comentário.
- Testes com `pytest`; todo código novo em `src/` vem com teste. Testes não acessam rede nem dependem de credenciais: use amostras pequenas e públicas em `tests/data/`.
- Funções pequenas, nomes em inglês no código, comentários e documentação em português.
- Sem lógica de negócio em notebooks; notebooks importam de `src/`.
- Configuração por variáveis de ambiente (ver `.env.example`), lidas em um único módulo.

## Git e CI

- Commits convencionais: `feat:`, `fix:`, `docs:`, `test:`, `refactor:`, `chore:`, `ci:`. Mensagem curta no imperativo; um assunto por commit.
- Trabalhe em branch e abra pull request; a `main` fica sempre verde.
- A CI roda `ruff` e `pytest`. Falha de CI bloqueia o merge.
- Nunca faça commit de `.env`, dados brutos grandes, tokens ou arquivos de cliente.

## Decisões (ADR)

Toda decisão relevante vira um registro em `docs/adr/NNNN-titulo-curto.md` (contexto, decisão, consequências). Quando uma decisão for tomada, registre-a em três lugares: o ADR, o plano do portfólio e a seção "Decisões deste repositório" abaixo.

## Decisões deste repositório

Preencha ao criar o repositório a partir do modelo.

- **Repositório:** `<nome>`
- **Projetos cobertos:** `<ex.: Projeto 1 e 2>`
- **Janela do cronograma:** `<início a fim>`
- **Bacia e período de dados:** `<a definir na Fase 0>`
- **Catálogo e schemas do Unity Catalog:** `<ex.: workspace.bronze ... ou hidro_mg.bronze ...>` (pendente: confirmar se o Free Edition permite criar catálogo novo)
- **Fontes usadas aqui:** `<IGAM / ANA / INMET / IBGE / normas>`
- **Serviços Docker:** `<nenhum / Airflow / Kafka / MCP>`
- **Pendências de verificação:** `<lista de TODO(verificar)>`
- **Registros de decisão:** `<links para docs/adr/...>`

| Data | Decisão | ADR |
| --- | --- | --- |
|  |  |  |
