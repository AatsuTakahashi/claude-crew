#!/bin/bash
# knowledge.sh — ナレッジDB CLI（構造化検索）
#
# Usage:
#   bash scripts/knowledge.sh add <content> <category> [--domain D] [--project P] [--agent A] [--tags T] [--source S]
#   bash scripts/knowledge.sh search [--category C] [--domain D] [--project P] [--agent A] [--keyword K] [--limit N]
#   bash scripts/knowledge.sh list [--category C] [--domain D] [--project P]
#   bash scripts/knowledge.sh migrate

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CREW_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DB_PATH="$CREW_DIR/knowledge.db"

ensure_db() {
    if [[ ! -f "$DB_PATH" ]]; then
        bash "$CREW_DIR/db/init.sh"
    fi
    # Apply migrations if needed
    if ! sqlite3 "$DB_PATH" "PRAGMA table_info(memories);" | grep -q "domain"; then
        sqlite3 "$DB_PATH" < "$CREW_DIR/db/migrate_002_structured_fields.sql" 2>/dev/null || true
        echo "Applied migration: added structured fields" >&2
    fi
}

# Parse --key value pairs from args, starting at given position
parse_opts() {
    OPTS_category="" OPTS_domain="" OPTS_project="" OPTS_agent="" OPTS_tags="" OPTS_source="agent" OPTS_keyword="" OPTS_limit="10"
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --category) OPTS_category="$2"; shift 2 ;;
            --domain)   OPTS_domain="$2";   shift 2 ;;
            --project)  OPTS_project="$2";  shift 2 ;;
            --agent)    OPTS_agent="$2";    shift 2 ;;
            --tags)     OPTS_tags="$2";     shift 2 ;;
            --source)   OPTS_source="$2";   shift 2 ;;
            --keyword)  OPTS_keyword="$2";  shift 2 ;;
            --limit)    OPTS_limit="$2";    shift 2 ;;
            *) shift ;;
        esac
    done
}

escape_sql() {
    echo "$1" | sed "s/'/''/g"
}

cmd_add() {
    local content="${1:?Usage: knowledge.sh add <content> <category> [options]}"
    local category="${2:?Usage: knowledge.sh add <content> <category> [options]}"
    shift 2
    parse_opts "$@"

    ensure_db

    local now
    now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local escaped_content
    escaped_content=$(escape_sql "$content")

    local domain_val="NULL" project_val="NULL" agent_val="NULL"
    [[ -n "$OPTS_domain" ]]  && domain_val="'$(escape_sql "$OPTS_domain")'"
    [[ -n "$OPTS_project" ]] && project_val="'$(escape_sql "$OPTS_project")'"
    [[ -n "$OPTS_agent" ]]   && agent_val="'$(escape_sql "$OPTS_agent")'"

    local id
    id=$(sqlite3 "$DB_PATH" "INSERT INTO memories (content, category, domain, project, agent, tags, source, created_at, updated_at) VALUES ('$escaped_content', '$category', $domain_val, $project_val, $agent_val, '$(escape_sql "$OPTS_tags")', '$(escape_sql "$OPTS_source")', '$now', '$now'); SELECT last_insert_rowid();")

    echo "Added memory #$id (category=$category, domain=${OPTS_domain:-none}, project=${OPTS_project:-none})" >&2
    echo "$id"
}

cmd_search() {
    ensure_db
    parse_opts "$@"

    local where="is_active = 1"
    [[ -n "$OPTS_category" ]] && where="$where AND category = '$(escape_sql "$OPTS_category")'"
    [[ -n "$OPTS_domain" ]]   && where="$where AND domain = '$(escape_sql "$OPTS_domain")'"
    [[ -n "$OPTS_project" ]]  && where="$where AND project = '$(escape_sql "$OPTS_project")'"
    [[ -n "$OPTS_agent" ]]    && where="$where AND agent = '$(escape_sql "$OPTS_agent")'"
    [[ -n "$OPTS_keyword" ]]  && where="$where AND (content LIKE '%$(escape_sql "$OPTS_keyword")%' OR tags LIKE '%$(escape_sql "$OPTS_keyword")%')"

    sqlite3 -json "$DB_PATH" \
        "SELECT id, content, category, domain, project, agent, tags FROM memories WHERE $where ORDER BY updated_at DESC LIMIT $OPTS_limit;"
}

cmd_list() {
    ensure_db
    parse_opts "$@"

    local where="is_active = 1"
    [[ -n "$OPTS_category" ]] && where="$where AND category = '$(escape_sql "$OPTS_category")'"
    [[ -n "$OPTS_domain" ]]   && where="$where AND domain = '$(escape_sql "$OPTS_domain")'"
    [[ -n "$OPTS_project" ]]  && where="$where AND project = '$(escape_sql "$OPTS_project")'"

    sqlite3 -json "$DB_PATH" \
        "SELECT id, content, category, domain, project, agent, tags FROM memories WHERE $where ORDER BY updated_at DESC;"
}

cmd_migrate() {
    ensure_db
    echo "Database is up to date."
}

case "${1:-help}" in
    add)      shift; cmd_add "$@" ;;
    search)   shift; cmd_search "$@" ;;
    list)     shift; cmd_list "$@" ;;
    migrate)  shift; cmd_migrate "$@" ;;
    *)
        cat <<'USAGE'
knowledge.sh — ナレッジDB CLI（構造化検索）

Commands:
  add <content> <category> [options]   記憶を追加
  search [options]                     構造化フィルタで検索
  list [options]                       一覧表示
  migrate                              DBマイグレーション適用

Options (add):
  --domain <domain>      技術ドメイン (auth, db, api, frontend, infra, test)
  --project <project>    プロジェクト名 (greencare, jarvis, ajisai)
  --agent <agent>        対象エージェント (task-executor, code-reviewer, etc.)
  --tags <tags>          自由タグ (カンマ区切り)
  --source <source>      記録元 (default: agent)

Options (search):
  --category <category>  カテゴリで絞る (lesson, dev, judgment, pattern, skill)
  --domain <domain>      ドメインで絞る
  --project <project>    プロジェクトで絞る
  --agent <agent>        エージェントで絞る
  --keyword <keyword>    内容・タグのキーワード検索
  --limit <N>            取得件数 (default: 10)

Categories: daily, dev, judgment, learning, lesson, skill, pattern
Domains:    auth, db, api, frontend, infra, test
USAGE
        ;;
esac
