-- Migration 001: Add embedding column for vector search
-- Safe to run multiple times (IF NOT EXISTS pattern via check)

ALTER TABLE memories ADD COLUMN embedding TEXT DEFAULT NULL;
