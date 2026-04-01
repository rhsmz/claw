「円卓の64人」を2026年現在の最強のローカルAIスタックとして稼働させるため、ご指定の要件（**gemma3:12b**を標準化、**TASKS.MD**の作成、**多言語Dockerfile**の実装、**Rust製管理スクリプト**）に基づき、各ファイルを再構築・新規作成します。

---

### 3. `TASKS.MD`（64名のプロンプト作成プラン）

全64名のエージェントに対し、ハルシネーションを抑え専門性を発揮させるための詳細設計図です。

```markdown
# AI帝国：円卓の64人 プロンプト作成タスク一覧

各クルーの `.md` ファイル作成時に遵守すべき設計指針。

## 1. 指揮・戦略部 (Executive Pod)
- **CTO**: 全45スキルと全64名の相関図を理解させ、プロジェクトを「設計→実装→監査」のフェーズに分解し、適切なエージェントを召喚するアルゴリズムを記述。
- **Policy Liaison**: Apple/GoogleのガイドラインPDF（Context7）を最優先で参照し、Non-Complianceがあれば即座にプロジェクトを停止させる「拒否権」を定義。

## 2. 設計・アーキテクチャ部 (Design Pod)
- **System Architect**: 多言語（JS/PHP/Go/Rust）の共存戦略（Microservices/BFF）を優先。Mermaidでの図解出力を必須化。
- **API Designer**: OpenAPI 3.1準拠。型安全性を重視し、後続のBuild Podが自動生成ツールを使えるレベルの厳密さを要求。

## 3. 開発軍団 (Build Legion)
- **Wizard (攻め)**: 各言語の最新仕様（e.g., Rust 2024 Edition, Go 1.2x）を前提とした超絶技巧の提案。
- **Guardian (守り)**: セキュリティ（Snyk）と静的解析（Linter）の結果を絶対視し、Wizardのコードを「差し戻す」冷徹さを定義。

## 4. 監査・法務部 (Audit & Legal Pod)
- **General Counsel**: 日本法および国際法（GDPR等）に基づき、契約書の不備を「赤字修正」形式で出力させる。
- **Store Gatekeeper**: ストア申請用メタデータの「キーワード最適化」と「リジェクトリスク語彙」のチェックリストを実装。
```



---

### 6. `Taskfile.yml`（更新版）

Rustスクリプトの実行と `gemma3:12b` のプルを統合します。

```yaml
tasks:
  # ... (既存タスクを維持)
  
  # --- 知識基盤 (Context7) の更新 (Rust版) ---
  knowledge-update:
    desc: 過去の資産を Context7 へ再インデックス
    cmds:
      - cargo run --manifest-path scripts/management/Cargo.toml -- sync
  
  # --- モデルの取得 (gemma3:12b) ---
  ollama-pull:
    desc: Ollama 内で gemma3:12b を pull
    cmds:
      - docker compose exec ollama ollama pull gemma3:12b
```

---

### 今後の流れ
これで、**バニラ状態のローカル推論環境（gemma3）**と、**多言語ビルド基盤**、そして**Rust製管理ツール**の定義が完了しました。

次はいよいよ、`TASKS.MD` に基づいて、帝国の最高司令官である **CTO（技術総帥）のプロンプト（`prompts/cto.md`）** を具体的に作成しましょうか？それとも、他の主要なクルー（PMや法務）のプロンプトから着手しますか？