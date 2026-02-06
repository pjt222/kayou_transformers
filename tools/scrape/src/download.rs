use std::collections::HashSet;
use std::path::{Path, PathBuf};
use std::sync::Arc;
use std::time::Duration;

use anyhow::{bail, Context, Result};
use chrono::Local;
use indicatif::{ProgressBar, ProgressStyle};
use reqwest::Client;
use sha2::{Digest, Sha256};
use tokio::sync::Semaphore;

use crate::types::{ImageCandidate, ScrapeLogEntry};

const USER_AGENT: &str = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36";

pub struct Downloader {
    client: Client,
    semaphore: Arc<Semaphore>,
    dedup_hash: bool,
}

impl Downloader {
    pub fn new(concurrency: usize, dedup_hash: bool) -> Self {
        let client = Client::builder()
            .timeout(Duration::from_secs(30))
            .user_agent(USER_AGENT)
            .build()
            .expect("failed to build HTTP client");

        Self {
            client,
            semaphore: Arc::new(Semaphore::new(concurrency)),
            dedup_hash,
        }
    }

    /// Download all candidates concurrently with progress bar.
    /// Returns log entries for each attempt.
    pub async fn download_all(
        &self,
        candidates: Vec<ImageCandidate>,
        root: &Path,
        seen_hashes: &mut HashSet<String>,
    ) -> Vec<ScrapeLogEntry> {
        if candidates.is_empty() {
            return Vec::new();
        }

        let progress_bar = ProgressBar::new(candidates.len() as u64);
        progress_bar.set_style(
            ProgressStyle::default_bar()
                .template("[{elapsed_precise}] {bar:40.cyan/blue} {pos}/{len} {msg}")
                .unwrap()
                .progress_chars("##-"),
        );

        let mut handles = Vec::new();

        for candidate in candidates {
            let semaphore = Arc::clone(&self.semaphore);
            let client = self.client.clone();
            let root = root.to_path_buf();
            let dedup_hash = self.dedup_hash;
            let progress_bar = progress_bar.clone();

            let handle = tokio::spawn(async move {
                let _permit = semaphore.acquire().await.unwrap();
                let result =
                    download_one(&client, &candidate, &root, dedup_hash).await;
                progress_bar.inc(1);

                let timestamp = Local::now().format("%Y-%m-%d %H:%M:%S").to_string();

                match result {
                    Ok(DownloadResult::Success { local_path }) => {
                        progress_bar.set_message(format!("OK: {}", candidate.filename));
                        ScrapeLogEntry {
                            timestamp,
                            source: candidate.source,
                            set_code: candidate.set_code,
                            search_term: candidate.search_term,
                            image_url: candidate.image_url,
                            local_path,
                            success: "TRUE".to_string(),
                        }
                    }
                    Ok(DownloadResult::Skipped { reason }) => {
                        progress_bar.set_message(format!("SKIP: {}", reason));
                        ScrapeLogEntry {
                            timestamp,
                            source: candidate.source,
                            set_code: candidate.set_code,
                            search_term: candidate.search_term,
                            image_url: candidate.image_url,
                            local_path: String::new(),
                            success: "FALSE".to_string(),
                        }
                    }
                    Err(e) => {
                        progress_bar.set_message(format!("FAIL: {}", e));
                        ScrapeLogEntry {
                            timestamp,
                            source: candidate.source,
                            set_code: candidate.set_code,
                            search_term: candidate.search_term,
                            image_url: candidate.image_url,
                            local_path: String::new(),
                            success: "FALSE".to_string(),
                        }
                    }
                }
            });

            handles.push(handle);
        }

        let mut entries = Vec::new();
        for handle in handles {
            if let Ok(entry) = handle.await {
                // Check content hash dedup after download
                if self.dedup_hash && entry.success == "TRUE" && !entry.local_path.is_empty() {
                    if let Some(hash) = compute_file_hash(&root.join(&entry.local_path)) {
                        if !seen_hashes.insert(hash) {
                            // Duplicate content, remove file
                            let _ = std::fs::remove_file(root.join(&entry.local_path));
                            let mut deduped = entry;
                            deduped.success = "FALSE".to_string();
                            deduped.local_path = String::new();
                            entries.push(deduped);
                            continue;
                        }
                    }
                }
                entries.push(entry);
            }
        }

        progress_bar.finish_with_message("done");
        entries
    }
}

enum DownloadResult {
    Success {
        local_path: String,
    },
    Skipped {
        reason: String,
    },
}

async fn download_one(
    client: &Client,
    candidate: &ImageCandidate,
    root: &Path,
    _compute_hash: bool,
) -> Result<DownloadResult> {
    let cards_dir = root.join(&candidate.set_code).join("cards");
    std::fs::create_dir_all(&cards_dir)
        .context("failed to create cards directory")?;

    let output_path = cards_dir.join(&candidate.filename);
    let relative_path = format!("{}/cards/{}", candidate.set_code, candidate.filename);

    // Skip if file already exists
    if output_path.exists() {
        return Ok(DownloadResult::Skipped {
            reason: format!("{} already exists", candidate.filename),
        });
    }

    // Retry with exponential backoff
    let mut attempt = 0u32;
    let max_retries = 3u32;
    let mut backoff = Duration::from_secs(1);

    let bytes = loop {
        attempt += 1;

        let response = client
            .get(&candidate.image_url)
            .send()
            .await
            .context("HTTP request failed")?;

        let status = response.status();

        if status.is_success() {
            // Validate content type
            let content_type = response
                .headers()
                .get("content-type")
                .and_then(|v| v.to_str().ok())
                .unwrap_or("");

            if !content_type.starts_with("image/") && !content_type.is_empty() {
                return Ok(DownloadResult::Skipped {
                    reason: format!("not an image: {}", content_type),
                });
            }

            let bytes = response.bytes().await.context("failed to read body")?;

            // Validate file size (>1KB)
            if bytes.len() < 1024 {
                return Ok(DownloadResult::Skipped {
                    reason: format!("too small: {} bytes", bytes.len()),
                });
            }

            break bytes;
        }

        // Retryable: 429, 5xx
        let is_retryable = status.as_u16() == 429 || status.is_server_error();

        if !is_retryable || attempt > max_retries {
            bail!("HTTP {} after {} attempts for {}", status, attempt, candidate.image_url);
        }

        tokio::time::sleep(backoff).await;
        backoff = (backoff * 2).min(Duration::from_secs(30));
    };

    // Write file
    std::fs::write(&output_path, &bytes)
        .with_context(|| format!("failed to write {}", output_path.display()))?;

    Ok(DownloadResult::Success {
        local_path: relative_path,
    })
}

fn compute_file_hash(path: &PathBuf) -> Option<String> {
    let data = std::fs::read(path).ok()?;
    let mut hasher = Sha256::new();
    hasher.update(&data);
    Some(format!("{:x}", hasher.finalize()))
}
