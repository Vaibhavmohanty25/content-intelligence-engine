create table if not exists public.content_ideas (
  id uuid primary key default gen_random_uuid(),
  signal_id uuid references public.content_signals(id) on delete set null,
  topic text not null,
  angle text,
  target_audience text,
  relevance_score numeric not null default 0,
  engagement_score numeric not null default 0,
  freshness_score numeric not null default 0,
  novelty_score numeric not null default 0,
  opportunity_score numeric not null default 0,
  status text not null default 'new',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint content_ideas_status_check
    check (status in ('new', 'scored', 'selected', 'generating', 'generated', 'rejected', 'failed')),
  constraint content_ideas_relevance_score_check check (relevance_score between 0 and 100),
  constraint content_ideas_engagement_score_check check (engagement_score between 0 and 100),
  constraint content_ideas_freshness_score_check check (freshness_score between 0 and 100),
  constraint content_ideas_novelty_score_check check (novelty_score between 0 and 100),
  constraint content_ideas_opportunity_score_check check (opportunity_score between 0 and 100)
);

comment on table public.content_ideas is
  'Content opportunities generated from normalized content signals.';
comment on column public.content_ideas.status is
  'Idea lifecycle state: new, scored, selected, generating, generated, rejected, or failed.';
comment on column public.content_ideas.opportunity_score is
  'Overall 0-100 score; the scoring formula is intentionally deferred to Phase 5.';
comment on column public.content_ideas.updated_at is
  'Set explicitly by the application or workflow layer; no automatic updated_at trigger exists in Phase 1.';
