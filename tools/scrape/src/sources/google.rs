use anyhow::{bail, Context, Result};
use async_trait::async_trait;
use reqwest::Client;
use serde::Deserialize;
use std::time::Duration;

use crate::rate_limiter::RateLimiter;
use crate::sources::Source;
use crate::types::{ImageCandidate, SearchRequest};

const USER_AGENT: &str = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36";

pub struct GoogleSource {
    client: Client,
    rate_limiter: RateLimiter,
    api_key: Option<String>,
    cx: Option<String>,
}

#[derive(Deserialize)]
struct GoogleSearchResponse {
    items: Option<Vec<GoogleSearchItem>>,
}

#[derive(Deserialize)]
struct GoogleSearchItem {
    link: Option<String>,
}

impl GoogleSource {
    pub fn new(delay_override: Option<f64>) -> Self {
        let delay = delay_override.unwrap_or(1.0);
        Self {
            client: Client::builder()
                .timeout(Duration::from_secs(30))
                .user_agent(USER_AGENT)
                .build()
                .expect("failed to build HTTP client"),
            rate_limiter: RateLimiter::new(delay),
            api_key: std::env::var("GOOGLE_API_KEY").ok(),
            cx: std::env::var("GOOGLE_CX").ok(),
        }
    }

    async fn search_images(
        &self,
        query: &str,
        api_key: &str,
        cx: &str,
    ) -> Result<Vec<String>> {
        self.rate_limiter.wait().await;

        let url = format!(
            "https://www.googleapis.com/customsearch/v1?key={}&cx={}&searchType=image&q={}&num=10",
            api_key,
            cx,
            url::form_urlencoded::byte_serialize(query.as_bytes()).collect::<String>()
        );

        eprintln!("  Google image search: {}", query);

        let response = self
            .client
            .get(&url)
            .send()
            .await
            .context("Google API request failed")?;

        let status = response.status();
        if !status.is_success() {
            let body = response.text().await.unwrap_or_default();
            bail!("Google API error {}: {}", status, body);
        }

        let body = response
            .text()
            .await
            .context("failed to read Google API response body")?;
        let search_response: GoogleSearchResponse =
            serde_json::from_str(&body).context("failed to parse Google API response")?;

        let urls: Vec<String> = search_response
            .items
            .unwrap_or_default()
            .into_iter()
            .filter_map(|item| item.link)
            .collect();

        eprintln!("    Found {} image results", urls.len());
        Ok(urls)
    }
}

#[async_trait]
impl Source for GoogleSource {
    fn name(&self) -> &str {
        "google"
    }

    fn default_delay(&self) -> f64 {
        1.0
    }

    async fn discover(&self, request: &SearchRequest) -> Result<Vec<ImageCandidate>> {
        let api_key = match &self.api_key {
            Some(k) => k.clone(),
            None => {
                eprintln!("  Google: GOOGLE_API_KEY not set, skipping");
                return Ok(Vec::new());
            }
        };
        let cx = match &self.cx {
            Some(c) => c.clone(),
            None => {
                eprintln!("  Google: GOOGLE_CX not set, skipping");
                return Ok(Vec::new());
            }
        };

        let mut candidates = Vec::new();
        let mut image_index = 0u32;

        // Use both English and Chinese terms
        let all_terms: Vec<&String> = request
            .english_terms
            .iter()
            .chain(request.chinese_terms.iter())
            .collect();

        for term in all_terms {
            match self.search_images(term, &api_key, &cx).await {
                Ok(urls) => {
                    for image_url in urls {
                        image_index += 1;
                        let ext = url_extension(&image_url).to_string();
                        candidates.push(ImageCandidate {
                            source: "google".to_string(),
                            set_code: request.set_code.clone(),
                            search_term: term.clone(),
                            image_url,
                            filename: format!(
                                "google_{}_{:03}.{}",
                                request.set_code.to_lowercase(),
                                image_index,
                                ext
                            ),
                        });
                    }
                }
                Err(e) => {
                    eprintln!("    Google search error for '{}': {}", term, e);
                }
            }
        }

        Ok(candidates)
    }
}

fn url_extension(url: &str) -> &str {
    let clean = url.split('?').next().unwrap_or(url);
    match clean.rsplit('.').next() {
        Some(ext) if matches!(ext, "jpg" | "jpeg" | "png" | "webp" | "gif") => ext,
        _ => "jpg",
    }
}
