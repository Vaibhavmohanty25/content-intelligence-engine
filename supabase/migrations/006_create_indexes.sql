create index if not exists content_signals_source_idx
  on public.content_signals (source);
create index if not exists content_signals_source_type_idx
  on public.content_signals (source_type);
create index if not exists content_signals_processing_status_idx
  on public.content_signals (processing_status);
create index if not exists content_signals_created_at_idx
  on public.content_signals (created_at);
create unique index if not exists content_signals_source_url_unique_idx
  on public.content_signals (source_url)
  where source_url is not null;

create index if not exists content_ideas_signal_id_idx
  on public.content_ideas (signal_id);
create index if not exists content_ideas_status_idx
  on public.content_ideas (status);
create index if not exists content_ideas_opportunity_score_idx
  on public.content_ideas (opportunity_score);
create index if not exists content_ideas_created_at_idx
  on public.content_ideas (created_at);

create index if not exists content_drafts_idea_id_idx
  on public.content_drafts (idea_id);
create index if not exists content_drafts_status_idx
  on public.content_drafts (status);
create index if not exists content_drafts_platform_idx
  on public.content_drafts (platform);
create index if not exists content_drafts_created_at_idx
  on public.content_drafts (created_at);

create index if not exists workflow_errors_workflow_name_idx
  on public.workflow_errors (workflow_name);
create index if not exists workflow_errors_resolved_idx
  on public.workflow_errors (resolved);
create index if not exists workflow_errors_created_at_idx
  on public.workflow_errors (created_at);
