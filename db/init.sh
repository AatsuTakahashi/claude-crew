#!/bin/bash
# ナレッジDBを初期化するスクリプト
# 既存のDBがある場合はスキップする

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DB_PATH="${SCRIPT_DIR}/../knowledge.db"
SCHEMA_PATH="${SCRIPT_DIR}/schema.sql"

if [ -f "$DB_PATH" ]; then
    echo "knowledge.db already exists. Skipping initialization."
    exit 0
fi

sqlite3 "$DB_PATH" < "$SCHEMA_PATH"
echo "knowledge.db created successfully."
