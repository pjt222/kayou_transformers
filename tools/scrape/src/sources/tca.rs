use anyhow::{Context, Result};
use async_trait::async_trait;
use reqwest::Client;
use scraper::{Html, Selector};
use std::time::Duration;

use crate::rate_limiter::RateLimiter;
use crate::sources::Source;
use crate::types::{ImageCandidate, SearchRequest};

const TCA_CATEGORY_URL: &str =
    "https://tradingcardarchives.com/product-category/transformers/kayou/";
const USER_AGENT: &str = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36";

pub struct TcaSource {
    client: Client,
    rate_limiter: RateLimiter,
}

impl TcaSource {
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

    /// Fetch a page and return its HTML body.
    async fn fetch_page(&self, url: &str) -> Result<String> {
        self.rate_limiter.wait().await;
        let response = self
            .client
            .get(url)
            .send()
            .await
            .with_context(|| format!("failed to fetch {}", url))?;
        let body = response
            .text()
            .await
            .with_context(|| format!("failed to read body from {}", url))?;
        Ok(body)
    }

    /// Crawl TCA category pages and collect all product page URLs.
    async fn crawl_product_urls(&self) -> Result<Vec<String>> {
        let mut all_urls = Vec::new();
        let mut page_num = 1u32;

        loop {
            let url = if page_num == 1 {
                TCA_CATEGORY_URL.to_string()
            } else {
                format!("{}page/{}/", TCA_CATEGORY_URL, page_num)
            };

            eprintln!("  TCA: fetching category page {}", page_num);
            let body = match self.fetch_page(&url).await {
                Ok(b) => b,
                Err(e) => {
                    if page_num > 1 {
                        break; // End of pagination
                    }
                    return Err(e);
                }
            };

            let document = Html::parse_document(&body);

            // Extract product links
            let product_selector =
                Selector::parse("a.woocommerce-LoopProduct-link").unwrap();
            let mut found_on_page = 0;

            for element in document.select(&product_selector) {
                if let Some(href) = element.value().attr("href") {
                    if href.contains("kayou-transformers") && !all_urls.contains(&href.to_string())
                    {
                        all_urls.push(href.to_string());
                        found_on_page += 1;
                    }
                }
            }

            eprintln!("    Found {} product links on page {}", found_on_page, page_num);

            if found_on_page == 0 {
                break;
            }

            // Check for next page
            let next_selector = Selector::parse("a.next.page-numbers").unwrap();
            if document.select(&next_selector).next().is_none() {
                break;
            }

            page_num += 1;
        }

        eprintln!("  TCA: {} total product pages found", all_urls.len());
        Ok(all_urls)
    }

    /// Extract set code from a TCA product URL slug.
    fn url_to_set_code(url: &str) -> Option<String> {
        // URLs like /product/kayou-transformers-tf02-ssr-007/
        let re = regex::Regex::new(r"kayou-transformers-(tf[a-z0-9]+)-").unwrap();
        re.captures(url).map(|caps| {
            caps.get(1).unwrap().as_str().to_uppercase()
        })
    }

    /// Extract card ID from a TCA product URL slug.
    fn url_to_card_id(url: &str) -> String {
        let re = regex::Regex::new(r"/product/kayou-transformers-[a-z0-9]+-(.+?)/?$").unwrap();
        match re.captures(url) {
            Some(caps) => caps.get(1).unwrap().as_str().to_string(),
            None => {
                // Fallback: use last path segment
                url.trim_end_matches('/')
                    .rsplit('/')
                    .next()
                    .unwrap_or("unknown")
                    .to_string()
            }
        }
    }

    /// Scrape a single product page for the full-res image URL.
    async fn scrape_card_image(&self, page_url: &str) -> Result<Option<String>> {
        let body = self.fetch_page(page_url).await?;
        let document = Html::parse_document(&body);

        // Try full-size link first: .woocommerce-product-gallery__image a[href]
        let gallery_link_selector =
            Selector::parse(".woocommerce-product-gallery__image a").unwrap();
        if let Some(element) = document.select(&gallery_link_selector).next() {
            if let Some(href) = element.value().attr("href") {
                if !href.is_empty() {
                    return Ok(Some(href.to_string()));
                }
            }
        }

        // Try img src in gallery
        let gallery_img_selector =
            Selector::parse(".woocommerce-product-gallery__image img").unwrap();
        if let Some(element) = document.select(&gallery_img_selector).next() {
            if let Some(src) = element.value().attr("src") {
                if !src.is_empty() {
                    return Ok(Some(src.to_string()));
                }
            }
        }

        // Fallback: wp-post-image
        let post_img_selector = Selector::parse(".wp-post-image").unwrap();
        if let Some(element) = document.select(&post_img_selector).next() {
            if let Some(src) = element.value().attr("src") {
                if !src.is_empty() {
                    return Ok(Some(src.to_string()));
                }
            }
        }

        Ok(None)
    }
}

#[async_trait]
impl Source for TcaSource {
    fn name(&self) -> &str {
        "tca"
    }

    fn default_delay(&self) -> f64 {
        2.0
    }

    async fn discover(&self, request: &SearchRequest) -> Result<Vec<ImageCandidate>> {
        let product_urls = self.crawl_product_urls().await?;
        let mut candidates = Vec::new();

        for page_url in &product_urls {
            let set_code = match Self::url_to_set_code(page_url) {
                Some(code) => code,
                None => continue,
            };

            // Filter to requested set
            if set_code != request.set_code {
                continue;
            }

            let card_id = Self::url_to_card_id(page_url);
            eprintln!("  TCA card: {} {}", set_code, card_id);

            match self.scrape_card_image(page_url).await {
                Ok(Some(image_url)) => {
                    let ext = url_extension(&image_url).to_string();
                    candidates.push(ImageCandidate {
                        source: "tca".to_string(),
                        set_code: set_code.clone(),
                        search_term: page_url.clone(),
                        image_url,
                        filename: format!("tca_{}.{}", card_id, ext),
                    });
                }
                Ok(None) => {
                    eprintln!("    No image found on {}", page_url);
                }
                Err(e) => {
                    eprintln!("    Error scraping {}: {}", page_url, e);
                }
            }
        }

        Ok(candidates)
    }
}

/// Extract file extension from URL, defaulting to "jpg".
fn url_extension(url: &str) -> &str {
    let clean = url.split('?').next().unwrap_or(url);
    match clean.rsplit('.').next() {
        Some(ext) if matches!(ext, "jpg" | "jpeg" | "png" | "webp" | "gif") => ext,
        _ => "jpg",
    }
}
