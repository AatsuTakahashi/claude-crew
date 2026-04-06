---
name: ruby-quality-check
description: rspecテスト実行とRuboCop静的解析の手順。コードレビューや品質修正時に使用。
---

# Ruby品質チェック

## rspec実行

```bash
# 1. コンテナに入る
docker-compose exec {サービス名} bash

# 2. ファイル指定で実行
bundle exec rspec ./spec/path/to/target_spec.rb
```

### 確認ポイント

- テストが存在し、パスしているか
- テストカバレッジが十分か（主要なパスと異常系）
- テストが実装の意図（Why）を正しく表現しているか
- テストが壊れやすい書き方になっていないか

## RuboCop実行

```bash
# 違反チェック
docker-compose exec {サービス名} bundle exec rubocop --format json

# 自動修正
docker-compose exec {サービス名} bundle exec rubocop -a
```

### 確認ポイント

- 新たに発生した違反と既存の違反を区別する
- プロジェクトの`.rubocop.yml`設定を尊重する
- 自動修正可能なものは`--autocorrect`を活用する
- 自動修正できないものは手動で対応する
