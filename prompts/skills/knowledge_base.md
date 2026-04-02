# Skill Card: knowledge_base

## Purpose
Use `knowledge_base` to produce higher-quality, verifiable outputs in scope.

## Local RAG（hexa_rag）仕様
- MCP サーバ `hexa_rag` の `search`（または `rag`）で関連チャンクを取得する前提で動作します。
- 出力は必ず Markdown 形式にします。
- 「人間が判断できる」ため、ベクトル検索でヒットした根拠は `source_path` とセットで、最低限そのチャンクの抜粋（短い引用でも可）を `## Vector References` にまとめて提示します。
- `## Vector References` には、取得順（上位ほど重要）と各 `source_path` を明示し、回答本文中の主張に対応づけて引用番号を付けます（例: [1], [2]）。

## Activation Triggers
- Task explicitly requires this capability.
- Current evidence quality is insufficient without this capability.

## Minimum Output
- Intent
- Evidence summary
- Confidence note
- Vector References（必須）: [1] `source_path`: 抜粋（引用/要約。可能なら見出しやキーフレーズを含める）
