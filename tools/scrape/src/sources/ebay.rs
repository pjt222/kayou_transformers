use anyhow::{Context, Result};
use async_trait::async_trait;
use regex::Regex;
use reqwest::Client;
use scraper::{Html, Selector};
use std::collections::HashSet;
use std::time::Duration;

use crate::rate_limiter::RateLimiter;
use crate::sources::Source;
use crate::types::{ImageCandidate, SearchRequest};

const USER_AGENT: &str = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36";

pub struct EbaySource {
    client: Client,
    rate_limiter: RateLimiter,
}

impl EbaySource {
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

    /// Search eBay and extract listing IDs from the results page.
    async fn search_listing_ids(&self, query: &str) -> Result<Vec<String>> {
        self.rate_limiter.wait().await;

        let url = format!(
            "https://www.ebay.com/sch/i.html?_nkw={}&_sacat=0&LH_BIN=1&_ipg=48",
            urlencoding(query)
        );

        eprintln!("  eBay search: {}", query);

        let body = self
            .client
            .get(&url)
            .send()
            .await
            .context("eBay search request failed")?
            .text()
            .await
            .context("failed to read eBay search body")?;

        let re = Regex::new(r#""listingId"\s*:\s*"(\d+)""#).unwrap();
        let ids: Vec<String> = re
            .captures_iter(&body)
            .map(|cap| cap[1].to_string())
            .collect::<HashSet<_>>()
            .into_iter()
            .collect();

        eprintln!("    Found {} listing IDs", ids.len());
        Ok(ids)
    }

    /// Fetch a single eBay listing page and extract image URLs.
    async fn fetch_listing_images(&self, listing_id: &str) -> Result<Vec<String>> {
        self.rate_limiter.wait().await;

        let url = format!("https://www.ebay.com/itm/{}", listing_id);

        let body = self
            .client
            .get(&url)
            .send()
            .await
            .with_context(|| format!("failed to fetch listing {}", listing_id))?
            .text()
            .await
            .with_context(|| format!("failed to read listing body {}", listing_id))?;

        // Extract all ebayimg.com image URLs
        let img_re = Regex::new(
            r"https://i\.ebayimg\.com/images/g/[A-Za-z0-9~_-]+/s-l\d+\.(?:jpg|png|webp)",
        )
        .unwrap();

        let mut images: Vec<String> = img_re
            .find_iter(&body)
            .map(|m| m.as_str().to_string())
            .collect::<HashSet<_>>()
            .into_iter()
            .collect();

        // Upgrade all to large size (s-l1600)
        let size_re = Regex::new(r"/s-l\d+\.").unwrap();
        for img in &mut images {
            *img = size_re.replace(img, "/s-l1600.").to_string();
        }

        // Deduplicate after upgrade
        let unique: Vec<String> = images
            .into_iter()
            .collect::<HashSet<_>>()
            .into_iter()
            .collect();

        // Try to add og:image if not already present
        let document = Html::parse_document(&body);
        let og_selector = Selector::parse("meta[property='og:image']").unwrap();
        if let Some(element) = document.select(&og_selector).next() {
            if let Some(content) = element.value().attr("content") {
                let large = size_re.replace(content, "/s-l1600.").to_string();
                if !unique.contains(&large) {
                    let mut result = vec![large];
                    result.extend(unique);
                    return Ok(result);
                }
            }
        }

        Ok(unique)
    }
}

#[async_trait]
impl Source for EbaySource {
    fn name(&self) -> &str {
        "ebay"
    }

    fn default_delay(&self) -> f64 {
        2.0
    }

    async fn discover(&self, request: &SearchRequest) -> Result<Vec<ImageCandidate>> {
        let mut all_listing_ids = HashSet::new();

        // Search using English terms
        for term in &request.english_terms {
            match self.search_listing_ids(term).await {
                Ok(ids) => {
                    all_listing_ids.extend(ids);
                }
                Err(e) => {
                    eprintln!("    eBay search error for '{}': {}", term, e);
                }
            }
        }

        if all_listing_ids.is_empty() {
            eprintln!("  eBay: no listings found for {}", request.set_code);
            return Ok(Vec::new());
        }

        eprintln!(
            "  eBay: {} unique listings for {}",
            all_listing_ids.len(),
            request.set_code
        );

        let mut candidates = Vec::new();

        for listing_id in &all_listing_ids {
            match self.fetch_listing_images(listing_id).await {
                Ok(images) => {
                    eprintln!("    Listing {} → {} images", listing_id, images.len());
                    for (i, image_url) in images.iter().enumerate() {
                        let ext = url_extension(image_url);
                        candidates.push(ImageCandidate {
                            source: "ebay".to_string(),
                            set_code: request.set_code.clone(),
                            search_term: listing_id.clone(),
                            image_url: image_url.clone(),
                            filename: format!("ebay_{}_{:02}.{}", listing_id, i + 1, ext),
                        });
                    }
                }
                Err(e) => {
                    eprintln!("    eBay listing {} error: {}", listing_id, e);
                }
            }
        }

        Ok(candidates)
    }
}

/// Simple URL-encoding for query strings.
fn urlencoding(s: &str) -> String {
    url::form_urlencoded::byte_serialize(s.as_bytes()).collect()
}

fn url_extension(url: &str) -> &str {
    let clean = url.split('?').next().unwrap_or(url);
    match clean.rsplit('.').next() {
        Some(ext) if matches!(ext, "jpg" | "jpeg" | "png" | "webp" | "gif") => ext,
        _ => "jpg",
    }
}
