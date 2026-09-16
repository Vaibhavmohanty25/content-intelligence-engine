-- Prepare pgvector for Phase 4 semantic similarity and deduplication.
-- Vector columns are intentionally deferred until an embedding provider and
-- embedding dimension have been selected.
create extension if not exists vector with schema extensions;

comment on extension vector is
  'Prepared in Phase 1 for Phase 4 semantic similarity and deduplication; vector storage is intentionally deferred until the embedding provider and dimension are selected.';
