#!/bin/bash
# 📋 Claude Crew — Guild Board Logger
# ギルド掲示板（ステータスログ）に冒険者の活動を記録
#
# Usage:
#   bash scripts/crew_log.sh start <agent_name> "<quest_description>"
#   bash scripts/crew_log.sh done  <agent_name> "<result_summary>"
#   bash scripts/crew_log.sh error <agent_name> "<error_description>"
#   bash scripts/crew_log.sh info  "<message>"
#
# Output: logs/crew.log
# Monitor: ./summon.sh --watch  or  tail -f logs/crew.log

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_DIR="$SCRIPT_DIR/../logs"
LOG_FILE="$LOG_DIR/crew.log"

mkdir -p "$LOG_DIR"

TIMESTAMP="$(date '+%H:%M:%S')"
DATE="$(date '+%Y-%m-%d')"

ACTION="${1:?Usage: $0 <start|done|error|info> [agent] [message]}"

# 冒険者ごとのアイコンと称号
get_agent_title() {
  case "$1" in
    architect)  echo "🏗️  軍師 Architect" ;;
    coder)      echo "⚔️  剣士 Coder" ;;
    reviewer)   echo "🛡️  守護者 Reviewer" ;;
    researcher) echo "🔮 斥候 Researcher" ;;
    *)          echo "🤖 冒険者 $1" ;;
  esac
}

case "$ACTION" in
  start)
    AGENT="${2:?Agent name required}"
    MESSAGE="${3:-}"
    TITLE="$(get_agent_title "$AGENT")"
    echo "[$DATE $TIMESTAMP] ▶ $TITLE 出撃 — $MESSAGE" >> "$LOG_FILE"
    ;;
  done)
    AGENT="${2:?Agent name required}"
    MESSAGE="${3:-}"
    TITLE="$(get_agent_title "$AGENT")"
    echo "[$DATE $TIMESTAMP] ✅ $TITLE 帰還 — $MESSAGE" >> "$LOG_FILE"
    ;;
  error)
    AGENT="${2:?Agent name required}"
    MESSAGE="${3:-}"
    TITLE="$(get_agent_title "$AGENT")"
    echo "[$DATE $TIMESTAMP] ❌ $TITLE 撤退 — $MESSAGE" >> "$LOG_FILE"
    ;;
  info)
    MESSAGE="${2:-}"
    echo "[$DATE $TIMESTAMP] 📋 $MESSAGE" >> "$LOG_FILE"
    ;;
  *)
    echo "Unknown action: $ACTION" >&2
    echo "Usage: $0 <start|done|error|info> [agent] [message]" >&2
    exit 1
    ;;
esac
