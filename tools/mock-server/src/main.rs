// tools/mock-server/src/main.rs
// A simple mock server to receive and log webhook requests for testing purposes.

use axum::{
    Router,
    body::Bytes,
    http::{HeaderMap, StatusCode},
    routing::post,
};
use std::net::SocketAddr;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};
use base64::Engine;
use time::OffsetDateTime;

const HEADER_WEBHOOK_ID: &str = "webhook-id";
const HEADER_WEBHOOK_SIGNATURE: &str = "webhook-signature";
const HEADER_WEBHOOK_TIMESTAMP: &str = "webhook-timestamp";
const PREFIX: &str = "whsec_";
const TOLERANCE_IN_SECONDS: i64 = 5 * 60;
const SIGNATURE_VERSION: &str = "v1";

#[derive(Debug)]
enum WebhookError {
    InvalidTimestamp,
    InvalidSecret,
    InvalidHeader(&'static str),
    TimestampTooOld,
    FutureTimestamp,
    MissingHeader(&'static str),
    InvalidSignature,
    InvalidPayload,
}

impl std::fmt::Display for WebhookError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            WebhookError::InvalidTimestamp => write!(f, "failed to parse timestamp"),
            WebhookError::InvalidSecret => write!(f, "invalid secret"),
            WebhookError::InvalidHeader(name) => write!(f, "invalid header: {}", name),
            WebhookError::TimestampTooOld => write!(f, "signature timestamp too old"),
            WebhookError::FutureTimestamp => write!(f, "signature timestamp too far in future"),
            WebhookError::MissingHeader(name) => write!(f, "missing header: {}", name),
            WebhookError::InvalidSignature => write!(f, "signature invalid"),
            WebhookError::InvalidPayload => write!(f, "payload invalid"),
        }
    }
}

struct Webhook {
    keys: Vec<Vec<u8>>,
}

impl Webhook {
    fn new(secret: &str) -> Result<Self, WebhookError> {
        // Split by comma to support key rotation (multiple secrets)
        let secrets: Vec<&str> = secret.split(',').map(|s| s.trim()).collect();
        
        let mut keys = Vec::new();
        for secret in secrets {
            let secret = secret.strip_prefix(PREFIX).unwrap_or(secret);
            let key = base64::engine::general_purpose::STANDARD
                .decode(secret)
                .map_err(|_| WebhookError::InvalidSecret)?;
            keys.push(key);
        }
        
        if keys.is_empty() {
            return Err(WebhookError::InvalidSecret);
        }
        
        Ok(Webhook { keys })
    }

    fn verify(&self, payload: &[u8], headers: &HeaderMap) -> Result<(), WebhookError> {
        let now = OffsetDateTime::now_utc().unix_timestamp();
        self.verify_with_timestamp(payload, headers, now)
    }

    fn verify_with_timestamp(
        &self,
        payload: &[u8],
        headers: &HeaderMap,
        now: i64,
    ) -> Result<(), WebhookError> {
        let msg_id = Self::get_header(headers, HEADER_WEBHOOK_ID, "id")?;
        let msg_signature = Self::get_header(headers, HEADER_WEBHOOK_SIGNATURE, "signature")?;
        let msg_ts = Self::get_header(headers, HEADER_WEBHOOK_TIMESTAMP, "timestamp")
            .and_then(Self::parse_timestamp)?;

        Self::verify_timestamp(msg_ts, now)?;

        // Try to verify with each key (for key rotation support)
        for key in &self.keys {
            if self.verify_with_key(msg_id, msg_ts, payload, msg_signature, key).is_ok() {
                return Ok(());
            }
        }
        
        Err(WebhookError::InvalidSignature)
    }

    fn verify_with_key(
        &self,
        msg_id: &str,
        msg_ts: i64,
        payload: &[u8],
        msg_signature: &str,
        key: &[u8],
    ) -> Result<(), WebhookError> {
        let versioned_signature = self.sign_with_key(msg_id, msg_ts, payload, key)?;
        let expected_signature = versioned_signature
            .split_once(',')
            .map(|x| x.1)
            .ok_or(WebhookError::InvalidSignature)?;

        msg_signature
            .split(' ')
            .filter_map(|x| x.split_once(','))
            .filter(|x| x.0 == SIGNATURE_VERSION)
            .any(|x| {
                (x.1.len() == expected_signature.len())
                    && (x
                        .1
                        .bytes()
                        .zip(expected_signature.bytes())
                        .fold(0, |acc, (a, b)| acc | (a ^ b))
                        == 0)
            })
            .then_some(())
            .ok_or(WebhookError::InvalidSignature)
    }

    fn sign_with_key(
        &self,
        msg_id: &str,
        timestamp: i64,
        payload: &[u8],
        key: &[u8],
    ) -> Result<String, WebhookError> {
        let payload = std::str::from_utf8(payload).map_err(|_| WebhookError::InvalidPayload)?;
        let to_sign = format!("{msg_id}.{timestamp}.{payload}");
        let signed = hmac_sha256::HMAC::mac(to_sign.as_bytes(), key);
        let encoded = base64::engine::general_purpose::STANDARD.encode(signed);
        Ok(format!("{SIGNATURE_VERSION},{encoded}"))
    }

    fn get_header<'a>(
        headers: &'a HeaderMap,
        header_name: &'static str,
        err_name: &'static str,
    ) -> Result<&'a str, WebhookError> {
        headers
            .get(header_name)
            .ok_or(WebhookError::MissingHeader(err_name))?
            .to_str()
            .map_err(|_| WebhookError::InvalidHeader(err_name))
    }

    fn parse_timestamp(hdr: &str) -> Result<i64, WebhookError> {
        str::parse::<i64>(hdr).map_err(|_| WebhookError::InvalidTimestamp)
    }

    fn verify_timestamp(ts: i64, now: i64) -> Result<(), WebhookError> {
        if now - ts > TOLERANCE_IN_SECONDS {
            Err(WebhookError::TimestampTooOld)
        } else if ts > now + TOLERANCE_IN_SECONDS {
            Err(WebhookError::FutureTimestamp)
        } else {
            Ok(())
        }
    }
}

#[tokio::main]
async fn main() {
    tracing_subscriber::registry()
        .with(tracing_subscriber::fmt::layer())
        .with(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| "info".into())
        )
        .init();

    let app = Router::new().route("/webhook", post(handler));

    let port = 9000;
    let addr = SocketAddr::from(([0, 0, 0, 0], port));

    tracing::info!("Mock Server running on port {}", port);
    tracing::info!("   Docker: http://host.docker.internal:{}/webhook", port);

    let listener = tokio::net::TcpListener::bind(addr).await.unwrap();
    axum::serve(listener, app).await.unwrap();
}

async fn handler(headers: HeaderMap, body: Bytes) -> StatusCode {
    println!("\n{}", "=".repeat(60));
    println!("WEBHOOK RECEIVED");
    println!("{}", "-".repeat(60));

    // Print Headers
    for (name, value) in &headers {
        println!("{name:?}: {value:?}");
    }
    println!("{}", "-".repeat(60));

    // Pretty Print JSON
    match serde_json::from_slice::<serde_json::Value>(&body) {
        Ok(json) => println!("{}", serde_json::to_string_pretty(&json).unwrap()),
        Err(_) => println!("{body:?}"),
    }

    println!("{}", "-".repeat(60));

    // Verify webhook signature
    // Get the secret from environment variable (supports comma-separated list for key rotation)
    let secret = std::env::var("WEBHOOK_SECRET").unwrap_or_else(|_| {
        tracing::warn!("WEBHOOK_SECRET not set, skipping signature verification");
        String::new()
    });

    if !secret.is_empty() {
        match Webhook::new(&secret) {
            Ok(wh) => {
                let key_count = wh.keys.len();
                if key_count > 1 {
                    println!("Using {} keys for verification (key rotation enabled)", key_count);
                }
                
                match wh.verify(&body, &headers) {
                    Ok(()) => {
                        println!("Signature verification: PASSED");
                    }
                    Err(e) => {
                        println!("Signature verification: FAILED ({})", e);
                        println!("{}\n", "=".repeat(60));
                        return StatusCode::UNAUTHORIZED;
                    }
                }
            },
            Err(e) => {
                println!("Failed to initialize webhook verifier: {}", e);
                println!("{}\n", "=".repeat(60));
                return StatusCode::INTERNAL_SERVER_ERROR;
            }
        }
    } else {
        println!("Signature verification: SKIPPED (no secret configured)");
    }

    println!("{}\n", "=".repeat(60));

    StatusCode::OK
}
