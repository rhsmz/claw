//! OpenAI 互換の薄いプロキシ: クライアント向けモデル名（imperial-*）を
//! llama-server が期待する `model` に書き換えて `UPSTREAM_OPENAI_BASE` へ転送する。

use axum::{
    body::Body,
    extract::State,
    http::{header, HeaderMap, StatusCode},
    response::{IntoResponse, Response},
    routing::get,
    Router,
};
use bytes::Bytes;
use futures_util::StreamExt;
use serde_json::{json, Value};
use std::net::SocketAddr;
use std::sync::Arc;
use tower_http::cors::CorsLayer;
use tower_http::trace::TraceLayer;
use tracing::{error, info};

fn build_upstream_url(upstream_base: &str, subpath: &str) -> String {
    let base = upstream_base.trim_end_matches('/');
    let p = subpath.trim_start_matches('/');
    format!("{base}/{p}")
}

fn rewrite_model_in_json(body: &mut Value, compat_model: &str, aliases: &[String]) {
    let Some(model) = body.get("model").and_then(|m| m.as_str()) else {
        return;
    };
    if aliases.iter().any(|a| a == model) {
        if let Some(m) = body.get_mut("model") {
            *m = json!(compat_model);
        }
    }
}

#[derive(Clone)]
struct AppState {
    client: reqwest::Client,
    /// 例: http://rust-inference:8080/v1 （末尾スラッシュなし推奨）
    upstream_base: String,
    /// llama-server に送る model 文字列
    compat_model: String,
    /// 上流 Authorization（llama はダミー可）
    upstream_bearer: String,
    /// このゲートウェイの Bearer。未設定なら検証しない。
    gateway_api_key: Option<String>,
    /// imperial-* など → compat_model へ置換する名前
    aliases: Vec<String>,
}

impl AppState {
    fn upstream_url(&self, path: &str) -> String {
        build_upstream_url(&self.upstream_base, path)
    }

    fn check_gateway_auth(&self, headers: &HeaderMap) -> Result<(), StatusCode> {
        let Some(expected) = &self.gateway_api_key else {
            return Ok(());
        };
        let auth = headers
            .get(header::AUTHORIZATION)
            .and_then(|v| v.to_str().ok())
            .ok_or(StatusCode::UNAUTHORIZED)?;
        let prefix = "Bearer ";
        if !auth.starts_with(prefix) {
            return Err(StatusCode::UNAUTHORIZED);
        }
        if auth[prefix.len()..] != *expected {
            return Err(StatusCode::UNAUTHORIZED);
        }
        Ok(())
    }

    fn rewrite_model(&self, body: &mut Value) {
        rewrite_model_in_json(body, &self.compat_model, &self.aliases);
    }
}

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt()
        .with_env_filter(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| tracing_subscriber::EnvFilter::new("info")),
        )
        .init();

    let bind = std::env::var("BIND_ADDR").unwrap_or_else(|_| "0.0.0.0:4100".into());
    let upstream_base = std::env::var("UPSTREAM_OPENAI_BASE")
        .unwrap_or_else(|_| "http://127.0.0.1:9080/v1".into());
    let compat_model = std::env::var("OPENAI_COMPAT_MODEL")
        .unwrap_or_else(|_| "openai/gpt-3.5-turbo".into());
    let upstream_bearer = std::env::var("UPSTREAM_API_KEY").unwrap_or_else(|_| "dummy-key".into());
    let gateway_api_key = std::env::var("GATEWAY_API_KEY").ok().filter(|s| !s.is_empty());

    let aliases_csv = std::env::var("MODEL_ALIASES").unwrap_or_else(|_| {
        "imperial-logic-high-v1,imperial-build-knight-v1,imperial-scout-mini-v1".into()
    });
    let aliases: Vec<String> = aliases_csv
        .split(',')
        .map(|s| s.trim().to_string())
        .filter(|s| !s.is_empty())
        .collect();

    let client = reqwest::Client::builder()
        .timeout(std::time::Duration::from_secs(600))
        .build()
        .expect("reqwest client");

    let state = Arc::new(AppState {
        client,
        upstream_base,
        compat_model: compat_model.clone(),
        upstream_bearer,
        gateway_api_key,
        aliases,
    });

    info!(
        bind = %bind,
        upstream = %state.upstream_base,
        compat_model = %compat_model,
        gateway_auth = state.gateway_api_key.is_some(),
        "llm-gateway-proxy starting"
    );

    let app = Router::new()
        .route("/health", get(health))
        .route("/v1/models", get(models_list))
        .fallback(axum::routing::any(proxy_v1))
        .layer(CorsLayer::permissive())
        .layer(TraceLayer::new_for_http())
        .with_state(state);

    let addr: SocketAddr = bind.parse().expect("BIND_ADDR must be a valid SocketAddr");
    let listener = tokio::net::TcpListener::bind(addr)
        .await
        .unwrap_or_else(|e| panic!("bind {addr}: {e}"));
    axum::serve(listener, app).await.expect("serve");
}

async fn health() -> impl IntoResponse {
    (StatusCode::OK, "ok")
}

/// Open WebUI が期待する形式で、エイリアス名をそのまま id として返す。
async fn models_list(State(state): State<Arc<AppState>>, headers: HeaderMap) -> Response {
    if let Err(code) = state.check_gateway_auth(&headers) {
        return (code, "unauthorized").into_response();
    }
    let data: Vec<Value> = state
        .aliases
        .iter()
        .map(|id| {
            json!({
                "id": id,
                "object": "model",
                "created": 0_i64,
                "owned_by": "local"
            })
        })
        .collect();
    Json(json!({ "object": "list", "data": data })).into_response()
}

struct Json(Value);

impl IntoResponse for Json {
    fn into_response(self) -> Response {
        let body = serde_json::to_string(&self.0).unwrap_or_else(|_| "{}".into());
        Response::builder()
            .status(StatusCode::OK)
            .header(header::CONTENT_TYPE, "application/json")
            .body(Body::from(body))
            .unwrap()
    }
}

async fn proxy_v1(
    State(state): State<Arc<AppState>>,
    req: axum::http::Request<Body>,
) -> Response {
    if let Err(code) = state.check_gateway_auth(req.headers()) {
        return (code, "unauthorized").into_response();
    }

    let method = req.method().clone();
    let uri = req.uri().clone();
    let path = uri.path().to_string();

    if !path.starts_with("/v1/") {
        return (StatusCode::NOT_FOUND, "not found").into_response();
    }

    let sub = path.trim_start_matches("/v1/").to_string();
    let url = state.upstream_url(&sub);
    if let Some(q) = uri.query() {
        let url = format!("{url}?{q}");
        return forward(&state, method, url, req).await;
    }
    forward(&state, method, url, req).await
}

async fn forward(
    state: &AppState,
    method: axum::http::Method,
    url: String,
    req: axum::http::Request<Body>,
) -> Response {
    let body_bytes = match axum::body::to_bytes(req.into_body(), usize::MAX).await {
        Ok(b) => b,
        Err(e) => {
            error!(%e, "read body");
            return (StatusCode::BAD_REQUEST, "body read failed").into_response();
        }
    };

    let mut outgoing = body_bytes.clone();

    let rewrite_body = method == axum::http::Method::POST
        && (url.contains("/chat/completions") || url.contains("/embeddings"));
    if rewrite_body {
        if let Ok(mut v) = serde_json::from_slice::<Value>(&body_bytes) {
            state.rewrite_model(&mut v);
            if let Ok(b) = serde_json::to_vec(&v) {
                outgoing = Bytes::from(b);
            }
        }
    }

    let mut rb = state
        .client
        .request(method, &url)
        .header(
            header::AUTHORIZATION,
            format!("Bearer {}", state.upstream_bearer),
        )
        .header(header::CONTENT_TYPE, "application/json");

    if !outgoing.is_empty() {
        rb = rb.body(outgoing);
    }

    let upstream = match rb.send().await {
        Ok(r) => r,
        Err(e) => {
            error!(%e, %url, "upstream request");
            return (StatusCode::BAD_GATEWAY, "upstream error").into_response();
        }
    };

    let status =
        StatusCode::from_u16(upstream.status().as_u16()).unwrap_or(StatusCode::BAD_GATEWAY);
    let mut res = Response::builder().status(status);

    for (key, value) in upstream.headers().iter() {
        let name = key.as_str();
        if name.eq_ignore_ascii_case("transfer-encoding")
            || name.eq_ignore_ascii_case("connection")
        {
            continue;
        }
        if let Ok(v) = value.to_str() {
            if let Ok(h) = axum::http::HeaderName::try_from(name) {
                res = res.header(h, v);
            }
        }
    }

    let stream = upstream.bytes_stream().map(|r| {
        r.map_err(|_| std::io::Error::other("upstream stream"))
    });
    let body = Body::from_stream(stream);

    match res.body(body) {
        Ok(resp) => resp,
        Err(_) => (StatusCode::INTERNAL_SERVER_ERROR, "response build").into_response(),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn upstream_url_trims_and_joins() {
        assert_eq!(
            build_upstream_url("http://h:8080/v1", "chat/completions"),
            "http://h:8080/v1/chat/completions"
        );
        assert_eq!(
            build_upstream_url("http://h:8080/v1/", "/chat/completions"),
            "http://h:8080/v1/chat/completions"
        );
    }

    #[test]
    fn rewrite_model_replaces_alias_only() {
        let mut v = json!({"model": "imperial-logic-high-v1", "stream": true});
        rewrite_model_in_json(
            &mut v,
            "openai/gpt-3.5-turbo",
            &["imperial-logic-high-v1".to_string()],
        );
        assert_eq!(v["model"], "openai/gpt-3.5-turbo");
        assert_eq!(v["stream"], true);

        let mut other = json!({"model": "gpt-4"});
        rewrite_model_in_json(&mut other, "openai/gpt-3.5-turbo", &["imperial-logic-high-v1".to_string()]);
        assert_eq!(other["model"], "gpt-4");
    }

    #[test]
    fn gateway_auth_accepts_matching_bearer() {
        let mut headers = HeaderMap::new();
        headers.insert(
            header::AUTHORIZATION,
            "Bearer secret-key".parse().unwrap(),
        );
        let state_key = Some("secret-key".to_string());
        let st = AppState {
            client: reqwest::Client::new(),
            upstream_base: String::new(),
            compat_model: String::new(),
            upstream_bearer: String::new(),
            gateway_api_key: state_key,
            aliases: vec![],
        };
        assert!(st.check_gateway_auth(&headers).is_ok());
    }

    #[test]
    fn gateway_auth_rejects_wrong_bearer() {
        let mut headers = HeaderMap::new();
        headers.insert(
            header::AUTHORIZATION,
            "Bearer wrong".parse().unwrap(),
        );
        let st = AppState {
            client: reqwest::Client::new(),
            upstream_base: String::new(),
            compat_model: String::new(),
            upstream_bearer: String::new(),
            gateway_api_key: Some("secret-key".to_string()),
            aliases: vec![],
        };
        assert_eq!(
            st.check_gateway_auth(&headers),
            Err(StatusCode::UNAUTHORIZED)
        );
    }
}
