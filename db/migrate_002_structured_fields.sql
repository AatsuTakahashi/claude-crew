-- Migration 002: Add structured fields for metadata-based search
-- Replace embedding-based vector search with structured filtering

ALTER TABLE memories ADD COLUMN domain TEXT DEFAULT NULL;
ALTER TABLE memories ADD COLUMN project TEXT DEFAULT NULL;
ALTER TABLE memories ADD COLUMN agent TEXT DEFAULT NULL;

CREATE INDEX IF NOT EXISTS idx_memories_domain ON memories(domain);
CREATE INDEX IF NOT EXISTS idx_memories_project ON memories(project);
CREATE INDEX IF NOT EXISTS idx_memories_agent ON memories(agent);
