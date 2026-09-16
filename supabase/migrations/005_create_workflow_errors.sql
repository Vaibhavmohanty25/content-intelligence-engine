create table if not exists public.workflow_errors (
  id uuid primary key default gen_random_uuid(),
  workflow_name text not null,
  node_name text,
  execution_id text,
  error_type text,
  error_message text not null,
  payload jsonb,
  retry_count integer not null default 0,
  resolved boolean not null default false,
  created_at timestamptz not null default now(),
  resolved_at timestamptz,
  constraint workflow_errors_retry_count_check check (retry_count >= 0)
);

comment on table public.workflow_errors is
  'Central error logging for future n8n workflows and API integrations.';
comment on column public.workflow_errors.payload is
  'Optional flexible context payload captured with the error.';
