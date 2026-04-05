#!/bin/bash
# memory.sh — エージェントメモリの管理
#
# Usage:
#   bash scripts/memory.sh list <agent>           # メモリ一覧
#   bash scripts/memory.sh show <agent> <file>    # メモリ表示
#   bash scripts/memory.sh stats                  # 全エージェント統計
#   bash scripts/memory.sh export <output-dir>    # メモリエクスポート

set -euo pipefail

CREW_DIR="$(cd "$(dirname "$0")/.." && pwd)"
MEMORY_DIR="$CREW_DIR/memory"

case "${1:-help}" in
  list)
    agent="${2:?Usage: $0 list <agent>}"
    dir="$MEMORY_DIR/$agent"
    if [[ ! -d "$dir" ]]; then
      echo "Agent '$agent' not found. Available: $(ls "$MEMORY_DIR" | tr '\n' ' ')" >&2
      exit 1
    fi
    echo "=== $agent memories ==="
    if ls "$dir"/*.md 1>/dev/null 2>&1; then
      for f in "$dir"/*.md; do
        name=$(head -5 "$f" | grep "^name:" | sed 's/name: //')
        echo "  $(basename "$f") — $name"
      done
    else
      echo "  (empty)"
    fi
    ;;

  show)
    agent="${2:?Usage: $0 show <agent> <file>}"
    file="${3:?Usage: $0 show <agent> <file>}"
    cat "$MEMORY_DIR/$agent/$file"
    ;;

  stats)
    echo "=== Claude Crew Memory Stats ==="
    for agent_dir in "$MEMORY_DIR"/*/; do
      agent=$(basename "$agent_dir")
      count=$(find "$agent_dir" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
      size=$(du -sh "$agent_dir" 2>/dev/null | cut -f1)
      echo "  $agent: ${count} memories (${size})"
    done
    ;;

  export)
    output="${2:?Usage: $0 export <output-dir>}"
    mkdir -p "$output"
    cp -r "$MEMORY_DIR" "$output/crew-memory-$(date +%Y%m%d)"
    echo "Exported to $output/crew-memory-$(date +%Y%m%d)"
    ;;

  *)
    echo "Usage: $0 {list|show|stats|export} [args...]"
    ;;
esac
