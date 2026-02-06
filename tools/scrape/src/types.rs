use serde::{Deserialize, Serialize};

/// A discovered image URL with metadata, before downloading.
#[derive(Debug, Clone)]
pub struct ImageCandidate {
    pub source: String,
    pub set_code: String,
    pub search_term: String,
    pub image_url: String,
    /// Suggested filename (e.g., "tca_ssr-007.jpg")
    pub filename: String,
}

/// A row in the R-compatible scrape log CSV.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ScrapeLogEntry {
    pub timestamp: String,
    pub source: String,
    pub set_code: String,
    pub search_term: String,
    pub image_url: String,
    pub local_path: String,
    pub success: String, // "TRUE" or "FALSE" for R compatibility
}

/// Parameters passed to a source's discover method.
#[derive(Debug, Clone)]
pub struct SearchRequest {
    pub set_code: String,
    pub english_terms: Vec<String>,
    pub chinese_terms: Vec<String>,
}

pub const VALID_SETS: &[&str] = &[
    "TF01", "TF02", "TF03", "TFKB01", "TFH01", "TFO01", "TF40Y", "TFEU01",
];
