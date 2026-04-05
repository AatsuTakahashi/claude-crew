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

# 出撃時のユーモアフレーバー（冒険者ごと）
get_start_flavor() {
  case "$1" in
    architect)
      local FLAVORS=(
        "設計図を広げ、作戦会議が始まる..."
        "「まずは地図を描こう」軍師がペンを取った"
        "軍師の目が光る。勝利の方程式を見つけたか？"
        "「急いては事を仕損じる」軍師は冷静に分析を始めた"
      )
      ;;
    coder)
      local FLAVORS=(
        "剣を抜き、コードの荒野に斬り込む！"
        "「コードは剣より強し！」剣士が叫んだ"
        "キーボードが鳴り響く。剣士の猛攻が始まった"
        "剣士はエディタを開いた。今日の獲物はデカいぞ"
      )
      ;;
    reviewer)
      local FLAVORS=(
        "盾を構え、バグの侵入を阻止する構え"
        "「一匹たりとも通さん」守護者の目が鋭く光る"
        "守護者がコードを一行ずつ検問している"
        "品質の番人、今日も門番として立ちはだかる"
      )
      ;;
    researcher)
      local FLAVORS=(
        "水晶玉に手をかざし、真実を探り始めた..."
        "「答えは必ずある」斥候が調査を開始した"
        "斥候の魔法の目が、未知の領域を映し出す"
        "古文書（ドキュメント）を紐解き、知識を掘り起こす"
      )
      ;;
    *)
      local FLAVORS=("冒険者が立ち上がった")
      ;;
  esac
  local idx=$((RANDOM % ${#FLAVORS[@]}))
  echo "${FLAVORS[$idx]}"
}

# 帰還時のユーモアフレーバー（冒険者ごと）
get_done_flavor() {
  case "$1" in
    architect)
      local FLAVORS=(
        "完璧な作戦図が完成した"
        "軍師は満足げに頷いた"
        "「この設計なら負けはない」"
        "作戦は練り上がった。あとは実行あるのみ"
      )
      ;;
    coder)
      local FLAVORS=(
        "剣士は剣を鞘に収めた。見事な太刀筋だった"
        "戦場に静寂が戻る。コードは美しく仕上がった"
        "「やれやれ、今日もいい汗をかいた」"
        "剣士のコミットが戦場に刻まれた"
      )
      ;;
    reviewer)
      local FLAVORS=(
        "守護者の検問が完了。門は安全だ"
        "「よし、通ってよい」守護者が頷いた"
        "品質の盾に傷はない。完璧な防衛だった"
        "守護者の厳しい目をくぐり抜けたコードだけが生き残る"
      )
      ;;
    researcher)
      local FLAVORS=(
        "斥候が貴重な情報を持ち帰った"
        "「報告します。真実が見えました」"
        "水晶玉が静かに光を失う。調査完了"
        "未知が既知に変わった。斥候の功績は大きい"
      )
      ;;
    *)
      local FLAVORS=("冒険者が帰還した")
      ;;
  esac
  local idx=$((RANDOM % ${#FLAVORS[@]}))
  echo "${FLAVORS[$idx]}"
}

# エラー時のフレーバー
get_error_flavor() {
  case "$1" in
    architect)  echo "「...想定外だ。作戦を練り直す」" ;;
    coder)      echo "剣が折れた...だが、まだ立てる！" ;;
    reviewer)   echo "守護者の盾に亀裂が！応急処置が必要だ" ;;
    researcher) echo "水晶玉が曇った。情報が足りない..." ;;
    *)          echo "冒険者が負傷した。撤退！" ;;
  esac
}

case "$ACTION" in
  start)
    AGENT="${2:?Agent name required}"
    MESSAGE="${3:-}"
    TITLE="$(get_agent_title "$AGENT")"
    FLAVOR="$(get_start_flavor "$AGENT")"
    echo "[$DATE $TIMESTAMP] ▶ $TITLE 出撃 — $MESSAGE" >> "$LOG_FILE"
    echo "[$DATE $TIMESTAMP]   💬 $FLAVOR" >> "$LOG_FILE"
    ;;
  done)
    AGENT="${2:?Agent name required}"
    MESSAGE="${3:-}"
    TITLE="$(get_agent_title "$AGENT")"
    FLAVOR="$(get_done_flavor "$AGENT")"
    echo "[$DATE $TIMESTAMP] ✅ $TITLE 帰還 — $MESSAGE" >> "$LOG_FILE"
    echo "[$DATE $TIMESTAMP]   💬 $FLAVOR" >> "$LOG_FILE"
    ;;
  error)
    AGENT="${2:?Agent name required}"
    MESSAGE="${3:-}"
    TITLE="$(get_agent_title "$AGENT")"
    FLAVOR="$(get_error_flavor "$AGENT")"
    echo "[$DATE $TIMESTAMP] ❌ $TITLE 撤退 — $MESSAGE" >> "$LOG_FILE"
    echo "[$DATE $TIMESTAMP]   💬 $FLAVOR" >> "$LOG_FILE"
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
