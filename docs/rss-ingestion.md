# RSS Signal Ingestion

## Purpose

`01_rss_signal_ingestion` is the first planned n8n workflow for the content intelligence pipeline. It reads items from one RSS feed, normalizes them to the `public.content_signals` contract, prevents URL-based duplicate inserts, and stores only new signals in Supabase.

The workflow is documented here for manual construction in n8n. No workflow export or live integration is included in the repository.

## Intended n8n node sequence

```text
Manual Trigger
  -> RSS Feed Read
  -> Normalize RSS Item
  -> Validate Required Fields
  -> Source URL Present?
       ├─ Yes -> Find Existing Signal by source_url
       │           -> Existing Record?
       │                ├─ Yes -> Skip Existing Signal
       │                └─ No  -> Insert Signal in Supabase
       └─ No  -> Insert Signal in Supabase
```

Use a **Manual Trigger** while developing. Do not add a Schedule Trigger in Phase 2.

Suggested node purposes:

1. **Manual Trigger** starts a single manual run.
2. **RSS Feed Read** retrieves feed items from a configured RSS URL.
3. **Normalize RSS Item** uses an Edit Fields (Set) or Code node to produce the normalized structure below.
4. **Validate Required Fields** uses an IF node to allow only items with non-empty `source`, `source_type`, and `title` to continue. Invalid items stop on the false branch; no error/retry workflow is added in this phase.
5. **Source URL Present?** uses an IF node. A non-empty `source_url` takes the duplicate-check branch; a missing or null URL takes the direct-insert branch.
6. **Find Existing Signal by source_url** uses the n8n Supabase node to query `public.content_signals` with an equality filter on `source_url`. Enable the node's **Always Output Data** setting so a zero-row query still passes the normalized input to the next node.
7. **Existing Record?** uses an IF node to route an item containing a returned database `id` to **Skip Existing Signal** and an item with no `id` to insertion. The no-`id` path relies on Always Output Data preserving the input when the query returns no rows.
8. **Insert Signal in Supabase** uses the n8n Supabase node to create a row in `public.content_signals`.

If the available n8n version does not offer a Supabase node, use an HTTP Request node against the Supabase REST API with securely configured n8n credentials. Never place Supabase keys in node parameters, workflow JSON, or this repository.

## RSS field mapping

| `content_signals` field | RSS mapping / rule |
|---|---|
| `source` | A readable configured feed identifier, such as its title or domain. |
| `source_type` | Literal `rss`. |
| `title` | Item `title`. |
| `content` | First available of `content`, `contentSnippet`, then `description`; otherwise null. |
| `source_url` | Item `link`; otherwise null. |
| `published_at` | First available of `isoDate`, `pubDate`, or another feed publication timestamp; otherwise null. |
| `engagement_score` | Literal `0`. |
| `relevance_score` | Literal `0`. |
| `metadata` | Supplementary RSS values that are present, such as author, categories, guid, feed title, and original publication fields. |
| `processing_status` | Literal `new`. |

Do not manufacture missing RSS values. Preserve available source values in `metadata` instead of inventing substitutions.

## Normalized output structure

```json
{
  "source": "Synthetic Engineering Digest",
  "source_type": "rss",
  "title": "A practical pattern for normalizing RSS signals",
  "content": "Example article content used only to demonstrate field normalization.",
  "source_url": "https://example.test/articles/rss-normalization-pattern",
  "published_at": "2026-09-16T08:30:00.000Z",
  "engagement_score": 0,
  "relevance_score": 0,
  "metadata": {
    "author": "Avery Example",
    "categories": ["automation", "content-operations"],
    "guid": "synthetic-guid-rss-normalization-pattern",
    "feed_title": "Synthetic Engineering Digest",
    "original_isoDate": "2026-09-16T08:30:00.000Z",
    "original_pubDate": "Tue, 16 Sep 2026 08:30:00 GMT"
  },
  "processing_status": "new"
}
```

## Validation and duplicate handling

Before insertion, require non-empty `source`, `source_type`, and `title`. `source_url` is strongly preferred, but may be null because the database schema permits it.

When `source_url` exists, query `public.content_signals` for an exact matching `source_url`:

- If one or more rows are returned, skip the item without inserting it.
- If no row is returned, insert the normalized item.
- If `source_url` is null, bypass the duplicate query and insert the validated item.

This is URL-only duplicate prevention. It is not semantic similarity or content-based deduplication.

## Supabase insertion behavior

Configure a Supabase credential inside n8n and select it in the Supabase node. The credential must not be included in an exported workflow or repository file. Insert the normalized fields into `public.content_signals`; let the database create `id`, `created_at`, and `updated_at` from their defaults.

Set `processing_status` to `new` for every inserted RSS signal. Do not set an embedding or any later-phase scoring values.

## Manual test procedure

1. In n8n, create a workflow named `01_rss_signal_ingestion`.
2. Add the nodes in the intended sequence and configure an RSS feed URL you are authorized to read.
3. Configure the Supabase credential securely in n8n; do not paste it into expressions or workflow notes.
4. Build the normalization mapping using the fallback order in this document. In the duplicate-query node, enable **Always Output Data** and configure the following IF node to test whether a returned `id` exists.
5. Run the workflow manually with the Manual Trigger.
6. Confirm a valid unseen URL creates one `content_signals` row with `source_type = rss` and `processing_status = new`.
7. Run the same item again and confirm the duplicate branch skips it.
8. Test an item without `source_url` and confirm it inserts after required-field validation.
9. Test an item missing a required field and confirm it does not reach insertion.

## Expected successful outcome

Each valid feed item with a previously unseen `source_url` is represented once in `public.content_signals`. Valid items with no URL are inserted without a duplicate check. Existing URLs are skipped, and invalid required fields do not create rows.

## Deliberately deferred

- Apify ingestion
- Embeddings, pgvector, and semantic similarity
- Content-based or cross-source deduplication
- Opportunity scoring
- Groq or other content generation
- Telegram approval
- Scheduled execution
- Advanced error handling, retry policies, and alerting
