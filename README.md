# AI Content Intelligence Engine

AI Content Intelligence Engine is an automation-first system for turning external content signals into reviewable content drafts. It uses n8n for workflow orchestration and Supabase/PostgreSQL for persistent state. Sources are normalized into a common schema, checked for duplicates, stored as signals, and can subsequently be evaluated, drafted with an LLM, and routed through human approval.

The repository currently implements the database foundation and a TechCrunch RSS ingestion workflow. Semantic similarity, scoring, LLM generation, approval, and publishing integrations are represented in the architecture and schema but are not implemented.

## System Flow

1. **External signal ingestion** — RSS feeds and, later, Apify-powered scraping or external data sources supply content signals with source-specific formats.
2. **Workflow orchestration** — n8n triggers workflows, calls external APIs, validates and routes data, performs duplicate checks, writes to the database, and is intended to coordinate retries, LLM calls, approval, and publishing.
3. **Data normalization** — each source is converted to a shared contract: `source`, `source_type`, `title`, `content`, `source_url`, `published_at`, `engagement_score`, `relevance_score`, `metadata`, and `processing_status`.
4. **Duplicate protection** — an item with an existing `source_url` is skipped; a new URL is inserted into `content_signals`. A partial unique index on `source_url` provides database-level protection in addition to the workflow lookup.
5. **Content bank** — normalized signals persist in Supabase and can provide the input for ideas, drafts, and operational error records.
6. **Semantic similarity** — pgvector is enabled for a future embedding-based similarity check that can detect related content beyond exact URL matches.
7. **Opportunity scoring** — a future rule-based scoring layer can evaluate unique signals before generation.
8. **LLM generation** — selected ideas can be supplied to Groq for structured analysis and content drafts.
9. **Human approval** — generated drafts are designed to be approved, rejected, or regenerated through Telegram before they reach publishing integrations.

```text
RSS Feeds                         Apify / External APIs
    |                                        |
    +--------------------+-------------------+
                         |
                        n8n ---------------------> workflow_errors
                         |                          failure logs / retry state
                         v
                Data Normalization
                         |
                         v
                  Duplicate Check
                         |
                         v
          Supabase / PostgreSQL Content Bank
                         |
                         v
            Semantic Similarity (pgvector)
                         |
                         v
               Rule-Based Opportunity Scoring
                         |
                         v
                      Groq LLM
                         |
                         v
                   Content Draft
                         |
                         v
                Telegram Approval
                /        |         \
           Approve     Reject    Regenerate
              |
              v
      Future Publishing Layer
```

## Components and Responsibilities

| Component | Responsibility | Current status |
| --- | --- | --- |
| n8n | Orchestration, API calls, validation, routing, database operations, and workflow control | RSS ingestion implemented |
| Supabase / PostgreSQL | Persistent storage for signals, ideas, drafts, and error records | Schema implemented |
| pgvector | Foundation for vector storage and similarity queries | Extension enabled; similarity flow not implemented |
| Groq API | LLM inference for analysis, strategy, structured outputs, and generation | Planned |
| RSS | External content-signal source | TechCrunch workflow implemented |
| Apify | Web scraping and external data ingestion | Planned |
| Telegram API | Human approval actions for drafts | Planned |

## Duplicate Protection and Semantic Similarity

The implemented RSS workflow checks `source_url` in Supabase before inserting a signal. The schema reinforces this with a unique partial index, so non-null URLs cannot be stored more than once. The workflow currently requires a source URL as part of validation; records that fail required-field validation do not proceed to insertion.

Exact URL matching does not identify related stories published under different URLs. The intended semantic path is:

```text
Content Signal
      |
Embedding Generation
      |
pgvector Similarity Search
      |
Similar Content Found?
      /               \
    Yes               No
     |                 |
   Skip            Continue
```

pgvector is enabled, but no embedding column, provider, model, or similarity workflow is implemented yet. The embedding provider is intentionally independent of Groq and can be selected separately.

## Opportunity Scoring

After duplicate checks, unique signals are intended to enter a rule-based scoring layer. The layer evaluates relevance, engagement, freshness, novelty, and content gap to calculate an opportunity score and decide whether an idea proceeds to generation. No machine-learning scoring implementation is currently present.

## LLM Generation and Approval

Groq is the intended LLM inference layer for topic analysis, content strategy, structured output, and content generation. The planned path is:

```text
Selected Content Idea -> Context Preparation -> Groq LLM -> Structured Draft -> content_drafts
```

The architecture can later use prompt roles such as researcher, strategist, critic, and writer. These roles are not yet implemented as a multi-agent workflow.

Drafts are designed to enter a Telegram approval workflow with **Approve**, **Reject**, and **Regenerate** actions. Approval remains a human decision point before any future publishing workflow.

## Error Handling and Observability

`workflow_errors` provides a centralized destination for n8n workflow and API failures. It records the workflow name, failed node, execution ID, error type, error message, payload, retry count, and resolution status. The table is implemented; automated error logging and retries are planned.

The design accommodates retry handling for HTTP 429 rate limits, authentication failures, malformed API responses, timeouts, and other third-party service failures.

## Current Implementation

- Supabase/PostgreSQL schema migrations for `content_signals`, `content_ideas`, `content_drafts`, and `workflow_errors`
- pgvector extension enabled in PostgreSQL
- Database constraints and indexes, including a unique partial index on `content_signals.source_url`
- Exported n8n RSS workflow at `n8n/workflows/01_rss_signal_ingestion.json`
- TechCrunch RSS configured as the working feed: `https://techcrunch.com/feed`
- RSS payload normalization for the shared signal fields
- Required-field and source-URL validation
- Supabase lookup by `source_url`, duplicate-skip routing, and insertion of unseen RSS signals into `content_signals`

## Planned Extensions

- Apify-based signal ingestion
- Embedding generation and pgvector semantic deduplication
- Rule-based opportunity scoring
- Groq content strategy and generation
- Telegram approval workflow
- Automated retry and error handling
- Multi-channel content generation
- Publishing integrations
- Analytics feedback loop

## Database Schema

| Table | Purpose |
| --- | --- |
| `content_signals` | Normalized source data, source metadata, processing status, and source-level relevance and engagement scores |
| `content_ideas` | Derived topic, angle, target audience, relevance, engagement, freshness, novelty, opportunity score, and workflow status |
| `content_drafts` | Idea reference, target platform, headline, body, CTA, model provider, model name, prompt version, and approval status |
| `workflow_errors` | Workflow execution errors, failed node, error type, payload, retry count, and resolution status |

```text
content_signals
      |
      v
content_ideas
      |
      v
content_drafts

workflow_errors (independent)
```

## Tech Stack

| Area | Technology |
| --- | --- |
| Automation / orchestration | n8n |
| Database | Supabase, PostgreSQL |
| Vector search | pgvector |
| LLM inference | Groq API |
| External data | RSS, Apify |
| Human approval | Telegram API |
| Version control | Git, GitHub |

## Repository Structure

```text
.
├── README.md
├── .env.example
├── docs/
│   ├── architecture.md
│   ├── database-schema.md
│   ├── rss-ingestion.md
│   └── workflow.md
├── n8n/
│   └── workflows/
│       └── 01_rss_signal_ingestion.json
├── prompts/
│   └── content_generator.md
├── sample-data/
│   ├── README.md
│   └── rss-sample.json
└── supabase/
    └── migrations/
        ├── 001_enable_extensions.sql
        ├── 002_create_content_signals.sql
        ├── 003_create_content_ideas.sql
        ├── 004_create_content_drafts.sql
        ├── 005_create_workflow_errors.sql
        └── 006_create_indexes.sql
```

## Environment Configuration

Copy `.env.example` to a local `.env` file and populate local values without committing the file. The example contains variable names only:

```dotenv
SUPABASE_URL=
SUPABASE_ANON_KEY=
SUPABASE_SERVICE_ROLE_KEY=
GROQ_API_KEY=
APIFY_API_TOKEN=
TELEGRAM_BOT_TOKEN=
TELEGRAM_CHAT_ID=
N8N_WEBHOOK_URL=
```

Configure n8n credentials through n8n's secure credential store. Do not hardcode keys or tokens in workflow JSON files or source control.

## Design Principles

- n8n handles orchestration rather than heavy business logic.
- Supabase is the persistent system state.
- Every ingestion source normalizes into one common schema.
- Duplicate protection operates at both the workflow and database levels.
- LLM and embedding providers are decoupled.
- Human approval sits between generation and publishing.
- Credentials remain outside source control.
- Workflow JSON files are version-controlled without secrets.
