create table if not exists public.content_signals (
  id uuid primary key default gen_random_uuid(),
  source text not null,
  source_type text not null,
  title text not null,
  content text,
  source_url text,
  published_at timestamptz,
  engagement_score numeric default 0,
  relevance_score numeric default 0,
  metadata jsonb not null default '{}'::jsonb,
  processing_status text not null default 'new',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint content_signals_processing_status_check
    check (processing_status in ('new', 'normalized', 'duplicate', 'scored', 'selected', 'ignored', 'failed'))
);

comment on table public.content_signals is
  'Normalized external content signals collected from RSS, Apify, and future sources.';
comment on column public.content_signals.metadata is
  'Flexible source-specific external API metadata retained without changing the core schema.';
comment on column public.content_signals.processing_status is
  'Pipeline state: new, normalized, duplicate, scored, selected, ignored, or failed.';
comment on column public.content_signals.updated_at is
  'Set explicitly by the application or workflow layer; no automatic updated_at trigger exists in Phase 1.';
comment on table public.content_signals is
  'Normalized external content signals collected from RSS, Apify, and future sources. An embedding column will be added in Phase 4 after the embedding provider and dimension are selected.';
