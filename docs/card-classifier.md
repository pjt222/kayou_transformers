# Card Image Classifier

## Overview

`scripts/classify_card_images.R` uses a local vision model (via Ollama + ellmer) to classify trading card images by set, rarity, character, and image type.

## Usage

```bash
Rscript scripts/classify_card_images.R                    # classify all sets
Rscript scripts/classify_card_images.R TF01               # classify one set
Rscript scripts/classify_card_images.R --move             # classify + move misattributed files
Rscript scripts/classify_card_images.R --provider gemini  # use Gemini instead of Ollama
Rscript scripts/classify_card_images.R --provider claude  # use Claude instead of Ollama
Rscript scripts/classify_card_images.R --model gemma3:4b  # override default model
```

## Providers

| Provider | Default Model | Notes |
|----------|--------------|-------|
| `ollama` (default) | `qwen2.5vl:3b` | Free, local, ~3.2 GB VRAM |
| `gemini` | `gemini-2.0-flash` | Requires `GOOGLE_API_KEY` env var |
| `claude` | `claude-sonnet-4-5-20250929` | Requires `ANTHROPIC_API_KEY` env var |

## Prerequisites

- Ollama running locally: `ollama serve`
- Vision model pulled: `ollama pull qwen2.5vl:3b`
- R packages: `ellmer`, `kayoutf`

## Output

Results are saved to `scripts/classification_results.csv` with columns:

| Column | Description |
|--------|-------------|
| `is_card` | TRUE if single card front, FALSE if packaging/box/other |
| `set_code` | Detected set (TF01, TF02, ..., TFEU01, UNKNOWN) |
| `rarity_code` | Rarity printed on card (SR, SSR, UR, etc.) |
| `character_name` | English character name |
| `card_number` | Card number if visible |
| `confidence` | high / medium / low |
| `notes` | Model's reasoning |
| `needs_move` | TRUE if detected set differs from current directory |
| `move_to` | Target set directory if move needed |

## How It Works

1. Builds a system prompt from `kayoutf` reference data (all sets, rarities, visual differences)
2. Creates a fresh chat per image (avoids context accumulation)
3. Uses structured output (`type_object`) to enforce the classification schema
4. Compares detected set against the directory the image is currently in
5. Optionally moves misattributed images with `--move`
