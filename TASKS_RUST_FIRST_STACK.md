# タスク計画: Rust-first インフラ（上流製品の代替調査・段階移行）

**ファイル**: `TASKS_RUST_FIRST_STACK.md`  
**親計画との関係**: [TASKS.MD](TASKS.MD) はクループロンプト親計画。本ファイルは **Docker スタック / メモリ効率 / Rust 寄せ** の別トラック。

---

## Purpose

- Python ランタイム依存を減らし、**メモリが限られた環境**でも運用しやすいスタックに近づける。
- **oneAPI / llama.cpp 等の C++ ネイティブ配布**は推論層として例外許容し、**自前・ゲートウェイ・UI・可観測性**は可能な限り **Rust（または静的バイナリ）** を優先する。
- 現行 [docker-compose.yml](docker-compose.yml) の **上流製品**に対し、**Rust（または低メモリ）代替**を調査し、**PoC → 段階置換**のロードマップを固定する。

## Inputs

- 現行スタック: [README.md](README.md)、[Plan.md](Plan.md)、`docker-compose.yml`
- 推論: `rust-inference`（llama-server / SYCL）、**`opencl-inference`**（profile `opencl-wsl`・WSL の `/dev/dxg` + OpenCL）
- 運用: [Taskfile.yml](Taskfile.yml)、[ENV.md](ENV.md)

## 上流コンポーネント一覧（現行）

| 役割 | 現状 | 実装言語・備考 |
|------|------|----------------|
| LLM ゲートウェイ | LiteLLM | Python（公式イメージ） |
| チャット UI | Open WebUI（profile `ui`） | Python/Node 系イメージ |
| トレース・可観測性 | Langfuse v3（profile `ui`） | Node/複合スタック |
| MCP ハブ | docker/mcp-gateway | 上流イメージ |
| DB / キャッシュ | PostgreSQL、Redis | 言語非依存（維持） |
| 推論 | rust-inference | C++/SYCL + llama-server（方針どおり） |
| 推論（WSL OpenCL） | opencl-inference（`--profile opencl-wsl`） | llama-server + GGML OpenCL、`intel-opencl-icd` |
| 管理 CLI | scripts/management | 既に Rust |

## Rust（または低メモリ）代替候補 — 調査メモ

**注意**: 下記は調査時点の候補。**本番採用前にライセンス・メンテ状況・OpenAI 互換度・ZeroClaw 連携を PoC で検証すること。**

### LLM ゲートウェイ（LiteLLM 代替候補）

| 候補 | 言語 | メモ | リンク |
|------|------|------|--------|
| **litellm-rs** | Rust | Python LiteLLM に触発。クレート + `gateway` バイナリ、多数プロバイダ、OpenAI 互換。 | [crates.io/litellm-rs](https://crates.io/crates/litellm-rs)、[GitHub majiayu000/litellm-rs](https://github.com/majiayu000/litellm-rs) |
| **crabllm** | Rust | LiteLLM 風ゲートウェイ（コスト・ガードレール等）。コミュニティ小さめ。 | [GitHub crabtalk/crabllm](https://github.com/crabtalk/crabllm) |
| **Sentinel** | Rust | LLM プロキシ（キャッシュ・フェイルオーバー等）。要評価。 | [GitHub fbk2111/Sentinel](https://github.com/fbk2111/Sentinel) |
| **eavs** | Rust | ローカル向けプロキシ・ストリーミング。要評価。 | [GitHub byteowlz/eavs](https://github.com/byteowlz/eavs) |
| **自前最小プロキシ** | Rust | `axum` + ルーティング + `rust-inference` 固定。機能は最小。 | リポジトリ内新クレート |

### チャット UI（Open WebUI 代替候補）

| 候補 | 言語 | メモ | リンク |
|------|------|------|--------|
| **llumen** | Rust | 軽量チャット UI、OpenAI 互換 API 前提。 | [GitHub pinkfuwa/llumen](https://github.com/pinkfuwa/llumen) |
| **Erato** | Rust + TS | セルフホスト、MCP 拡張など。 | [GitHub EratoLab/erato](https://github.com/EratoLab/erato) |
| **Libre WebUI** | TypeScript | Rust ではないが参考比較用。 | [GitHub libre-webui/libre-webui](https://github.com/libre-webui/libre-webui) |

### 可観測性（Langfuse 代替候補）

| 候補 | 言語 | メモ | リンク |
|------|------|------|--------|
| **xtrace** | Rust（Axum） | LLM 向けトレース等の Rust 系。互換性は PoC で確認。 | [xtrace.sh](https://xtrace.sh/) |
| **OpenObserve** | 別スタック | ログ・トレース統合。Rust 製 UI ではないがストレージ効率の文脈で比較。 | 公式サイト参照 |
| **Langfuse を継続 + Rust SDK** | ハイブリッド | サーバは Python/Node のまま、**送信側のみ Rust**（`opentelemetry-langfuse`、`langfuse-ergonomic`）。完全 Rust 化ではない。 | [crates.io/opentelemetry-langfuse](https://crates.io/crates/opentelemetry-langfuse) 等 |

### 推論層

- **方針維持**: GGUF + llama.cpp（SYCL）+ 必要に応じて `llama-cpp-2` 等で Rust から束ねる（C++ はバックエンドとして残す）。

## Sub-tasks（推奨フェーズ）

- [x] **Phase 0 — 要件固定**  
  - ZeroClaw / Open WebUI が期待する **OpenAI 互換 API** の必須エンドポイント一覧化。  
  - LiteLLM 依存機能（DB 記録、Redis キャッシュ、マスターキー）の **要/不要** を整理。  
  - **成果物**: [docs/rust_gateway_openai_requirements.md](docs/rust_gateway_openai_requirements.md)

- [x] **Phase 1 — ゲートウェイ PoC**（先行実装）  
  - `litellm-rs` の `gateway` を Docker で起動し、`rust-inference:8080` へルーティングできるか検証。  
  - 代替として **最小 axum プロキシ**（チャット completions のみ）のスパイク。  
  - **結論**: リポジトリに **`llm-gateway-proxy/`** を追加（`POST /v1/chat/completions` のモデル書き換え＋ストリーミング転送、`GET /v1/models`、`POST /v1/embeddings` 転送、任意 Bearer）。**litellm-rs** は `config/gateway.yaml` で `base_url` をローカル向けにできるが公式 Docker 未整備のため、別途 `cargo install` / clone で検証可能（詳細は要件ドキュメント §4）。

- [x] **Phase 2 — Compose プロファイル**  
  - `litellm` 並行で `llm-gateway-rust` サービスを **profile `rust-gateway`** で追加済み。  
  - `.env.example` / `ENV.md` / `README.md` に切替手順を記載。

- [x] **Phase 3 — UI**（Llumen 同梱、Erato は未同梱）  
  - **Llumen**: `docker-compose.yml` の **`ui-llumen`** プロファイル、`task up-with-llumen`。`LLUMEN_OPENAI_BASE` で LiteLLM または `llm-gateway-rust` を選択。詳細は [docs/rust_gateway_openai_requirements.md](docs/rust_gateway_openai_requirements.md) §6。  
  - **Erato**: private submodule 前提のため **本リポジトリでは Compose 化せず**、必要時は上流の Helm / ソース手順で別途構築。  
  - **ブラウザ検証**: スタックポータル（`:8042`）の Llumen カード、または `http://localhost:8079`（既定）。§5 の手順と併用。

- [ ] **Phase 4 — 可観測性**  
  - xtrace または OTel 経路の PoC。Langfuse 完全脱却は任意。

- [ ] **Phase 5 — 整理**  
  - Python イメージ削除またはデフォルトから外す。ドキュメント・Taskfile 更新。

---

## テスト実行記録（Phase 1〜3 の検証）

**ローカル CI 相当（Docker 不要）**

| コマンド | 内容 | 最終確認 |
|----------|------|----------|
| `task test` | `compose config` + `management` / `llm-gateway-proxy` の `cargo test` + `rust-inference` `check` | ✅ 実施済（要: 定期的に再実行）。**Windows 上の `task test` を推奨**（WSL で `CARGO_HOME=/app` 等だと cargo が書き込み失敗することがある） |
| `cargo test --manifest-path llm-gateway-proxy/Cargo.toml` | ゲートウェイ URL 組み立て・モデル書き換え・Bearer | ✅ 4 tests |

**スタック起動後（Docker + GGUF 前提）**

| コマンド / 操作 | 期待 |
|-----------------|------|
| `task test-smoke` | コア 4 件 OK（ポータル・LiteLLM liveness・rust-inference `/health`・MCP :8811）。profile 系は未起動でも SKIP 可。**2026-04-05**: opencl / llm-gateway / Llumen / Langfuse まで OK（任意は ZeroClaw・Open WebUI SKIP） |
| `task test-smoke-strict` | 上記に加え Llumen / rust-gateway / UI 等もすべて OK（**ZeroClaw・Open WebUI 等は対応プロファイルを `up` してから**）。2026-04-05 試行では ZeroClaw・Open WebUI 未起動のためそこだけ FAIL |
| ブラウザ（§5・§6） | [docs/rust_gateway_openai_requirements.md](docs/rust_gateway_openai_requirements.md) 参照。ポータル `:8042`、Llumen `:8079`、`llm-gateway-rust` `:4100/health`（プレーン `ok` は a11y に出ない場合あり）。**2026-04-05**: MCP ブラウザでポータル・`:4100/health`・Llumen ログイン画面を確認 |
| **Llumen 実チャット** | `task up` → `task up-with-llumen` → UI でモデル選択し 1 往復（LiteLLM 経由で rust-inference）。今回はログイン画面まで（実チャットは手元で続行可） |
| **rust-gateway 経路** | `--profile rust-gateway` 起動後、`POST /v1/chat/completions`（Bearer = `LITELLM_MASTER_KEY`）が 200 またはストリーム。**2026-04-05**: `imperial-logic-high-v1` で HTTP 200・JSON 応答確認（キー取得例: `docker compose exec -T litellm printenv LITELLM_MASTER_KEY`） |

**Phase 4 以降（未着手）**

| 項目 | メモ |
|------|------|
| xtrace PoC | [xtrace.sh](https://xtrace.sh/) のセルフホスト手順・LiteLLM/プロキシとの接続を調査 |
| OTel → Langfuse | 送信側のみ Rust（`opentelemetry-langfuse` 等）のスパイク |

## Deliverables

- 各 Phase の **PoC 結果メモ**（採用/不採用理由、メモリ・レイテンシ目安）。
- 採用時: `docker-compose` 差分、`.env.example` 更新、README セクション。
- 不採用時: 次候補または自前実装のタスク化。

## Dependencies

- `rust-inference` がヘルス済み（GGUF 配置済み）であること。
- レビュー: `prompts/common/workflow_contract.md` の承認ゲートをプロジェクト運用で踏む場合は、本計画の Execute 前に **承認** を得る。

## Supervisor report & approval（任意）

クルー運用でゲートを使う場合は [crew/_template/TASKS_TEMPLATE.md](crew/_template/TASKS_TEMPLATE.md) に倣い、ここに承認を記録する。

## Progress history

- (2026-04-05) 初版作成。上流 Rust 代替の候補表を整理。
- (2026-04-05) Phase 0–2 着手: `docs/rust_gateway_openai_requirements.md`、`llm-gateway-proxy/`、`docker-compose.yml` の `rust-gateway` プロファイル、`task build-llm-gateway-rust`。
- (2026-04-05) ブラウザ検証フロー: 要件ドキュメント §5、`stack-portal` にゲートウェイカード追加、`task llm-gateway-dev`。MCP ブラウザで `:4100/health` を確認（ローカル `cargo run` 時）。
- (2026-04-05) Phase 3: Llumen（`ghcr.io/pinkfuwa/llumen`）を `ui-llumen` で追加。`task up-with-llumen`、README / ENV / ポータル更新。Erato は submodule 都合で未同梱と文書化。
- (2026-04-05) テスト強化: `llm-gateway-proxy` にユニットテスト 4 件、`task test` に同クレートを追加。スモークに Llumen / `llm-gateway-rust` を追加。`help-stack` の YAML を単一引用符で囲み `task` パースエラーを解消。
- (2026-04-05) `task test-smoke` はコア必須・profile 任意（SKIP）を既定化。全件必須は `task test-smoke-strict`。README §3b に成功手順を追記。
- (2026-04-05) テスト記録セクション追加。`task test` ✅。`task test-smoke` は **Docker Engine 未起動**のためコア FAIL（ポータル・LiteLLM・rust-inference・MCP）。Docker Desktop 起動 → `task up`（GGUF 配置済み）後に再実行予定。Phase 4 は調査メモのみ追記。
- (2026-04-05) **Phase 1〜3 コマンド＋ブラウザ検証**: `task test`（Windows）✅、`task test-smoke`（コア＋opencl＋gateway＋Llumen）✅、`llm-gateway-proxy` Docker ベースを **Rust 1.86** に上げて `rust-gateway` イメージがビルド可能に。`POST /v1/chat/completions`（`:4100`）✅。要件ドキュメント §5・§6 相当をブラウザ MCP で確認（ポータル・ゲートウェイ health・Llumen ログイン画面）。**次の作業トラック: Phase 4（可観測性 PoC）**。

## Definition of Done（本ファイル単体）

- [x] Phase 1 ゲートウェイ PoC が完了し、結論が上表または進捗履歴に記録されている。  
- [x] 採用アーキテクチャが README または Plan.md と矛盾しない（既定スタックは LiteLLM のまま、Rust ゲートウェイは任意プロファイル）。  
- [ ] 「Python を減らす」範囲（ゲートウェイのみ / UI まで / 可観測性まで）がステークホルダ合意済み。

## Cross-reference

- 親計画（クルー）: [TASKS.MD](TASKS.MD)  
- インフラ計画メモ: [Plan.md](Plan.md)  
- 個別実行用テンプレ: [crew/_template/TASKS_TEMPLATE.md](crew/_template/TASKS_TEMPLATE.md)（必要なら `crew/<agent_id>/TASKS_<timestamp>_rust_stack.MD` を派生）
