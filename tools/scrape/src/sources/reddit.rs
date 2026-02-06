use anyhow::{Context, Result};
use async_trait::async_trait;
use reqwest::Client;
use serde::Deserialize;
use std::collections::HashSet;
use std::time::Duration;

use crate::rate_limiter::RateLimiter;
use crate::sources::Source;
use crate::types::{ImageCandidate, SearchRequest};

const USER_AGENT: &str = "KayouTFScraper/0.1 (trading card research; https://github.com/pjt222/kayou_transformers)";
const SUBREDDITS: &[&str] = &["transformers", "tradingcards"];

pub struct RedditSource {
    client: Client,
    rate_limiter: RateLimiter,
}

#[derive(Deserialize)]
struct RedditListing {
    data: Option<RedditListingData>,
}

#[derive(Deserialize)]
struct RedditListingData {
    children: Option<Vec<RedditChild>>,
}

#[derive(Deserialize)]
struct RedditChild {
    data: Option<RedditPost>,
}

#[derive(Deserialize)]
struct RedditPost {
    id: Option<String>,
    url: Option<String>,
    preview: Option<RedditPreview>,
    is_gallery: Option<bool>,
    gallery_data: Option<RedditGalleryData>,
    media_metadata: Option<serde_json::Value>,
}

#[derive(Deserialize)]
struct RedditPreview {
    images: Option<Vec<RedditPreviewImage>>,
}

#[derive(Deserialize)]
struct RedditPreviewImage {
    source: Option<RedditImageSource>,
}

#[derive(Deserialize)]
struct RedditImageSource {
    url: Option<String>,
}

#[derive(Deserialize)]
struct RedditGalleryData {
    items: Option<Vec<RedditGalleryItem>>,
}

#[derive(Deserialize)]
struct RedditGalleryItem {
    media_id: Option<String>,
}

impl RedditSource {
    pub fn new(delay_override: Option<f64>) -> Self {
        let delay = delay_override.unwrap_or(1.0);
        Self {
            client: Client::builder()
                .timeout(Duration::from_secs(30))
                .user_agent(USER_AGENT)
                .build()
                .expect("failed to build HTTP client"),
            rate_limiter: RateLimiter::new(delay),
        }
    }

    async fn search_subreddit(
        &self,
        subreddit: &str,
        query: &str,
    ) -> Result<Vec<(String, Vec<String>)>> {
        self.rate_limiter.wait().await;

        let url = format!(
            "https://www.reddit.com/r/{}/search.json?q={}&restrict_sr=1&type=link&limit=25",
            subreddit,
            url::form_urlencoded::byte_serialize(query.as_bytes()).collect::<String>()
        );

        eprintln!("  Reddit: r/{} search: {}", subreddit, query);

        let response = self
            .client
            .get(&url)
            .send()
            .await
            .with_context(|| format!("Reddit search failed for r/{}", subreddit))?;

        if !response.status().is_success() {
            eprintln!(
                "    Reddit returned {} for r/{}",
                response.status(),
                subreddit
            );
            return Ok(Vec::new());
        }

        let body = response
            .text()
            .await
            .context("failed to read Reddit response body")?;
        let listing: RedditListing =
            serde_json::from_str(&body).context("failed to parse Reddit JSON response")?;

        let mut results = Vec::new();

        let children = listing
            .data
            .and_then(|d| d.children)
            .unwrap_or_default();

        for child in children {
            let post = match child.data {
                Some(p) => p,
                None => continue,
            };

            let post_id = post.id.unwrap_or_default();
            if post_id.is_empty() {
                continue;
            }

            let mut image_urls = Vec::new();

            // Direct URL (i.redd.it, i.imgur.com)
            if let Some(ref url) = post.url {
                if is_image_url(url) {
                    image_urls.push(decode_html_entities(url));
                }
            }

            // Preview images
            if let Some(preview) = &post.preview {
                if let Some(images) = &preview.images {
                    for img in images {
                        if let Some(source) = &img.source {
                            if let Some(url) = &source.url {
                                image_urls.push(decode_html_entities(url));
                            }
                        }
                    }
                }
            }

            // Gallery posts
            if post.is_gallery == Some(true) {
                if let (Some(gallery), Some(metadata)) =
                    (&post.gallery_data, &post.media_metadata)
                {
                    if let Some(items) = &gallery.items {
                        for item in items {
                            if let Some(media_id) = &item.media_id {
                                // Try to get full image URL from metadata
                                if let Some(meta) = metadata.get(media_id.as_str()) {
                                    if let Some(s) = meta.get("s") {
                                        if let Some(url_val) = s.get("u") {
                                            if let Some(url_str) = url_val.as_str() {
                                                image_urls.push(decode_html_entities(url_str));
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            if !image_urls.is_empty() {
                results.push((post_id, image_urls));
            }
        }

        eprintln!("    Found {} posts with images", results.len());
        Ok(results)
    }
}

#[async_trait]
impl Source for RedditSource {
    fn name(&self) -> &str {
        "reddit"
    }

    fn default_delay(&self) -> f64 {
        1.0
    }

    async fn discover(&self, request: &SearchRequest) -> Result<Vec<ImageCandidate>> {
        let mut candidates = Vec::new();
        let mut seen_urls = HashSet::new();

        for subreddit in SUBREDDITS {
            for term in &request.english_terms {
                match self.search_subreddit(subreddit, term).await {
                    Ok(posts) => {
                        for (post_id, image_urls) in posts {
                            for (i, image_url) in image_urls.iter().enumerate() {
                                if seen_urls.contains(image_url) {
                                    continue;
                                }
                                seen_urls.insert(image_url.clone());

                                let ext = url_extension(image_url);
                                candidates.push(ImageCandidate {
                                    source: "reddit".to_string(),
                                    set_code: request.set_code.clone(),
                                    search_term: term.clone(),
                                    image_url: image_url.clone(),
                                    filename: format!(
                                        "reddit_{}_{:02}.{}",
                                        post_id,
                                        i + 1,
                                        ext
                                    ),
                                });
                            }
                        }
                    }
                    Err(e) => {
                        eprintln!(
                            "    Reddit error for r/{} '{}': {}",
                            subreddit, term, e
                        );
                    }
                }
            }
        }

        Ok(candidates)
    }
}

fn is_image_url(url: &str) -> bool {
    let lower = url.to_lowercase();
    lower.contains("i.redd.it")
        || lower.contains("i.imgur.com")
        || lower.ends_with(".jpg")
        || lower.ends_with(".jpeg")
        || lower.ends_with(".png")
        || lower.ends_with(".webp")
        || lower.ends_with(".gif")
}

fn decode_html_entities(s: &str) -> String {
    s.replace("&amp;", "&").replace("&lt;", "<").replace("&gt;", ">")
}

fn url_extension(url: &str) -> &str {
    let clean = url.split('?').next().unwrap_or(url);
    match clean.rsplit('.').next() {
        Some(ext) if matches!(ext, "jpg" | "jpeg" | "png" | "webp" | "gif") => ext,
        _ => "jpg",
    }
}
