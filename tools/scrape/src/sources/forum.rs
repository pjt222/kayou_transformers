use anyhow::{Context, Result};
use async_trait::async_trait;
use regex::Regex;
use reqwest::Client;
use scraper::{Html, Selector};
use std::collections::HashSet;
use std::time::Duration;

use crate::config;
use crate::rate_limiter::RateLimiter;
use crate::sources::Source;
use crate::types::{ImageCandidate, SearchRequest};

const USER_AGENT: &str = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36";

pub struct ForumSource {
    client: Client,
    rate_limiter: RateLimiter,
}

impl ForumSource {
    pub fn new(delay_override: Option<f64>) -> Self {
        let delay = delay_override.unwrap_or(2.0);
        Self {
            client: Client::builder()
                .timeout(Duration::from_secs(30))
                .user_agent(USER_AGENT)
                .build()
                .expect("failed to build HTTP client"),
            rate_limiter: RateLimiter::new(delay),
        }
    }

    /// Scrape images from a forum thread page.
    async fn scrape_thread(&self, url: &str, domain: &str) -> Result<Vec<String>> {
        self.rate_limiter.wait().await;

        eprintln!("  Forum: fetching {}", url);

        let body = self
            .client
            .get(url)
            .send()
            .await
            .with_context(|| format!("failed to fetch forum thread: {}", url))?
            .text()
            .await
            .context("failed to read forum thread body")?;

        let document = Html::parse_document(&body);
        let mut image_urls = HashSet::new();

        // Select images from post bodies
        let selectors = match domain {
            "tfw2005" => vec![
                ".message-body img",
                ".bbWrapper img",
                ".message-content img",
            ],
            "seibertron" => vec![
                ".article-body img",
                ".news-content img",
                ".field-item img",
            ],
            _ => vec!["article img", ".post-content img", ".entry-content img"],
        };

        for selector_str in selectors {
            if let Ok(selector) = Selector::parse(selector_str) {
                for element in document.select(&selector) {
                    if let Some(src) = element.value().attr("src") {
                        if is_card_image(src) {
                            image_urls.insert(src.to_string());
                        }
                    }
                    // Also check data-src for lazy-loaded images
                    if let Some(src) = element.value().attr("data-src") {
                        if is_card_image(src) {
                            image_urls.insert(src.to_string());
                        }
                    }
                }
            }
        }

        // Also extract from image URLs in text (some forums use bbcode or raw URLs)
        let url_re = Regex::new(
            r#"https?://[^\s"'<>]+\.(?:jpg|jpeg|png|webp|gif)"#,
        )
        .unwrap();
        for cap in url_re.find_iter(&body) {
            let url = cap.as_str();
            if is_card_image(url) {
                image_urls.insert(url.to_string());
            }
        }

        eprintln!("    Found {} candidate images", image_urls.len());
        Ok(image_urls.into_iter().collect())
    }
}

#[async_trait]
impl Source for ForumSource {
    fn name(&self) -> &str {
        "forum"
    }

    fn default_delay(&self) -> f64 {
        2.0
    }

    async fn discover(&self, request: &SearchRequest) -> Result<Vec<ImageCandidate>> {
        let threads = config::forum_threads();
        let mut candidates = Vec::new();

        for (set_code, thread_url, domain) in &threads {
            if *set_code != request.set_code {
                continue;
            }

            // Extract thread ID for filename
            let thread_id = extract_thread_id(thread_url);

            match self.scrape_thread(thread_url, domain).await {
                Ok(image_urls) => {
                    for (i, image_url) in image_urls.iter().enumerate() {
                        let ext = url_extension(image_url);
                        candidates.push(ImageCandidate {
                            source: "forum".to_string(),
                            set_code: request.set_code.clone(),
                            search_term: thread_url.to_string(),
                            image_url: image_url.clone(),
                            filename: format!(
                                "forum_{}_{}_{:03}.{}",
                                domain,
                                thread_id,
                                i + 1,
                                ext
                            ),
                        });
                    }
                }
                Err(e) => {
                    eprintln!("    Forum error for {}: {}", thread_url, e);
                }
            }
        }

        Ok(candidates)
    }
}

/// Filter out avatars, smilies, icons, and other non-card images.
fn is_card_image(url: &str) -> bool {
    let lower = url.to_lowercase();

    // Must be a real image URL
    if !lower.contains(".jpg")
        && !lower.contains(".jpeg")
        && !lower.contains(".png")
        && !lower.contains(".webp")
    {
        return false;
    }

    // Exclude common non-card patterns
    let exclude_patterns = [
        "avatar",
        "smilie",
        "smiley",
        "emoji",
        "icon",
        "logo",
        "button",
        "banner",
        "badge",
        "thumb",
        "/data/avatars/",
        "/styles/",
        "/js/",
        "/css/",
        "gravatar.com",
        "pixel.quantserve",
    ];

    for pattern in &exclude_patterns {
        if lower.contains(pattern) {
            return false;
        }
    }

    true
}

fn extract_thread_id(url: &str) -> String {
    // TFW2005: .../threads/name.12345/
    let re = Regex::new(r"\.(\d+)/?$").unwrap();
    if let Some(caps) = re.captures(url) {
        return caps[1].to_string();
    }

    // Seibertron: .../news/name/12345/
    let re2 = Regex::new(r"/(\d+)/?$").unwrap();
    if let Some(caps) = re2.captures(url) {
        return caps[1].to_string();
    }

    "unknown".to_string()
}

fn url_extension(url: &str) -> &str {
    let clean = url.split('?').next().unwrap_or(url);
    match clean.rsplit('.').next() {
        Some(ext) if matches!(ext, "jpg" | "jpeg" | "png" | "webp" | "gif") => ext,
        _ => "jpg",
    }
}
