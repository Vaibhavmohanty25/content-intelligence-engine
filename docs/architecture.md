# Planned Architecture

This document describes the planned architecture only. No systems are implemented during Phase 0.

## RSS + Apify

RSS feeds and Apify will provide external signal ingestion.

## n8n

n8n will provide workflow orchestration, API integrations, routing, scheduling, retries, and automation.

## Supabase/PostgreSQL

Supabase and PostgreSQL will provide persistent storage for signals, content ideas, content drafts, workflow states, and errors.

## Semantic Similarity Layer

A future semantic similarity layer will support duplicate-content detection. Embeddings will be stored and searched using pgvector. The embedding provider has not yet been selected; Groq is not described as an embedding provider.

## Opportunity Scoring

Future rule-based opportunity scoring will evaluate whether a signal should proceed to content generation.

## Groq

Groq will provide future LLM inference for analysis, strategy, structured output, and content generation.

## Telegram

Telegram will provide future human-in-the-loop approval, rejection, and regeneration.
