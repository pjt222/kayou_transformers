use std::time::{Duration, Instant};

use tokio::sync::Mutex;

/// Per-source rate limiter that enforces a minimum delay between requests.
pub struct RateLimiter {
    delay: Duration,
    last_request: Mutex<Instant>,
}

impl RateLimiter {
    pub fn new(delay_secs: f64) -> Self {
        Self {
            delay: Duration::from_secs_f64(delay_secs),
            // Set to past so first request goes through immediately
            last_request: Mutex::new(Instant::now() - Duration::from_secs(60)),
        }
    }

    /// Wait until the rate limit allows a new request.
    pub async fn wait(&self) {
        let mut last = self.last_request.lock().await;
        let elapsed = last.elapsed();
        if elapsed < self.delay {
            tokio::time::sleep(self.delay - elapsed).await;
        }
        *last = Instant::now();
    }
}
