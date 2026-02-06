use serde::{Deserialize, Serialize};

// --- Claude API request types ---

#[derive(Serialize)]
pub struct ApiRequest {
    pub model: String,
    pub max_tokens: u32,
    pub system: String,
    pub messages: Vec<Message>,
    #[serde(rename = "output_config")]
    pub output_config: OutputConfig,
}

#[derive(Serialize)]
pub struct OutputConfig {
    pub format: OutputFormat,
}

#[derive(Serialize)]
pub struct OutputFormat {
    #[serde(rename = "type")]
    pub format_type: String,
    pub json_schema: JsonSchemaWrapper,
}

#[derive(Serialize)]
pub struct JsonSchemaWrapper {
    pub name: String,
    pub schema: serde_json::Value,
}

#[derive(Serialize)]
pub struct Message {
    pub role: String,
    pub content: Vec<ContentBlock>,
}

#[derive(Serialize)]
#[serde(tag = "type")]
pub enum ContentBlock {
    #[serde(rename = "image")]
    Image { source: ImageSource },
    #[serde(rename = "text")]
    Text { text: String },
}

#[derive(Serialize)]
pub struct ImageSource {
    #[serde(rename = "type")]
    pub source_type: String,
    pub media_type: String,
    pub data: String,
}

// --- Claude API response types ---

#[derive(Deserialize)]
pub struct ApiResponse {
    pub content: Vec<ResponseContentBlock>,
}

#[derive(Deserialize)]
#[serde(tag = "type")]
pub enum ResponseContentBlock {
    #[serde(rename = "json")]
    Json { json: serde_json::Value },
    #[serde(rename = "text")]
    Text { text: String },
}

// --- Classification result from API ---

#[derive(Deserialize, Debug, Clone)]
pub struct ClassificationResult {
    pub is_card: bool,
    pub set_code: String,
    #[serde(default)]
    pub rarity_code: Option<String>,
    #[serde(default)]
    pub character_name: Option<String>,
    #[serde(default)]
    pub card_number: Option<String>,
    pub confidence: String,
    #[serde(default)]
    pub notes: Option<String>,
}

// --- CSV row (R-compatible output) ---

#[derive(Debug, Clone)]
pub struct CsvRow {
    pub is_card: String,       // "TRUE", "FALSE", or "NA"
    pub set_code: String,
    pub rarity_code: String,   // value or "NA"
    pub character_name: String, // value or "NA"
    pub card_number: String,   // value or "NA"
    pub confidence: String,
    pub notes: String,
    pub file_path: String,
    pub filename: String,
    pub current_directory: String,
    pub needs_move: String,    // "TRUE" or "FALSE"
    pub move_to: String,       // set code or "NA"
}

impl CsvRow {
    pub fn from_classification(
        result: &ClassificationResult,
        file_path: &str,
        filename: &str,
        current_directory: &str,
    ) -> Self {
        let needs_move = result.is_card
            && result.set_code != current_directory
            && result.set_code != "UNKNOWN";
        let move_to = if needs_move {
            result.set_code.clone()
        } else {
            "NA".to_string()
        };

        CsvRow {
            is_card: if result.is_card { "TRUE" } else { "FALSE" }.to_string(),
            set_code: result.set_code.clone(),
            rarity_code: opt_to_r(&result.rarity_code),
            character_name: opt_to_r(&result.character_name),
            card_number: opt_to_r(&result.card_number),
            confidence: result.confidence.clone(),
            notes: result.notes.clone().unwrap_or_default(),
            file_path: file_path.to_string(),
            filename: filename.to_string(),
            current_directory: current_directory.to_string(),
            needs_move: if needs_move { "TRUE" } else { "FALSE" }.to_string(),
            move_to,
        }
    }

    pub fn error_row(file_path: &str, filename: &str, current_directory: &str, error: &str) -> Self {
        CsvRow {
            is_card: "NA".to_string(),
            set_code: "UNKNOWN".to_string(),
            rarity_code: "NA".to_string(),
            character_name: "NA".to_string(),
            card_number: "NA".to_string(),
            confidence: "low".to_string(),
            notes: format!("ERROR: {error}"),
            file_path: file_path.to_string(),
            filename: filename.to_string(),
            current_directory: current_directory.to_string(),
            needs_move: "FALSE".to_string(),
            move_to: "NA".to_string(),
        }
    }
}

/// Convert Option<String> to R-style NA or value.
/// Empty strings also become "NA".
fn opt_to_r(opt: &Option<String>) -> String {
    match opt {
        Some(s) if !s.is_empty() && s != "NA" => s.clone(),
        _ => "NA".to_string(),
    }
}
