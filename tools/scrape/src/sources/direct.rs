use anyhow::Result;
use async_trait::async_trait;

use crate::sources::Source;
use crate::types::{ImageCandidate, SearchRequest};

/// Direct URL source — no discovery, just user-provided URLs.
pub struct DirectSource {
    urls: Vec<String>,
    target_set: String,
}

impl DirectSource {
    pub fn new(urls: Vec<String>, target_set: String) -> Self {
        Self { urls, target_set }
    }
}

#[async_trait]
impl Source for DirectSource {
    fn name(&self) -> &str {
        "direct"
    }

    fn default_delay(&self) -> f64 {
        0.5
    }

    async fn discover(&self, request: &SearchRequest) -> Result<Vec<ImageCandidate>> {
        // Only produce candidates if the request matches the target set
        if !self.target_set.is_empty() && self.target_set != request.set_code {
            return Ok(Vec::new());
        }

        let mut candidates = Vec::new();

        for (i, url) in self.urls.iter().enumerate() {
            let domain = extract_domain(url);
            let ext = url_extension(url);
            candidates.push(ImageCandidate {
                source: "direct".to_string(),
                set_code: request.set_code.clone(),
                search_term: "direct".to_string(),
                image_url: url.clone(),
                filename: format!("direct_{}_{:03}.{}", domain, i + 1, ext),
            });
        }

        Ok(candidates)
    }
}

fn extract_domain(url: &str) -> String {
    url::Url::parse(url)
        .ok()
        .and_then(|u| u.host_str().map(|h| h.to_string()))
        .unwrap_or_else(|| "unknown".to_string())
        .replace('.', "_")
}

fn url_extension(url: &str) -> &str {
    let clean = url.split('?').next().unwrap_or(url);
    match clean.rsplit('.').next() {
        Some(ext) if matches!(ext, "jpg" | "jpeg" | "png" | "webp" | "gif") => ext,
        _ => "jpg",
    }
}
