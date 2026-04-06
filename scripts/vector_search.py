#!/usr/bin/env python3
"""
vector_search.py — knowledge.db のベクトル検索エンジン
外部ライブラリ不要（Python標準ライブラリのみ）

Usage:
    python3 vector_search.py search <query> [--limit N] [--category CAT]
    python3 vector_search.py embed <id>
    python3 vector_search.py reindex
"""

import json
import math
import os
import sqlite3
import subprocess
import sys
import urllib.request

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
DB_PATH = os.path.join(SCRIPT_DIR, "..", "knowledge.db")
MODEL = "text-embedding-3-small"


def get_api_key():
    """OPENAI_API_KEY を環境変数または .env から取得"""
    key = os.environ.get("OPENAI_API_KEY")
    if key:
        return key
    env_path = os.path.join(SCRIPT_DIR, "..", ".env")
    if os.path.exists(env_path):
        with open(env_path) as f:
            for line in f:
                line = line.strip()
                if line.startswith("OPENAI_API_KEY="):
                    return line.split("=", 1)[1].strip().strip("'\"")
    print("Error: OPENAI_API_KEY not set. Export it or add to .env", file=sys.stderr)
    sys.exit(1)


def get_embedding(text, api_key):
    """OpenAI Embeddings API を curl なしの純 Python で呼び出す"""
    url = "https://api.openai.com/v1/embeddings"
    payload = json.dumps({"input": text, "model": MODEL}).encode("utf-8")
    req = urllib.request.Request(
        url,
        data=payload,
        headers={
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
        },
    )
    try:
        with urllib.request.urlopen(req) as resp:
            data = json.loads(resp.read().decode("utf-8"))
            return data["data"][0]["embedding"]
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8")
        print(f"Error: OpenAI API returned {e.code}: {body}", file=sys.stderr)
        sys.exit(1)


def cosine_similarity(a, b):
    """コサイン類似度（標準ライブラリのみ）"""
    dot = sum(x * y for x, y in zip(a, b))
    norm_a = math.sqrt(sum(x * x for x in a))
    norm_b = math.sqrt(sum(x * x for x in b))
    if norm_a == 0 or norm_b == 0:
        return 0.0
    return dot / (norm_a * norm_b)


def cmd_search(args):
    """意味検索: クエリに近い記憶を返す"""
    query = args[0] if args else ""
    if not query:
        print("Usage: vector_search.py search <query> [--limit N] [--category CAT]", file=sys.stderr)
        sys.exit(1)

    limit = 5
    category = None
    i = 1
    while i < len(args):
        if args[i] == "--limit" and i + 1 < len(args):
            limit = int(args[i + 1])
            i += 2
        elif args[i] == "--category" and i + 1 < len(args):
            category = args[i + 1]
            i += 2
        else:
            i += 1

    api_key = get_api_key()
    query_vec = get_embedding(query, api_key)

    conn = sqlite3.connect(DB_PATH)
    if category:
        rows = conn.execute(
            "SELECT id, content, category, tags, embedding FROM memories WHERE is_active = 1 AND category = ? AND embedding IS NOT NULL",
            (category,),
        ).fetchall()
    else:
        rows = conn.execute(
            "SELECT id, content, category, tags, embedding FROM memories WHERE is_active = 1 AND embedding IS NOT NULL"
        ).fetchall()
    conn.close()

    if not rows:
        print("No embedded memories found. Run 'reindex' first.", file=sys.stderr)
        sys.exit(0)

    results = []
    for row_id, content, cat, tags, emb_json in rows:
        emb = json.loads(emb_json)
        sim = cosine_similarity(query_vec, emb)
        results.append((sim, row_id, content, cat, tags))

    results.sort(key=lambda x: x[0], reverse=True)

    # JSON output for programmatic use
    output = []
    for sim, row_id, content, cat, tags in results[:limit]:
        output.append({
            "id": row_id,
            "similarity": round(sim, 4),
            "category": cat,
            "tags": tags,
            "content": content,
        })
    print(json.dumps(output, ensure_ascii=False, indent=2))


def cmd_embed(args):
    """指定IDの記憶にembeddingを付与する"""
    if not args:
        print("Usage: vector_search.py embed <id|all>", file=sys.stderr)
        sys.exit(1)

    api_key = get_api_key()
    conn = sqlite3.connect(DB_PATH)

    if args[0] == "all":
        rows = conn.execute(
            "SELECT id, content FROM memories WHERE is_active = 1 AND embedding IS NULL"
        ).fetchall()
    else:
        mem_id = int(args[0])
        rows = conn.execute(
            "SELECT id, content FROM memories WHERE id = ?", (mem_id,)
        ).fetchall()

    if not rows:
        print("No memories to embed.", file=sys.stderr)
        sys.exit(0)

    count = 0
    for row_id, content in rows:
        emb = get_embedding(content, api_key)
        conn.execute(
            "UPDATE memories SET embedding = ? WHERE id = ?",
            (json.dumps(emb), row_id),
        )
        count += 1
        print(f"  Embedded #{row_id}", file=sys.stderr)

    conn.commit()
    conn.close()
    print(f"Done. {count} memories embedded.", file=sys.stderr)


def cmd_reindex(args):
    """全記憶のembeddingを再生成する"""
    api_key = get_api_key()
    conn = sqlite3.connect(DB_PATH)
    rows = conn.execute(
        "SELECT id, content FROM memories WHERE is_active = 1"
    ).fetchall()

    if not rows:
        print("No active memories found.", file=sys.stderr)
        sys.exit(0)

    count = 0
    for row_id, content in rows:
        emb = get_embedding(content, api_key)
        conn.execute(
            "UPDATE memories SET embedding = ? WHERE id = ?",
            (json.dumps(emb), row_id),
        )
        count += 1
        print(f"  Reindexed #{row_id}", file=sys.stderr)

    conn.commit()
    conn.close()
    print(f"Done. {count} memories reindexed.", file=sys.stderr)


def main():
    if len(sys.argv) < 2:
        print(__doc__, file=sys.stderr)
        sys.exit(1)

    cmd = sys.argv[1]
    args = sys.argv[2:]

    if cmd == "search":
        cmd_search(args)
    elif cmd == "embed":
        cmd_embed(args)
    elif cmd == "reindex":
        cmd_reindex(args)
    else:
        print(f"Unknown command: {cmd}", file=sys.stderr)
        print(__doc__, file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
