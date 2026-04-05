//! ホスト上での `cargo check` / CI 用スタブ。
//! Docker イメージのエントリポイントは `entrypoint.sh` → `llama-server`。

fn main() {
    println!("rust-inference-stub: 推論はコンテナ内の llama-server を使用してください。");
}
