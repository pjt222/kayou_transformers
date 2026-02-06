# Vision Model Evaluation

## Model Tested

**qwen2.5vl:3b** (Qwen 2.5 Vision-Language, 3B parameters, 3.2 GB)

- Replaced `llama3.2-vision` (11B, ~7.9 GB) which was too large for the machine
- Strong multilingual support (relevant for Chinese text on TF01-TF03 cards)
- 125K context window

## Test Run: TF01 (2025-02-06)

40 images (20 eBay listing photos, 20 Trading Card Archives scans).

### Summary

| Metric | Count |
|--------|-------|
| Cards identified | 28 |
| Non-card images | 12 |
| Errors | 0 |
| Proposed moves | 8 |

### What Worked

- **Non-card detection**: Correctly identified 12 out of ~20 eBay listing photos as non-cards (packaging, box shots, promotional material, redemption codes). This is the most reliable capability.
- **Set identification (TCA scans)**: 15 out of 20 TCA card scans were correctly assigned to TF01. Clean card scans classify better than eBay photos.
- **Structured output compliance**: All 40 responses parsed successfully into the schema with zero errors.
- **Chinese text recognition**: Some notes returned in Chinese (e.g., image 28 returned a Chinese description), confirming the model reads Chinese card text.

### What Did Not Work

- **Character name hallucination**: The model confabulated non-Transformers names for images it couldn't parse: "Zarina", "Spider-Man", "Luke Skywalker", "Kim Kong", "Russ", "QINLU", "Skywalks". This is the most significant accuracy issue.
- **Rarity code accuracy**: Rarity codes were frequently wrong. Examples:
  - `tca_ar-008.jpg` (AR card) classified as BP
  - `tca_hr-003.jpg` (HR card) classified as BP
  - `tca_r-005.jpg` (R card) classified as BP-041
  - `tca_r-009.jpg` (R card) classified as HR-007
  - `tca_sr-005.jpg` (SR card) classified as LR
  - The model often reads the card number format but assigns wrong rarity codes
- **Degenerate output**: Image #6 triggered a long hallucinated output where the model invented non-existent set codes (TF05-TF09, TFH03-TFH04) and degenerated into repetitive text. This is a known small-model failure mode.
- **eBay listing misclassification**: Several eBay multi-card/listing photos were classified as cards from completely wrong franchises or sets (TFEU01, TFH01).
- **Cross-set confusion**: 8 cards proposed for moves, but some of these are likely false positives (e.g., a TF01 card classified as TFO01 or TF02).

### Accuracy Estimate

For clean card scans (TCA images):
- **Set detection**: ~75% correct (15/20)
- **Rarity detection**: ~30% correct (frequent misreads)
- **Character names**: ~40% plausible (often hallucinated)
- **is_card detection**: ~90% correct

For eBay listing photos:
- **is_card detection**: ~80% correct (most non-cards caught, some false positives)
- **Set/rarity/character**: Unreliable when image is not a clean single card

### Recommendations

1. **Use as a pre-filter, not ground truth**: The classifier is useful for separating cards from non-cards and suggesting set assignments, but all results need manual review.
2. **Rarity codes need a second pass**: Consider a focused rarity-only prompt with a cropped region of the rarity marking, or match against known rarity patterns in filenames.
3. **Character names need validation**: Cross-reference against the `kayoutf` character reference table to flag hallucinated names.
4. **Consider larger models for production**: `gemini-2.0-flash` or `claude-sonnet` via API would likely perform significantly better on rarity/character accuracy, at the cost of API fees.
5. **Image quality matters**: Clean scans (TCA) classify far better than eBay listing photos with backgrounds, watermarks, and multiple items.

## Model Comparison (Not Yet Tested)

| Model | Size | Cost | Expected Quality |
|-------|------|------|-----------------|
| `qwen2.5vl:3b` | 3.2 GB | Free (local) | Low-moderate accuracy, good for filtering |
| `llama3.2-vision` | 7.9 GB | Free (local) | Not tested (too large for machine) |
| `gemini-2.0-flash` | API | ~$0.001/image | Expected high accuracy |
| `claude-sonnet-4-5` | API | ~$0.01/image | Expected highest accuracy |
