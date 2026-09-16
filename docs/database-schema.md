# Database Schema

## Purpose

Phase 1 establishes the local Supabase/PostgreSQL schema for the MVP content intelligence pipeline. The schema is intended for server-to-server use through future workflows and service credentials; Row Level Security (RLS) is not enabled yet. RLS should be evaluated if a client-facing frontend is introduced later.

## Tables and relationships

```text
content_signals
      |
      | 1
      | many
      v
content_ideas
      |
      | 1
      | many
      v
content_drafts

workflow_errors (independent)
```

- `content_signals` stores normalized external signals from RSS, Apify, and future sources. Source-specific values belong in `metadata` (`jsonb`) so the core schema remains stable as external APIs vary.
- `content_ideas` stores content opportunities derived from signals. `signal_id` is optional and uses `on delete set null`, so an idea can be retained after its source signal is removed.
- `content_drafts` stores generated copy before human approval. Every draft belongs to an idea; deleting an idea cascades to its drafts.
- `workflow_errors` independently records failures from future n8n workflows and API integrations.

## Status fields

- `content_signals.processing_status`: `new`, `normalized`, `duplicate`, `scored`, `selected`, `ignored`, or `failed`.
- `content_ideas.status`: `new`, `scored`, `selected`, `generating`, `generated`, `rejected`, or `failed`.
- `content_drafts.status`: `draft`, `pending_approval`, `approved`, `rejected`, `regenerate`, `published`, or `failed`.
- `workflow_errors.resolved` identifies whether an error has been addressed; `resolved_at` can retain the resolution time.

These states are enforced with PostgreSQL `CHECK` constraints rather than enum types to keep the MVP easy to evolve.

## Scores

`content_signals` retains source-level `engagement_score` and `relevance_score`, defaulting to `0`. `content_ideas` has `relevance_score`, `engagement_score`, `freshness_score`, `novelty_score`, and `opportunity_score`; each is required and constrained from 0 to 100. The opportunity-scoring formula is intentionally deferred to Phase 5.

## pgvector preparation

The `vector` PostgreSQL extension is enabled in the `extensions` schema now so the database is ready for Phase 4 semantic similarity and deduplication. No vector column, vector index, embedding provider, or vector dimension is included in Phase 1.

**The embedding provider and embedding dimension have not yet been selected.**

`updated_at` values are intentionally not maintained by triggers in this phase. Future application or workflow code must set them explicitly when updating rows.
