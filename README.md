# Claude Crew

冒険者ギルド型マルチエージェントフレームワーク for Claude Code CLI.

## Quick Start

```bash
# ギルド本部で起動
./scripts/summon.sh

# 特定のプロジェクトに出撃
./scripts/summon.sh /path/to/your-project
```

## Requirements

- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code)
- SQLite3 (macOS/Linux標準搭載)

外部APIキー不要。Claude Codeのプランのみで動作します。

## Guild Members

| Agent | Role | Description |
|-------|------|-------------|
| why-architect | 軍師 | 依頼のWhyを深掘りし目的を確定 |
| what-finder | 斥候 | ターゲットと影響範囲を特定 |
| solver | 錬金術師 | 複数の解決策を導出・分析 |
| work-planner | 書記官 | 作業計画を構造化 |
| task-executor | 剣士 | タスク実行・実装 |
| code-reviewer | 守護者 | 品質検証 |
| quality-fixer | 鍛冶師 | 品質問題の修正 |
| pr-creator | 伝令兵 | PR作成 |
| notion-writer | 記録官 | Notion記録 |
| pattern-learner | 賢者 | パターン学習・蓄積 |
| agent-crafter | 創造師 | 新エージェントの設計・作成 |

## Workflow

```
User: "認証機能を追加して"

Guild Master:
  1. why-architect  → Whyの深掘り・EARS要件定義
  2. what-finder    → ターゲット・影響範囲特定・EARS補完
  3. solver         → 解決策の導出・トレードオフ分析
  4. work-planner   → 作業計画の構造化（EARS準拠）
  5. task-executor  → 実装（TDDフロー）
  6. code-reviewer  → 品質検証（EARS要件ベース）
  7. quality-fixer  → 品質問題の修正（必要な場合）
  8. pr-creator     → PR作成
  9. notion-writer  → Notionに記録
  10. pattern-learner → フロー記録
```

## Knowledge DB

構造化メタデータによるナレッジ管理。

```bash
# 追加
bash scripts/knowledge.sh add "内容" "category" --domain auth --project myapp --tags "JWT"

# 検索
bash scripts/knowledge.sh search --domain auth --category lesson

# 更新
bash scripts/knowledge.sh update 1 "更新内容"

# 削除（論理削除）
bash scripts/knowledge.sh delete 1
```

| Field | Description | Examples |
|-------|-------------|---------|
| category | ナレッジの種類 | lesson, dev, judgment, pattern, skill |
| domain | 技術ドメイン | auth, db, api, frontend, infra, test |
| project | プロジェクト | greencare, jarvis, ajisai |
| agent | 対象エージェント | task-executor, code-reviewer |
| tags | 自由タグ | JWT, RSpec, Supabase |

## Status Log

```bash
# 掲示板をリアルタイム監視（別ターミナル）
./scripts/summon.sh --watch

# 直近の戦況を確認
./scripts/summon.sh --status
```

## Other Projects

```bash
# プロジェクトにギルド拠点を設営
./scripts/summon.sh --setup /path/to/project

# そのプロジェクトで起動
./scripts/summon.sh /path/to/project
```

## Directory Structure

```
claude-crew/
├── CLAUDE.md              # Guild Master definition
├── agents/                # Agent definitions (.md)
├── .claude/
│   ├── rules/             # Guild principles
│   └── skills/            # Shared skills (EARS, etc.)
├── scripts/
│   ├── summon.sh          # Launch script
│   ├── crew_log.sh        # Status logger
│   └── knowledge.sh       # Knowledge DB CLI
├── config/
│   └── crew.yaml          # Guild configuration
└── db/
    ├── schema.sql         # DB schema
    └── init.sh            # DB initialization
```
