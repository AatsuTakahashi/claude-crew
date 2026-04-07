# Claude Crew

**冒険者ギルド型マルチエージェントフレームワーク for Claude Code CLI**

---

## Claude Crewとは

Claude Crewは、Claude Code CLIの上に構築されたマルチエージェントフレームワークです。

ひとつのAIに何でもやらせるのではなく、専門性の異なる複数のエージェント（冒険者）が役割分担して働きます。依頼を受けたギルドマスターが内容を判断し、適切な冒険者に仕事を委譲する。これがClaude Crewの基本的な動き方です。

### なぜマルチエージェントか

単一のAIに「認証機能を追加して」と依頼すると、目的の確認もせず、代替案も出さず、コードを書き始めることがあります。

Claude Crewでは、まずwhY-architectが「なぜその機能が必要か」を深掘りし、what-finderが影響範囲を特定し、solverが複数の解決策を比較したうえで、task-executorが実装に取りかかります。各エージェントは自分の専門領域だけに集中するため、それぞれの判断の質が上がります。

### 「冒険者ギルド」の思想

**適材適所** — The right person for the right job.

ギルドマスター（オーケストレーター）は自分では作業しません。依頼の性質を見極め、最適な冒険者に委譲します。適任の冒険者がいなければ、ユーザーに確認してからagent-crafterが新しい冒険者を設計します。ギルドは依頼に応じて拡張していきます。

---

## Requirements

- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code)
- SQLite3（macOS / Linux 標準搭載）

外部APIキー不要。Claude Codeのプランのみで動作します。

---

## 冒険者一覧

| 冒険者 | 称号 | 責務 |
|--------|------|------|
| **why-architect** | 軍師 | 依頼の「なぜ」を深掘りし、本質的な目的とEARS要件を確定させる |
| **what-finder** | 斥候 | ターゲット（顧客・対象）と影響範囲を特定する |
| **solver** | 錬金術師 | 複数の解決策を導出し、5軸でトレードオフを分析する |
| **work-planner** | 書記官 | 解決策を実行可能なタスクに分解し、作業計画を構造化する |
| **task-executor** | 剣士 | ブランチ作成・TDDによる実装・Purpose validation |
| **code-reviewer** | 守護者 | テスト・静的解析・CodeRabbit AIの観点で品質を検証する |
| **quality-fixer** | 鍛冶師 | テスト失敗・静的解析違反・CodeRabbit指摘を修正する |
| **pr-creator** | 伝令兵 | PRを作成する |
| **notion-writer** | 記録官 | NotionにWhy/What/How形式でタスクページを作成・更新する |
| **pattern-learner** | 賢者 | 作業完了時に連携フローと技術知見をknowledge.dbに記録する |
| **agent-crafter** | 創造師 | 既存の冒険者で対応できない依頼に対し、新しい冒険者を設計・作成する |

各冒険者の詳細な定義は `agents/` ディレクトリに格納されています。

---

## ワークフロー例

### 新機能の追加

```
User: "認証機能を追加して"

Guild Master:
  1. why-architect  → Whyの深掘り・EARS要件定義
  2. what-finder    → ターゲット・影響範囲の特定
  3. solver         → 解決策の導出・トレードオフ分析
  4. work-planner   → 作業計画の構造化
  5. task-executor  → TDDによる実装
  6. code-reviewer  → 品質検証
  7. quality-fixer  → 問題があれば修正（必要な場合）
  8. pr-creator     → PR作成
  9. notion-writer  → Notionに記録
  10. pattern-learner → フロー記録
```

### バグ修正

```
User: "ログイン画面でエラーが出る"

Guild Master:
  1. why-architect  → 問題の本質を確認
  2. what-finder    → 原因調査・影響範囲の特定
  3. solver         → 修正アプローチの検討
  4. task-executor  → 修正実装
  5. code-reviewer  → レビュー
  6. pr-creator     → PR作成
```

### 技術調査

```
User: "Next.js 15の変更点を調べて"

Guild Master:
  1. what-finder    → 情報収集・影響範囲の特定
  2. User           → 調査結果報告
```

### 特定の冒険者を直接指名する

`@agent_name` で始まるメッセージで、ギルドマスターを介さずに直接依頼できます。

```
@why-architect この依頼のWhyを深掘りして
@solver 解決策を出して
@task-executor この作業を実行して
@code-reviewer PRをレビューして
```

---

## 使い方

### セットアップ

```bash
# リポジトリをクローン
git clone https://github.com/your-username/claude-crew.git
cd claude-crew

# ナレッジDBを初期化
bash db/init.sh
```

### 起動

```bash
# ギルド本部（このリポジトリ）で起動
./summon

# 特定のプロジェクトに出撃
./summon /path/to/your-project

# ギルド掲示板（ステータスログ）をリアルタイム監視
./summon --watch

# 直近の戦況を確認
./summon --status
```

### 他のプロジェクトで使う

Claude Crewは任意のプロジェクトで使用できます。セットアップスクリプトが必要なファイルを配置します。

```bash
# プロジェクトにギルド拠点を設営
./summon --setup /path/to/your-project

# そのプロジェクトで起動
./summon /path/to/your-project
```

---

## ナレッジ管理

Claude Crewは作業を通じて得られた知見をSQLiteデータベースに蓄積します。過去の教訓・判断の前例・連携パターンが検索可能な形で積み重なり、次の依頼に活かされます。

```bash
# ドメインで絞り込んで検索
bash scripts/knowledge.sh search --domain auth --limit 10

# カテゴリ × プロジェクトで絞り込む
bash scripts/knowledge.sh search --project myapp --category lesson

# キーワード検索
bash scripts/knowledge.sh search --keyword "JWT"

# 新しい知見を追加
bash scripts/knowledge.sh add "内容" "lesson" --domain auth --project myapp --tags "JWT"
```

| カテゴリ | 内容 |
|----------|------|
| lesson | 過去の失敗と教訓 |
| dev | 技術知見・実装パターン |
| judgment | 判断の前例 |
| pattern | 冒険者の連携パターン（pattern-learnerが記録） |
| skill | スキル・ノウハウ |
| daily | 日常業務のルール・手順 |

---

## ディレクトリ構造

```
claude-crew/
├── CLAUDE.md              # ギルドマスターの定義（役割・冒険者一覧・ワークフロー）
├── agents/                # 各冒険者の定義（.md ファイル）
├── .claude/
│   ├── rules/             # ギルドの原則（Why-first・事実ベースなど）
│   └── skills/            # 共有スキル（EARS要件・CodeRabbitなど）
├── scripts/
│   ├── summon.sh          # 起動スクリプト
│   ├── crew_log.sh        # ギルド掲示板へのログ記録
│   └── knowledge.sh       # ナレッジDB操作CLI
├── config/
│   └── crew.yaml          # ギルド設定
├── db/
│   ├── schema.sql         # DBスキーマ
│   └── init.sh            # DB初期化スクリプト
├── logs/
│   └── crew.log           # ギルド掲示板（ステータスログ）
└── knowledge.db           # ナレッジデータベース
```
