use crate::types::SearchRequest;

/// Build search requests for each set code.
pub fn search_requests_for_set(set_code: &str) -> SearchRequest {
    let (english_terms, chinese_terms) = match set_code {
        "TF01" => (
            vec![
                "kayou transformers TF01".into(),
                "kayou transformers series 1".into(),
            ],
            vec![
                "卡游 变形金刚 一弹".into(),
                "卡游 变形金刚 TF01".into(),
            ],
        ),
        "TF02" => (
            vec![
                "kayou transformers TF02".into(),
                "kayou transformers series 2".into(),
            ],
            vec![
                "卡游 变形金刚 二弹".into(),
                "卡游 变形金刚 TF02".into(),
            ],
        ),
        "TF03" => (
            vec![
                "kayou transformers TF03".into(),
                "kayou transformers series 3".into(),
            ],
            vec![
                "卡游 变形金刚 三弹".into(),
                "卡游 变形金刚 TF03".into(),
            ],
        ),
        "TFKB01" => (
            vec![
                "kayou transformers TFKB01".into(),
                "kayou transformers series B ACG".into(),
                "kayou transformers movie card SR".into(),
                "kayou transformers drift crosshairs barricade card".into(),
            ],
            vec![
                "卡游 变形金刚 TFKB01".into(),
                "卡游 变形金刚 赛伯坦 B系列 电影卡".into(),
                "卡游 变形金刚 二弹 电影 SR HR AR".into(),
            ],
        ),
        "TFH01" => (
            vec![
                "kayou transformers TFH01".into(),
                "kayou transformers headmasters".into(),
            ],
            vec![
                "卡游 变形金刚 头领战士".into(),
                "卡游 变形金刚 TFH01".into(),
            ],
        ),
        "TFO01" => (
            vec![
                "kayou transformers TFO01".into(),
                "kayou transformers one".into(),
            ],
            vec![
                "卡游 变形金刚 起源".into(),
                "卡游 变形金刚 TFO01".into(),
            ],
        ),
        "TF40Y" => (
            vec![
                "kayou transformers TF40Y".into(),
                "kayou transformers 40th anniversary".into(),
            ],
            vec![
                "卡游 变形金刚 40周年".into(),
                "卡游 变形金刚 TF40Y".into(),
            ],
        ),
        "TFEU01" => (
            vec![
                "kayou transformers TFEU01".into(),
                "kayou transformers energon universe".into(),
            ],
            vec![
                "卡游 变形金刚 能量临界".into(),
                "卡游 变形金刚 TFEU01".into(),
            ],
        ),
        _ => (vec![], vec![]),
    };

    SearchRequest {
        set_code: set_code.to_string(),
        english_terms,
        chinese_terms,
    }
}

/// Default rate limit delays per source (seconds).
#[allow(dead_code)]
pub fn default_delay(source_name: &str) -> f64 {
    match source_name {
        "tca" => 2.0,
        "ebay" => 2.0,
        "google" => 1.0,
        "reddit" => 1.0,
        "forum" => 2.0,
        "direct" => 0.5,
        _ => 2.0,
    }
}

/// Known forum thread URLs for review content.
pub fn forum_threads() -> Vec<(&'static str, &'static str, &'static str)> {
    // (set_code, thread_url, domain_label)
    vec![
        ("TFO01", "https://www.tfw2005.com/boards/threads/kayou-transformers-one-trading-cards.1258741/", "tfw2005"),
        ("TF40Y", "https://www.tfw2005.com/boards/threads/kayou-transformers-40th-anniversary-trading-cards.1256892/", "tfw2005"),
        ("TFEU01", "https://www.tfw2005.com/boards/threads/kayou-transformers-energon-universe-trading-cards.1261543/", "tfw2005"),
        ("TF01", "https://www.seibertron.com/transformers/news/kayou-transformers-trading-cards-series-1/47891/", "seibertron"),
    ]
}
