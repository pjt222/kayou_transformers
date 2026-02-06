use std::time::Duration;

use anyhow::{bail, Context, Result};
use reqwest::Client;
use tokio::sync::Semaphore;

use crate::types::*;

const API_URL: &str = "https://api.anthropic.com/v1/messages";
const API_VERSION: &str = "2023-06-01";

pub struct ApiClient {
    client: Client,
    api_key: String,
    model: String,
    system_prompt: String,
    semaphore: Semaphore,
}

impl ApiClient {
    pub fn new(api_key: String, model: String, system_prompt: String, concurrency: usize) -> Self {
        let client = Client::builder()
            .timeout(Duration::from_secs(120))
            .build()
            .expect("failed to build HTTP client");

        Self {
            client,
            api_key,
            model,
            system_prompt,
            semaphore: Semaphore::new(concurrency),
        }
    }

    pub async fn classify_image(&self, image_base64: String, media_type: String) -> Result<ClassificationResult> {
        let _permit = self.semaphore.acquire().await?;

        let request = ApiRequest {
            model: self.model.clone(),
            max_tokens: 1024,
            system: self.system_prompt.clone(),
            messages: vec![Message {
                role: "user".to_string(),
                content: vec![
                    ContentBlock::Image {
                        source: ImageSource {
                            source_type: "base64".to_string(),
                            media_type,
                            data: image_base64,
                        },
                    },
                    ContentBlock::Text {
                        text: "Classify this trading card image.".to_string(),
                    },
                ],
            }],
            output_config: OutputConfig {
                format: OutputFormat {
                    format_type: "json_schema".to_string(),
                    json_schema: JsonSchemaWrapper {
                        name: "card_classification".to_string(),
                        schema: classification_schema(),
                    },
                },
            },
        };

        self.send_with_retry(&request).await
    }

    async fn send_with_retry(&self, request: &ApiRequest) -> Result<ClassificationResult> {
        let mut attempt = 0u32;
        let max_retries = 5u32;
        let mut backoff = Duration::from_secs(1);

        loop {
            attempt += 1;

            let response = self
                .client
                .post(API_URL)
                .header("x-api-key", &self.api_key)
                .header("anthropic-version", API_VERSION)
                .header("content-type", "application/json")
                .json(request)
                .send()
                .await
                .context("HTTP request failed")?;

            let status = response.status();

            if status.is_success() {
                let api_response: ApiResponse = response
                    .json()
                    .await
                    .context("failed to parse API response")?;

                return parse_classification(api_response);
            }

            // Non-retryable errors
            if status.as_u16() == 400 || status.as_u16() == 401 || status.as_u16() == 403 {
                let body = response.text().await.unwrap_or_default();
                bail!("API error {status}: {body}");
            }

            // Retryable: 429 (rate limit), 529 (overloaded), 5xx
            let is_retryable = status.as_u16() == 429
                || status.as_u16() == 529
                || status.is_server_error();

            if !is_retryable || attempt > max_retries {
                let body = response.text().await.unwrap_or_default();
                bail!("API error {status} after {attempt} attempts: {body}");
            }

            // Check retry-after header
            let retry_after = response
                .headers()
                .get("retry-after")
                .and_then(|v| v.to_str().ok())
                .and_then(|v| v.parse::<u64>().ok())
                .map(Duration::from_secs);

            let wait = retry_after.unwrap_or(backoff);
            tokio::time::sleep(wait).await;

            // Exponential backoff, capped at 60s
            backoff = (backoff * 2).min(Duration::from_secs(60));
        }
    }
}

fn parse_classification(response: ApiResponse) -> Result<ClassificationResult> {
    for block in response.content {
        match block {
            ResponseContentBlock::Json { json } => {
                let result: ClassificationResult =
                    serde_json::from_value(json).context("failed to parse classification JSON")?;
                return Ok(result);
            }
            ResponseContentBlock::Text { text } => {
                // Fallback: try parsing text as JSON
                if let Ok(result) = serde_json::from_str::<ClassificationResult>(&text) {
                    return Ok(result);
                }
            }
        }
    }
    bail!("no classification result in API response")
}

fn classification_schema() -> serde_json::Value {
    serde_json::json!({
        "type": "object",
        "properties": {
            "is_card": {
                "type": "boolean",
                "description": "TRUE if image shows a single trading card front, FALSE if packaging/box/multiple cards/back/other"
            },
            "set_code": {
                "type": "string",
                "enum": ["TF01", "TF02", "TF03", "TFKB01", "TFH01", "TFO01", "TF40Y", "TFEU01", "UNKNOWN"],
                "description": "Which set this card belongs to based on art style and text. Use UNKNOWN if uncertain."
            },
            "rarity_code": {
                "type": "string",
                "description": "Rarity code visible on card (e.g. SR, SSR, HR, UR, BP, XR, AR, R, SL, TP). Empty if not visible."
            },
            "character_name": {
                "type": "string",
                "description": "Character name depicted (English). Empty if not identifiable."
            },
            "card_number": {
                "type": "string",
                "description": "Card number if visible (e.g. '007', 'SR-005'). Empty if not visible."
            },
            "confidence": {
                "type": "string",
                "enum": ["high", "medium", "low"],
                "description": "Confidence in the overall classification"
            },
            "notes": {
                "type": "string",
                "description": "Brief notes on what is visible or why classification is uncertain"
            }
        },
        "required": ["is_card", "set_code", "rarity_code", "character_name", "card_number", "confidence", "notes"],
        "additionalProperties": false
    })
}
