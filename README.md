# AI Content Intelligence Engine

AI Content Intelligence Engine is an automation-first system for collecting external content signals, normalizing them into a shared structure, storing them in Supabase/PostgreSQL, and preparing them for opportunity selection, LLM-assisted drafting, and human approval. n8n is the orchestration layer; Supabase provides persistent system state.

The repository currently contains the database foundation and an RSS-to-Supabase ingestion workflow. Semantic deduplication, scoring, LLM generation, approval, and publishing are designed extensions and are identified as such below.

## System Workflow

1. **External signal ingestion** - RSS feeds and, later, Apify-powered scraping or other external sources provide content signals in source-specific formats.
2. **Workflow orchestration** - n8n triggers ingestion, calls external APIs, routes and validates data, performs duplicate checks, writes to the database, and provides the control point for retries, LLM calls, approval, and future publishing workflows.
3. **Data normalization** - Each source is mapped to a common contract: `source`, `source_type`, `title`, `content`, `source_url`, `published_at`, `engagement_score`, `relevance_score`, `metadata`, and `processing_status`.
4. **Duplicate protection** - The workflow checks `source_url` before inserting a signal. Existing URLs are skipped; new URLs are inserted into `content_signals`. A unique database index on non-null `source_url` provides final protection against duplicate records.
5. **Supabase content bank** - Normalized signals are retained alongside derived ideas, drafts, and operational error records.
6. **Semantic similarity** - pgvector is enabled for a future embedding-based comparison that can identify related content beyond an exact URL match.
7. **Opportunity scoring** - Unique signals can be evaluated using rule-based relevance, engagement, freshness, novelty, and content-gap factors before generation.
8. **Groq LLM generation** - Selected ideas can be prepared as context and sent to Groq to produce structured drafts.
9. **Human approval** - Generated drafts are designed to be approved, rejected, or regenerated in Telegram before entering any publishing workflow.

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

## Components

| Component | Responsibility | Repository status |
| --- | --- | --- |
| n8n | Workflow triggers, API calls, validation, routing, and database operations | RSS ingestion workflow implemented |
| Supabase / PostgreSQL | Persistent storage for signals, ideas, drafts, and error records | Schema migrations implemented |
| pgvector | Vector storage and similarity-query foundation | Extension enabled; semantic flow not implemented |
| RSS | External signal source | TechCrunch feed configured in the exported workflow |
| Apify | Web scraping and external data ingestion | Planned |
| Groq API | LLM inference for analysis, strategy, structured outputs, and generation | Planned |
| Telegram API | Draft approval actions | Planned |

## Duplicate Protection and Semantic Similarity

The implemented RSS workflow validates required fields and requires a `source_url` before it continues to the Supabase lookup. A matching URL is routed to the skip branch; an unseen URL is inserted into `content_signals`. The schema reinforces this workflow-level check with a unique partial index, preventing duplicate non-null URLs even if a workflow insert is retried.

Exact URL matching does not detect substantively similar stories published under different links. The intended semantic path is:

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

pgvector is enabled, but no embedding column, provider, model, or similarity workflow is implemented. The embedding provider is intentionally decoupled from Groq and can be selected independently.

## Opportunity Scoring

After duplicate checks, unique signals are intended to enter a rule-based scoring layer. It can evaluate relevance, engagement, freshness, novelty, and content gap to calculate an opportunity score and determine whether an idea should proceed to generation. No machine-learning scoring implementation is present.

## LLM Generation and Human Approval

Groq is the intended LLM inference layer for topic analysis, content strategy, structured output, and content generation. The target flow is:

```text
Selected Content Idea -> Context Preparation -> Groq LLM -> Structured Draft -> content_drafts
```

The architecture can later support prompt roles such as researcher, strategist, critic, and writer. A multi-agent workflow is not implemented.

Drafts are designed to pass through Telegram actions for **Approve**, **Reject**, or **Regenerate**. This keeps a human decision point between generation and any future publishing integration.

## Error Handling and Observability

`workflow_errors` is the centralized error-recording table for n8n workflows and API integrations. It stores workflow name, node name, execution ID, error type, error message, payload, retry count, and resolution status. n8n workflows can use it for centralized logging and troubleshooting.

The architecture is designed to support retries for HTTP 429 rate limits, authentication failures, malformed API responses, timeouts, and third-party service failures. Automated error logging and retry handling are not yet implemented.

## Current Implementation

- Supabase/PostgreSQL schema migrations for `content_signals`, `content_ideas`, `content_drafts`, and `workflow_errors`
- pgvector extension enabled in PostgreSQL
- Database constraints and indexes, including a unique partial index on `content_signals.source_url`
- Exported n8n RSS workflow at `n8n/workflows/01_rss_signal_ingestion.json`
- TechCrunch RSS feed configured as the working ingestion source
- RSS payload normalization to the shared signal fields
- Required-field validation and `source_url` presence validation
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
| `content_signals` | Normalized source data, source metadata, processing status, and relevance and engagement scores |
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
|-- README.md
|-- .env.example
|-- docs/
|   |-- architecture.md
|   |-- database-schema.md
|   |-- rss-ingestion.md
|   `-- workflow.md
|-- n8n/
|   `-- workflows/
|       `-- 01_rss_signal_ingestion.json
|-- prompts/
|   `-- content_generator.md
|-- sample-data/
|   |-- README.md
|   `-- rss-sample.json
`-- supabase/
    `-- migrations/
        |-- 001_enable_extensions.sql
        |-- 002_create_content_signals.sql
        |-- 003_create_content_ideas.sql
        |-- 004_create_content_drafts.sql
        |-- 005_create_workflow_errors.sql
        `-- 006_create_indexes.sql
```

## Environment Configuration

Copy `.env.example` to a local `.env` file and populate it locally; never commit the resulting file. The example contains variable names only:

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

Configure n8n credentials through n8n's secure credential store rather than hardcoding values in workflow JSON files or source control.

## Design Principles

- n8n handles orchestration rather than heavy business logic.
- Supabase is the persistent system state.
- Ingestion sources normalize into one common schema.
- Duplicate protection operates at both workflow and database levels.
- LLM and embedding providers are decoupled.
- Human approval sits between AI generation and publishing.
- Credentials remain outside source control.
- Workflow JSON files are version-controlled without secrets.
