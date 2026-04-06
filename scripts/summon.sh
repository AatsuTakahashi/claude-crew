#!/usr/bin/env bash
# 🏰 Claude Crew — Guild Summon Script
# 冒険者ギルドの扉を開き、精鋭たちを召喚する起動スクリプト
#
# Usage:
#   ./summon.sh                    # ギルド本部でCrew起動
#   ./summon.sh /path/to/project   # 指定のダンジョン（プロジェクト）に出撃
#   ./summon.sh --setup /path      # ダンジョンにギルド拠点を設営
#   ./summon.sh --status           # ギルド掲示板を確認
#   ./summon.sh --watch            # ギルド掲示板をリアルタイム監視
#   ./summon.sh -h                 # ヘルプ

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CREW_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# ═══════════════════════════════════════════════════════════════════════════════
# ギルドの装飾
# ═══════════════════════════════════════════════════════════════════════════════

RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
MAGENTA='\033[1;35m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

# スリープ付きecho（演出用）
slow_echo() {
  echo -e "$1"
  sleep 0.15
}

# ═══════════════════════════════════════════════════════════════════════════════
# ギルドのアスキーアート
# ═══════════════════════════════════════════════════════════════════════════════

show_guild_gate() {
  echo ""
  echo -e "${YELLOW}        ╔═══════════════════════════════════════╗${RESET}"
  echo -e "${YELLOW}        ║${RESET}    ${DIM}___${RESET}                ${DIM}___${RESET}              ${YELLOW}║${RESET}"
  echo -e "${YELLOW}        ║${RESET}   ${DIM}|   |${RESET}  ${BOLD}${WHITE}CLAUDE  CREW${RESET}  ${DIM}|   |${RESET}             ${YELLOW}║${RESET}"
  echo -e "${YELLOW}        ║${RESET}   ${DIM}| 🏰|${RESET}              ${DIM}| 🏰|${RESET}             ${YELLOW}║${RESET}"
  echo -e "${YELLOW}        ║${RESET}   ${DIM}|   |${RESET}  ${CYAN}冒険者ギルド${RESET}  ${DIM}|   |${RESET}             ${YELLOW}║${RESET}"
  echo -e "${YELLOW}        ║${RESET}   ${DIM}|   |${RESET}              ${DIM}|   |${RESET}             ${YELLOW}║${RESET}"
  echo -e "${YELLOW}        ║${RESET}${DIM}═══╧═══╧══════════════════╧═══╧═══${RESET}       ${YELLOW}║${RESET}"
  echo -e "${YELLOW}        ╚═══════════════════════════════════════╝${RESET}"
  echo ""
}

# ═══════════════════════════════════════════════════════════════════════════════
# ギルドマスターの挨拶と冒険者の掛け合い
# ═══════════════════════════════════════════════════════════════════════════════

# ギルドマスターの挨拶（ランダム）
GREETINGS=(
  "ようこそ、冒険者ギルド『Claude Crew』へ。今日はどんな依頼をこなす？"
  "おお、ギルドマスター殿。精鋭たちは既に待機している。指示を。"
  "ギルドの扉が開かれた。10人の冒険者、出撃準備完了。"
  "今日の依頼書は厚いな...だが心配無用。我がギルドの精鋭に不可能はない。"
  "バグドラゴンの討伐依頼が入っているぞ。腕の見せ所だ。"
  "新たな冒険の幕開けだ。さあ、依頼を受け付けよう。"
  "ギルドランク: S級。今日も最高品質のコードを納品しよう。"
  "冒険者たちよ、剣を研ぎ、盾を磨け。出陣の時だ。"
)

# 冒険者の掛け合い（ランダムで1セット表示）
show_banter() {
  local BANTER_SET=$((RANDOM % 6))
  echo -e "  ${DIM}── 冒険者たちの声が聞こえる... ──${RESET}"
  echo ""
  case $BANTER_SET in
    0)
      slow_echo "  ${CYAN}⚔️  Coder:${RESET}    ${DIM}「今日こそあのバグを仕留める...！」${RESET}"
      slow_echo "  ${CYAN}🛡️  Reviewer:${RESET}  ${DIM}「落ち着け剣士。まずは私のレビューを通してからだ」${RESET}"
      slow_echo "  ${CYAN}⚔️  Coder:${RESET}    ${DIM}「...はい」${RESET}"
      ;;
    1)
      slow_echo "  ${CYAN}🏗️  Architect:${RESET} ${DIM}「この設計、完璧だと思わないか？」${RESET}"
      slow_echo "  ${CYAN}🔮 Researcher:${RESET} ${DIM}「軍師殿、似た構成のOSSが3つ炎上してます」${RESET}"
      slow_echo "  ${CYAN}🏗️  Architect:${RESET} ${DIM}「...設計を見直そう」${RESET}"
      ;;
    2)
      slow_echo "  ${CYAN}🛡️  Reviewer:${RESET}  ${DIM}「このコード...誰が書いた？」${RESET}"
      slow_echo "  ${CYAN}⚔️  Coder:${RESET}    ${DIM}「...俺だが？」${RESET}"
      slow_echo "  ${CYAN}🛡️  Reviewer:${RESET}  ${DIM}「テスト、ないよね？」${RESET}"
      slow_echo "  ${CYAN}⚔️  Coder:${RESET}    ${DIM}「...書きます」${RESET}"
      ;;
    3)
      slow_echo "  ${CYAN}🔮 Researcher:${RESET} ${DIM}「調査完了。最適な手法が判明した」${RESET}"
      slow_echo "  ${CYAN}🏗️  Architect:${RESET} ${DIM}「さすが斥候。して、その手法とは？」${RESET}"
      slow_echo "  ${CYAN}🔮 Researcher:${RESET} ${DIM}「Stack Overflowの2位の回答です」${RESET}"
      slow_echo "  ${CYAN}🏗️  Architect:${RESET} ${DIM}「...1位じゃなくて？」${RESET}"
      slow_echo "  ${CYAN}🔮 Researcher:${RESET} ${DIM}「1位は10年前の回答で deprecated です」${RESET}"
      ;;
    4)
      slow_echo "  ${CYAN}⚔️  Coder:${RESET}    ${DIM}「よし、一発で動いた！」${RESET}"
      slow_echo "  ${CYAN}🛡️  Reviewer:${RESET}  ${DIM}「一発で動くコードほど怪しいものはない」${RESET}"
      slow_echo "  ${CYAN}⚔️  Coder:${RESET}    ${DIM}「疑り深すぎないか...？」${RESET}"
      slow_echo "  ${CYAN}🛡️  Reviewer:${RESET}  ${DIM}「それが仕事だ」${RESET}"
      ;;
    5)
      slow_echo "  ${CYAN}🏗️  Architect:${RESET} ${DIM}「マイクロサービスで行こう」${RESET}"
      slow_echo "  ${CYAN}⚔️  Coder:${RESET}    ${DIM}「TODOアプリにマイクロサービス...？」${RESET}"
      slow_echo "  ${CYAN}🔮 Researcher:${RESET} ${DIM}「軍師殿、費用対効果のデータ出しましょうか」${RESET}"
      slow_echo "  ${CYAN}🏗️  Architect:${RESET} ${DIM}「...モノリスで行こう」${RESET}"
      ;;
  esac
  echo ""
}

random_greeting() {
  local idx=$((RANDOM % ${#GREETINGS[@]}))
  echo "${GREETINGS[$idx]}"
}

show_banner() {
  show_guild_gate
  echo -e "  ${YELLOW}「$(random_greeting)」${RESET}"
  echo ""
}

show_guild_members() {
  echo -e "  ${YELLOW}⚜️  【 ギルドメンバー 】${RESET}"
  echo ""
  slow_echo "    🏗️  ${BOLD}Why-Architect${RESET}   ${DIM}— 軍師。依頼のWhyを深掘りする門番。${RESET}"
  slow_echo "    🔮 ${BOLD}What-Finder${RESET}     ${DIM}— 斥候。ターゲットと影響範囲を特定する。${RESET}"
  slow_echo "    ⚗️  ${BOLD}Solver${RESET}          ${DIM}— 錬金術師。複数の解を導き出す知恵者。${RESET}"
  slow_echo "    📜 ${BOLD}Work-Planner${RESET}    ${DIM}— 書記官。作戦を実行可能な計画に落とす。${RESET}"
  slow_echo "    ⚔️  ${BOLD}Task-Executor${RESET}   ${DIM}— 剣士。コードで道を切り拓く主力。${RESET}"
  slow_echo "    🛡️  ${BOLD}Code-Reviewer${RESET}   ${DIM}— 守護者。品質の盾でバグを通さぬ番人。${RESET}"
  slow_echo "    🔧 ${BOLD}Quality-Fixer${RESET}   ${DIM}— 鍛冶師。折れた剣を打ち直す職人。${RESET}"
  slow_echo "    📮 ${BOLD}PR-Creator${RESET}      ${DIM}— 伝令兵。成果を世に届ける使者。${RESET}"
  slow_echo "    📖 ${BOLD}Notion-Writer${RESET}   ${DIM}— 記録官。冒険の記録をNotionに刻む。${RESET}"
  slow_echo "    🧠 ${BOLD}Pattern-Learner${RESET} ${DIM}— 賢者。経験からパターンを学ぶ知者。${RESET}"
  echo ""
}

# ログ関数（ギルド風）
log_quest() {
  echo -e "  ${RED}【依頼】${RESET} $1"
}

log_info() {
  echo -e "  ${YELLOW}【報告】${RESET} $1"
}

log_success() {
  echo -e "  ${GREEN}【達成】${RESET} $1"
}

log_guild() {
  echo -e "  ${CYAN}【ギルド】${RESET} $1"
}

# ═══════════════════════════════════════════════════════════════════════════════
# オプション解析
# ═══════════════════════════════════════════════════════════════════════════════

show_help() {
  show_guild_gate
  echo -e "  ${BOLD}Usage:${RESET}"
  echo ""
  echo -e "    ${GREEN}./summon.sh${RESET}                    ギルド本部で起動"
  echo -e "    ${GREEN}./summon.sh /path/to/project${RESET}   ダンジョン（プロジェクト）に出撃"
  echo -e "    ${GREEN}./summon.sh --setup /path${RESET}      ダンジョンにギルド拠点を設営"
  echo -e "    ${GREEN}./summon.sh --status${RESET}           ギルド掲示板（直近の戦況）"
  echo -e "    ${GREEN}./summon.sh --watch${RESET}            掲示板をリアルタイム監視"
  echo -e "    ${GREEN}./summon.sh -h${RESET}                 このヘルプ"
  echo ""
  echo -e "  ${DIM}ギルドマスター（Orchestrator）が依頼を受け付け、${RESET}"
  echo -e "  ${DIM}最適な冒険者に自動で振り分けます。${RESET}"
  echo -e "  ${DIM}@agent_name で特定の冒険者を直接指名することも可能。${RESET}"
  echo ""
}

ACTION="launch"
TARGET_DIR=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --setup)
      ACTION="setup"
      TARGET_DIR="${2:?--setup requires a project path}"
      shift 2
      ;;
    --status)
      ACTION="status"
      shift
      ;;
    --watch)
      ACTION="watch"
      shift
      ;;
    -h|--help)
      show_help
      exit 0
      ;;
    *)
      TARGET_DIR="$1"
      shift
      ;;
  esac
done

# ═══════════════════════════════════════════════════════════════════════════════
# アクション実行
# ═══════════════════════════════════════════════════════════════════════════════

case "$ACTION" in
  setup)
    show_banner
    log_guild "ダンジョンにギルド拠点を設営中..."
    echo ""
    bash "$CREW_DIR/scripts/setup.sh" "$TARGET_DIR"
    echo ""
    log_success "拠点設営完了。冒険者たちはいつでも出撃できる。"
    echo ""
    echo -e "  次回出撃: ${BOLD}./summon.sh $TARGET_DIR${RESET}"
    echo ""
    ;;

  status)
    LOG_FILE="$CREW_DIR/logs/crew.log"
    if [[ -f "$LOG_FILE" ]]; then
      echo ""
      echo -e "  ${YELLOW}📋 【 ギルド掲示板 — 直近の戦況 】${RESET}"
      echo ""
      tail -20 "$LOG_FILE"
      echo ""
    else
      echo ""
      echo -e "  ${DIM}掲示板にはまだ何も貼られていない。${RESET}"
      echo -e "  ${DIM}冒険者を召喚して、最初の依頼をこなせ。${RESET}"
      echo ""
    fi
    ;;

  watch)
    LOG_FILE="$CREW_DIR/logs/crew.log"
    mkdir -p "$CREW_DIR/logs"
    touch "$LOG_FILE"
    echo ""
    echo -e "  ${YELLOW}📋 【 ギルド掲示板 — リアルタイム監視中 】${RESET}"
    echo -e "  ${DIM}Ctrl+C で監視を終了${RESET}"
    echo ""
    tail -f "$LOG_FILE"
    ;;

  launch)
    show_banner
    show_guild_members
    show_banter

    # ダンジョン（プロジェクト）を決定
    if [[ -n "$TARGET_DIR" ]]; then
      if [[ ! -d "$TARGET_DIR" ]]; then
        log_quest "ダンジョン '$TARGET_DIR' が見つからない！斥候の報告を待て。"
        exit 1
      fi
      # ギルド拠点の確認
      if [[ ! -d "$TARGET_DIR/.claude" ]] || [[ ! -L "$TARGET_DIR/.claude/agents" ]]; then
        log_info "このダンジョンにはまだ拠点がない。設営する..."
        bash "$CREW_DIR/scripts/setup.sh" "$TARGET_DIR"
        echo ""
      fi
      log_quest "ダンジョン: ${BOLD}$TARGET_DIR${RESET}"
      LAUNCH_DIR="$TARGET_DIR"
    else
      log_quest "ギルド本部: ${BOLD}$CREW_DIR${RESET}"
      LAUNCH_DIR="$CREW_DIR"
    fi

    # knowledge.db初期化（未作成の場合）
    if [[ ! -f "$LAUNCH_DIR/knowledge.db" ]] && [[ -f "$CREW_DIR/db/init.sh" ]]; then
      log_info "knowledge.db を初期化中..."
      bash "$CREW_DIR/db/init.sh"
    fi

    # 出撃ログ記録
    bash "$CREW_DIR/scripts/crew_log.sh" info "🏰 Guild opened — 冒険者ギルド開門"

    echo ""
    log_success "全冒険者、出撃準備完了。ギルドマスターを起動する..."
    echo ""
    echo -e "  ${MAGENTA}╔══════════════════════════════════════════╗${RESET}"
    echo -e "  ${MAGENTA}║${RESET}  ${BOLD}📋 別ターミナルでギルド掲示板を監視:${RESET}  ${MAGENTA}║${RESET}"
    echo -e "  ${MAGENTA}║${RESET}  ${CYAN}./summon.sh --watch${RESET}                    ${MAGENTA}║${RESET}"
    echo -e "  ${MAGENTA}╚══════════════════════════════════════════╝${RESET}"
    echo ""

    # Claude Code（ギルドマスター）起動
    cd "$LAUNCH_DIR"
    exec claude
    ;;
esac
