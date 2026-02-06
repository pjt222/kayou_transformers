pub mod tca;
pub mod ebay;
pub mod google;
pub mod reddit;
pub mod forum;
pub mod direct;

use anyhow::Result;
use async_trait::async_trait;

use crate::types::{ImageCandidate, SearchRequest};

/// Trait for all image sources. Discovery finds URLs; downloading is separate.
#[async_trait]
pub trait Source: Send + Sync {
    /// Human-readable source name (e.g., "tca", "ebay").
    fn name(&self) -> &str;

    /// Default delay between requests in seconds.
    #[allow(dead_code)]
    fn default_delay(&self) -> f64;

    /// Discover image candidate URLs for a given search request.
    async fn discover(&self, request: &SearchRequest) -> Result<Vec<ImageCandidate>>;
}

/// Names of all available sources.
pub const SOURCE_NAMES: &[&str] = &["tca", "ebay", "google", "reddit", "forum", "direct"];

/// Create a source by name.
pub fn create_source(
    name: &str,
    delay_override: Option<f64>,
    direct_urls: &[String],
    direct_set: &str,
) -> Option<Box<dyn Source>> {
    match name {
        "tca" => Some(Box::new(tca::TcaSource::new(delay_override))),
        "ebay" => Some(Box::new(ebay::EbaySource::new(delay_override))),
        "google" => Some(Box::new(google::GoogleSource::new(delay_override))),
        "reddit" => Some(Box::new(reddit::RedditSource::new(delay_override))),
        "forum" => Some(Box::new(forum::ForumSource::new(delay_override))),
        "direct" => Some(Box::new(direct::DirectSource::new(
            direct_urls.to_vec(),
            direct_set.to_string(),
        ))),
        _ => None,
    }
}
