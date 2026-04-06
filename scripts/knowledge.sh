#!/bin/bash
# knowledge.sh — ナレッジDB CLI（ベクトル検索対応）
#
# Usage:
#   bash scripts/knowledge.sh add <content> <category> [tags] [source]
#   bash scripts/knowledge.sh search <query> [--limit N] [--category CAT]
#   bash scripts/knowledge.sh list [category]
#   bash scripts/knowledge.sh reindex
#   bash scripts/knowledge.sh migrate

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CREW_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DB_PATH="$CREW_DIR/knowledge.db"
VECTOR_SEARCH="$SCRIPT_DIR/vector_search.py"

ensure_db() {
    if [[ ! -f "$DB_PATH" ]]; then
        bash "$CREW_DIR/db/init.sh"
    fi
    # Apply migration if embedding column doesn't exist
    if ! sqlite3 "$DB_PATH" "PRAGMA table_info(memories);" | grep -q "embedding"; then
        sqlite3 "$DB_PATH" < "$CREW_DIR/db/migrate_001_embedding.sql" 2>/dev/null || true
        echo "Applied migration: added embedding column" >&2
    fi
}

cmd_add() {
    local content="${1:?Usage: knowledge.sh add <content> <category> [tags] [source]}"
    local category="${2:?Usage: knowledge.sh add <content> <category> [tags] [source]}"
    local tags="${3:-}"
    local source="${4:-agent}"
    local now
    now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    ensure_db

    # Insert the memory
    local id
    id=$(sqlite3 "$DB_PATH" "INSERT INTO memories (content, category, tags, source, created_at, updated_at) VALUES ('$(echo "$content" | sed "s/'/''/g")', '$category', '$tags', '$source', '$now', '$now'); SELECT last_insert_rowid();")

    echo "Added memory #$id ($category)" >&2

    # Auto-embed if OPENAI_API_KEY is available
    if [[ -n "${OPENAI_API_KEY:-}" ]] || [[ -f "$CREW_DIR/.env" ]]; then
        python3 "$VECTOR_SEARCH" embed "$id" 2>&1 >&2 || echo "Warning: embedding failed (API key missing or invalid)" >&2
    else
        echo "Tip: Set OPENAI_API_KEY to auto-embed on add" >&2
    fi

    echo "$id"
}

cmd_search() {
    ensure_db

    # Check if any embeddings exist
    local embedded_count
    embedded_count=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM memories WHERE is_active = 1 AND embedding IS NOT NULL;")

    if [[ "$embedded_count" -gt 0 ]]; then
        # Vector search (semantic)
        python3 "$VECTOR_SEARCH" search "$@"
    else
        # Fallback to LIKE search
        local query="${1:?Usage: knowledge.sh search <query>}"
        echo "[fallback: LIKE search — run 'knowledge.sh reindex' for vector search]" >&2
        sqlite3 -json "$DB_PATH" \
            "SELECT id, content, category, tags FROM memories WHERE is_active = 1 AND content LIKE '%${query}%' ORDER BY updated_at DESC LIMIT 10;"
    fi
}

cmd_list() {
    ensure_db
    local category="${1:-}"
    if [[ -n "$category" ]]; then
        sqlite3 -json "$DB_PATH" \
            "SELECT id, content, category, tags, embedding IS NOT NULL as has_embedding FROM memories WHERE is_active = 1 AND category = '$category' ORDER BY updated_at DESC;"
    else
        sqlite3 -json "$DB_PATH" \
            "SELECT id, content, category, tags, embedding IS NOT NULL as has_embedding FROM memories WHERE is_active = 1 ORDER BY updated_at DESC;"
    fi
}

cmd_reindex() {
    ensure_db
    python3 "$VECTOR_SEARCH" reindex
}

cmd_migrate() {
    ensure_db
    echo "Database is up to date."
}

case "${1:-help}" in
    add)      shift; cmd_add "$@" ;;
    search)   shift; cmd_search "$@" ;;
    list)     shift; cmd_list "$@" ;;
    reindex)  shift; cmd_reindex "$@" ;;
    migrate)  shift; cmd_migrate "$@" ;;
    *)
        cat <<'USAGE'
knowledge.sh — ナレッジDB CLI（ベクトル検索対応）

Commands:
  add <content> <category> [tags] [source]  記憶を追加（自動embedding）
  search <query> [--limit N] [--category C] 意味検索（ベクトル類似度）
  list [category]                           一覧表示
  reindex                                   全記憶のembeddingを再生成
  migrate                                   DBマイグレーション適用

Categories: daily, dev, judgment, learning, lesson, skill, pattern

Requires: OPENAI_API_KEY (env or .env file)
USAGE
        ;;
esac
