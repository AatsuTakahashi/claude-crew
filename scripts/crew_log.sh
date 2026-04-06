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
    why-architect)   echo "🏗️  軍師 Why-Architect" ;;
    what-finder)     echo "🔮 斥候 What-Finder" ;;
    solver)          echo "⚗️  錬金術師 Solver" ;;
    work-planner)    echo "📜 書記官 Work-Planner" ;;
    task-executor)   echo "⚔️  剣士 Task-Executor" ;;
    code-reviewer)   echo "🛡️  守護者 Code-Reviewer" ;;
    quality-fixer)   echo "🔧 鍛冶師 Quality-Fixer" ;;
    pr-creator)      echo "📮 伝令兵 PR-Creator" ;;
    notion-writer)   echo "📖 記録官 Notion-Writer" ;;
    pattern-learner) echo "🧠 賢者 Pattern-Learner" ;;
    *)               echo "🤖 冒険者 $1" ;;
  esac
}

# 出撃時のユーモアフレーバー（冒険者ごと）
get_start_flavor() {
  case "$1" in
    why-architect)
      local FLAVORS=(
        "「なぜ？」軍師の問いが始まった。本質を見極めるまで進ませない"
        "軍師がWhyの門を構えた。曖昧な依頼は通さない"
        "「目的なき行動は、闇雲に剣を振るうのと同じだ」"
        "「急いては事を仕損じる」軍師は冷静に分析を始めた"
      )
      ;;
    what-finder)
      local FLAVORS=(
        "水晶玉に手をかざし、ターゲットを探り始めた..."
        "「答えは必ずある」斥候が調査を開始した"
        "斥候の魔法の目が、影響範囲を映し出す"
        "古文書（ドキュメント）を紐解き、真実を掘り起こす"
      )
      ;;
    solver)
      local FLAVORS=(
        "錬金術師がフラスコを振る。複数の解が泡立ち始めた"
        "「一つの解に飛びつくな。比較せよ」錬金術師の教え"
        "トレードオフの天秤が静かに揺れる..."
        "「最善の選択は、選択肢を知ることから始まる」"
      )
      ;;
    work-planner)
      local FLAVORS=(
        "書記官が羊皮紙を広げ、作戦計画を書き始めた"
        "「1タスク1コミット。それが戦いの掟だ」"
        "依存関係の糸を丁寧に解きほぐしている..."
        "計画なき実装は、地図なき航海と同じ"
      )
      ;;
    task-executor)
      local FLAVORS=(
        "剣を抜き、コードの荒野に斬り込む！"
        "「コードは剣より強し！」剣士が叫んだ"
        "キーボードが鳴り響く。剣士の猛攻が始まった"
        "剣士はエディタを開いた。今日の獲物はデカいぞ"
      )
      ;;
    code-reviewer)
      local FLAVORS=(
        "盾を構え、バグの侵入を阻止する構え"
        "「一匹たりとも通さん」守護者の目が鋭く光る"
        "守護者がコードを一行ずつ検問している"
        "品質の番人、今日も門番として立ちはだかる"
      )
      ;;
    quality-fixer)
      local FLAVORS=(
        "鍛冶師が炉に火を入れた。折れた剣を打ち直す"
        "「壊れたものは直せばいい」鍛冶師の槌が鳴る"
        "テスト失敗の残骸を集め、修復作業が始まった"
        "鍛冶師の腕にかかれば、どんなバグも叩き直せる"
      )
      ;;
    pr-creator)
      local FLAVORS=(
        "伝令兵が馬に跨った。成果を届ける使命だ"
        "「この勝利を、世に知らしめよ！」"
        "PRという名の手紙を丁寧に書き上げている"
        "伝令兵の足は速い。PRはすぐに届くだろう"
      )
      ;;
    notion-writer)
      local FLAVORS=(
        "記録官が羽ペンを取った。冒険の記録を残す"
        "「記録なき冒険は、なかったことと同じだ」"
        "Why/What/Howの三章構成で記録が始まる"
        "Notionの書庫に、新たな一ページが加わる"
      )
      ;;
    pattern-learner)
      local FLAVORS=(
        "賢者が瞑想に入った。経験からパターンを抽出する..."
        "「同じ過ちを繰り返さぬよう、学ばねばならぬ」"
        "knowledge.dbに新たな知恵が刻まれようとしている"
        "賢者の目が過去を見通し、未来の道を照らす"
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
    why-architect)
      local FLAVORS=(
        "Whyが確定した。もう迷わない"
        "軍師は満足げに頷いた。「本質を見極めた」"
        "「これでブレない。前に進め」"
        "Whyの門が開かれた。後続の冒険者たちに道が示された"
      )
      ;;
    what-finder)
      local FLAVORS=(
        "斥候が貴重な情報を持ち帰った"
        "「報告します。ターゲットと影響範囲が見えました」"
        "水晶玉が静かに光を失う。調査完了"
        "未知が既知に変わった。斥候の功績は大きい"
      )
      ;;
    solver)
      local FLAVORS=(
        "錬金術師のフラスコから、複数の解が結晶化した"
        "「選択肢は揃った。あとは決断あるのみ」"
        "トレードオフの天秤が静止した。答えが見えた"
        "錬金術師は静かに微笑んだ。最善の道が見えたようだ"
      )
      ;;
    work-planner)
      local FLAVORS=(
        "完璧な作戦図が完成した"
        "「この計画なら負けはない」書記官が羊皮紙を閉じた"
        "タスクは整理され、依存関係は明確になった"
        "計画は練り上がった。あとは実行あるのみ"
      )
      ;;
    task-executor)
      local FLAVORS=(
        "剣士は剣を鞘に収めた。見事な太刀筋だった"
        "戦場に静寂が戻る。コードは美しく仕上がった"
        "「やれやれ、今日もいい汗をかいた」"
        "剣士のコミットが戦場に刻まれた"
      )
      ;;
    code-reviewer)
      local FLAVORS=(
        "守護者の検問が完了。門は安全だ"
        "「よし、通ってよい」守護者が頷いた"
        "品質の盾に傷はない。完璧な防衛だった"
        "守護者の厳しい目をくぐり抜けたコードだけが生き残る"
      )
      ;;
    quality-fixer)
      local FLAVORS=(
        "鍛冶師の槌が止まった。修復完了だ"
        "「新品同様に仕上がったぞ」鍛冶師が額の汗を拭う"
        "全テストが緑に光る。鍛冶師の腕は確かだ"
        "品質問題はすべて叩き直された"
      )
      ;;
    pr-creator)
      local FLAVORS=(
        "伝令兵の任務完了。PRは無事に届いた"
        "「PR作成完了。あとはレビューを待つのみ」"
        "伝令の馬が戻ってきた。使命は果たされた"
        "PRという名の手紙が、無事に宛先に届いた"
      )
      ;;
    notion-writer)
      local FLAVORS=(
        "記録官がペンを置いた。冒険の記録は完璧だ"
        "「記録完了。後世に語り継がれるだろう」"
        "Notionの書庫に、新たな一章が加わった"
        "Why/What/How、三章すべてが記録された"
      )
      ;;
    pattern-learner)
      local FLAVORS=(
        "賢者が目を開けた。新たなパターンを学んだ"
        "「この経験は、次の冒険で活きるだろう」"
        "knowledge.dbに新たな知恵が刻まれた"
        "ギルドの知恵がまた一つ増えた"
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
    why-architect)    echo "「...Whyが確定できない。もっと情報が必要だ」" ;;
    what-finder)      echo "水晶玉が曇った。情報が足りない..." ;;
    solver)           echo "錬金術師のフラスコが割れた。解が見つからない..." ;;
    work-planner)     echo "「計画に穴がある...練り直しだ」" ;;
    task-executor)    echo "剣が折れた...だが、まだ立てる！" ;;
    code-reviewer)    echo "守護者の盾に亀裂が！品質基準を満たせていない" ;;
    quality-fixer)    echo "鍛冶師「この傷は深い...時間がかかる」" ;;
    pr-creator)       echo "伝令兵の馬が道に迷った...PR作成に失敗" ;;
    notion-writer)    echo "記録官のペンが折れた。Notion接続に問題が..." ;;
    pattern-learner)  echo "賢者「...まだパターンが見えない」" ;;
    *)                echo "冒険者が負傷した。撤退！" ;;
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
