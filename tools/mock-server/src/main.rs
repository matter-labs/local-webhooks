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

#[tokio::main]
async fn main() {
    tracing_subscriber::registry()
        .with(tracing_subscriber::fmt::layer())
        .with(tracing_subscriber::EnvFilter::from_default_env())
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
    for (name, value) in headers {
        println!("{name:?}: {value:?}");
    }
    println!("{}", "-".repeat(60));

    // Pretty Print JSON
    match serde_json::from_slice::<serde_json::Value>(&body) {
        Ok(json) => println!("{}", serde_json::to_string_pretty(&json).unwrap()),
        Err(_) => println!("{body:?}"),
    }

    println!("{}\n", "=".repeat(60));

    StatusCode::OK
}
