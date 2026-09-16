create table if not exists public.content_drafts (
  id uuid primary key default gen_random_uuid(),
  idea_id uuid not null references public.content_ideas(id) on delete cascade,
  platform text not null default 'linkedin',
  headline text,
  body text not null,
  cta text,
  model_provider text,
  model_name text,
  prompt_version text,
  status text not null default 'draft',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint content_drafts_status_check
    check (status in ('draft', 'pending_approval', 'approved', 'rejected', 'regenerate', 'published', 'failed'))
);

comment on table public.content_drafts is
  'Generated content stored before human approval.';
comment on column public.content_drafts.model_provider is
  'Reserved for future generation provenance; no model integration is implemented in Phase 1.';
comment on column public.content_drafts.status is
  'Draft lifecycle state: draft, pending_approval, approved, rejected, regenerate, published, or failed.';
comment on column public.content_drafts.updated_at is
  'Set explicitly by the application or workflow layer; no automatic updated_at trigger exists in Phase 1.';
