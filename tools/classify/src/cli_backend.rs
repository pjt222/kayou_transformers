use std::path::Path;

use anyhow::{bail, Context, Result};
use async_trait::async_trait;
use tokio::sync::Semaphore;

use crate::classify::Classifier;
use crate::types::ClassificationResult;

pub struct CliClient {
    model: String,
    semaphore: Semaphore,
}

impl CliClient {
    pub fn new(model: String, concurrency: usize) -> Self {
        Self {
            model,
            semaphore: Semaphore::new(concurrency),
        }
    }
}

#[async_trait]
impl Classifier for CliClient {
    async fn classify(&self, image_path: &Path, system_prompt: &str) -> Result<ClassificationResult> {
        let _permit = self.semaphore.acquire().await?;

        let abs_path = std::fs::canonicalize(image_path)
            .with_context(|| format!("failed to resolve path {}", image_path.display()))?;

        let prompt = format!(
            "{}\n\n\
             Read the image at {} and classify this Kayou Transformers trading card image.\n\n\
             You MUST respond with ONLY a JSON object (no markdown fences, no explanation) with these exact fields:\n\
             {{\"is_card\": bool, \"set_code\": string, \"rarity_code\": string, \"character_name\": string, \
             \"card_number\": string, \"confidence\": string, \"notes\": string}}\n\n\
             set_code must be one of: TF01, TF02, TF03, TFKB01, TFH01, TFO01, TF40Y, TFEU01, UNKNOWN\n\
             confidence must be one of: high, medium, low",
            system_prompt,
            abs_path.display()
        );

        let output = tokio::process::Command::new("claude")
            .args([
                "-p",
                &prompt,
                "--allowedTools",
                "Read",
                "--model",
                &self.model,
                "--output-format",
                "text",
            ])
            .output()
            .await
            .context("failed to spawn claude CLI (is it in PATH?)")?;

        if !output.status.success() {
            let stderr = String::from_utf8_lossy(&output.stderr);
            bail!(
                "claude CLI exited with {}: {}",
                output.status,
                stderr.trim()
            );
        }

        let raw = String::from_utf8_lossy(&output.stdout);
        parse_cli_response(&raw)
    }
}

/// Parse the CLI response, stripping optional markdown fences.
fn parse_cli_response(raw: &str) -> Result<ClassificationResult> {
    let trimmed = raw.trim();

    // Strip markdown JSON fences if present
    let json_str = if trimmed.starts_with("```json") {
        trimmed
            .strip_prefix("```json")
            .and_then(|s| s.strip_suffix("```"))
            .unwrap_or(trimmed)
            .trim()
    } else if trimmed.starts_with("```") {
        trimmed
            .strip_prefix("```")
            .and_then(|s| s.strip_suffix("```"))
            .unwrap_or(trimmed)
            .trim()
    } else {
        trimmed
    };

    // Try to find a JSON object in the response if direct parse fails
    serde_json::from_str::<ClassificationResult>(json_str).or_else(|_| {
        // Look for first { ... last } as a fallback
        if let (Some(start), Some(end)) = (json_str.find('{'), json_str.rfind('}')) {
            let extracted = &json_str[start..=end];
            serde_json::from_str::<ClassificationResult>(extracted)
                .context("failed to parse extracted JSON from CLI response")
        } else {
            bail!("no JSON object found in CLI response: {}", &trimmed[..trimmed.len().min(200)])
        }
    })
}
