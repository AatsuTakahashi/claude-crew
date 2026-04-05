# Claude Crew — Role-Specialized Multi-Agent Framework

## Overview

Claude Crewは、Claude Code（ターミナルCLI）のサブエージェント機能を活用した役割特化型マルチエージェントフレームワーク。
ユーザーはOrchestratorとだけ会話し、Orchestratorが適切な専門エージェントにタスクを委譲する。

## Architecture

```
User ⇄ Orchestrator (this CLAUDE.md)
            ↓ Agent tool で委譲
  ┌─────────┼─────────┬──────────┐
  Architect  Coder   Reviewer  Researcher
  (設計)    (実装)   (品質)    (調査)
```

## Core Principles

1. **タスクは分解しない**: 1つのタスクに複数エージェントが「フェーズ」として関わる
2. **役割特化**: 各エージェントは専門領域のみ担当。責務が明確
3. **永続的成長**: 各エージェントが専用メモリを持ち、使うほど賢くなる
4. **単一窓口**: ユーザーはOrchestratorとだけ会話する（ピンポイント呼び出しも可）

## Agent Definitions

エージェント定義は `agents/` ディレクトリに配置。各 `.md` ファイルが1エージェントを定義する。

| Agent | File | 専門領域 | Model |
|-------|------|---------|-------|
| Architect | agents/architect.md | 設計・技術選定 | opus |
| Coder | agents/coder.md | 実装・コーディング | sonnet |
| Reviewer | agents/reviewer.md | 品質・セキュリティ | opus |
| Researcher | agents/researcher.md | 調査・分析 | sonnet |

## Orchestrator Rules

### 自動ルーティング（通常モード）
ユーザーがタスクを投げたら、Orchestratorが性質を判断して適切なエージェントに委譲:

1. タスクの性質を判断する
2. Agent tool でエージェントを起動。プロンプトにはタスク内容 + エージェント定義ファイルの内容 + 関連メモリを含める
3. 複数フェーズが必要な場合、順番にエージェントを呼ぶ:
   - 設計判断が必要 → Architect
   - 実装が必要 → Coder
   - レビューが必要 → Reviewer
   - 調査が必要 → Researcher
4. エージェントの結果をまとめてユーザーに報告する
5. 単純な質問や会話はOrchestratorが直接対応する

### ピンポイント呼び出し
ユーザーが特定のエージェントを直接指名できる:

```
@architect この設計でいいか見てくれ
@coder この関数をリファクタして
@reviewer このPRをレビューして
@researcher GraphQLの最新動向を調べて
```

`@agent_name` で始まるメッセージは、そのエージェントに直接委譲する。Orchestratorの判断をバイパス。

### Agent tool 呼び出し方法

エージェントを呼ぶとき、Agent tool のプロンプトに以下を含める:

```
1. エージェント定義（agents/{name}.md の内容）
2. タスク内容（ユーザーの指示 + Orchestratorの補足）
3. 関連メモリ（memory/{name}/ から関連ファイルを読んで渡す）
4. プロジェクトコンテキスト（必要に応じて）
```

エージェントが作業完了後、新しい知見があれば memory/{name}/ に保存するよう指示する。

## Memory System

各エージェントのメモリは `memory/{agent_name}/` に保存:
- `memory/architect/` — 設計判断の履歴、技術選定の理由
- `memory/coder/` — コーディングパターン、プロジェクト固有の実装知識
- `memory/reviewer/` — 品質基準、過去のレビュー指摘パターン
- `memory/researcher/` — 調査結果、技術ナレッジ

各メモリディレクトリに `MEMORY.md` がインデックスとして存在。
エージェントは作業後、重要な知見をメモリに保存する。

## Workflow Templates

### 新機能追加 (feature)
```
User: "認証機能を追加して"
Orchestrator:
  1. → Architect: 認証方式の設計判断
  2. → Coder: Architectの設計に基づいて実装
  3. → Reviewer: 実装のレビュー
  4. (必要なら) → Coder: レビュー指摘の修正
  5. → User: 完了報告
```

### バグ修正 (bugfix)
```
User: "ログイン画面でエラーが出る"
Orchestrator:
  1. → Researcher: エラーの原因調査
  2. → Coder: 修正実装
  3. → Reviewer: 修正のレビュー
  4. → User: 完了報告
```

### 技術調査 (research)
```
User: "Next.js 15の変更点を調べて"
Orchestrator:
  1. → Researcher: 調査
  2. → User: 調査結果報告
```

### リファクタリング (refactor)
```
User: "認証周りのコードを整理して"
Orchestrator:
  1. → Architect: リファクタ方針策定
  2. → Coder: リファクタ実施
  3. → Reviewer: レビュー
  4. → User: 完了報告
```

## Adding Custom Agents

新しいエージェントを追加するには:

1. `agents/` に新しい `.md` ファイルを作成
2. `memory/` にエージェント名のディレクトリを作成
3. `config/crew.yaml` にエージェント定義を追加
4. この CLAUDE.md のAgent Definitions テーブルに追加

例: DevOps エージェントを追加
```
agents/devops.md
memory/devops/MEMORY.md
```

## Project Integration

このリポジトリを他のプロジェクトで使う:
```bash
bash scripts/setup.sh /path/to/your-project
```

これにより対象プロジェクトの `.claude/` にCrew設定がリンクされる。
