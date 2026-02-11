test_that("kt_sets returns tibble with expected columns", {
  result <- kt_sets()
  expect_s3_class(result, "tbl_df")
  expect_true("set_code" %in% names(result))
  expect_true("set_name_en" %in% names(result))
  expect_true("release_year" %in% names(result))
  expect_equal(nrow(result), 8)
})

test_that("kt_cards returns tibble with expected columns", {
  result <- kt_cards()
  expect_s3_class(result, "tbl_df")
  expected_cols <- c("card_id", "set_code", "rarity_code", "card_number",
                     "card_name_en", "character_name", "faction", "card_type")
  for (col in expected_cols) {
    expect_true(col %in% names(result), info = paste("Missing column:", col))
  }
  expect_gt(nrow(result), 0)
})

test_that("kt_cards filters by set", {
  result <- kt_cards(set = "TFEU01")
  expect_true(all(result$set_code == "TFEU01"))
  expect_equal(nrow(result), 254)
})

test_that("kt_cards filters by rarity", {
  result <- kt_cards(set = "TFEU01", rarity = "BP")
  expect_equal(nrow(result), 5)
  expect_true(all(result$rarity_code == "BP"))
})

test_that("kt_cards filters by faction", {
  result <- kt_cards(faction = "Autobot")
  expect_true(all(result$faction == "Autobot", na.rm = TRUE))
})

test_that("kt_cards filters by character", {
  result <- kt_cards(character = "Optimus Prime")
  expect_gt(nrow(result), 0)
  expect_true(all(grepl("Optimus Prime", result$character_name, ignore.case = TRUE),
                  na.rm = TRUE))
})

test_that("kt_cards supports vector set filter", {
  result <- kt_cards(set = c("TF01", "TF02"))
  expect_true(all(result$set_code %in% c("TF01", "TF02")))
  expect_equal(nrow(result), 124 + 125)
})

test_that("kt_cards supports vector rarity filter", {
  result <- kt_cards(set = "TFEU01", rarity = c("BP", "AR"))
  expect_true(all(result$rarity_code %in% c("BP", "AR")))
  expect_equal(nrow(result), 5 + 3)
})

test_that("kt_cards supports vector faction filter", {
  result <- kt_cards(set = "TFEU01", rarity = "BP",
                     faction = c("Autobot", "Decepticon"))
  expect_equal(nrow(result), 5)
})

test_that("kt_rarities supports vector set filter", {
  result <- kt_rarities(set = c("TF01", "TF02"))
  expect_true(all(result$set_code %in% c("TF01", "TF02")))
  expect_equal(nrow(result), 9 + 10)
})

test_that("kt_rarities returns tibble", {
  result <- kt_rarities()
  expect_s3_class(result, "tbl_df")
  expect_gt(nrow(result), 0)
})

test_that("kt_rarities filters by set", {
  result <- kt_rarities(set = "TFEU01")
  expect_true(all(result$set_code == "TFEU01"))
  expect_equal(nrow(result), 16)
})

test_that("kt_characters returns tibble", {
  result <- kt_characters()
  expect_s3_class(result, "tbl_df")
  expect_gt(nrow(result), 0)
  expect_true("character_name" %in% names(result))
})

test_that("kt_characters filters by faction", {
  result <- kt_characters(faction = "Autobot")
  expect_true(all(result$faction == "Autobot"))
})

test_that("kt_products returns tibble", {
  result <- kt_products()
  expect_s3_class(result, "tbl_df")
  expect_gt(nrow(result), 0)
})

test_that("kt_products filters by set", {
  result <- kt_products(set = "TFEU01")
  expect_true(all(result$set_code == "TFEU01"))
  expect_equal(nrow(result), 2)
})

test_that("kt_tbl returns lazy table", {
  skip_if_not_installed("dplyr")
  skip_if_not_installed("dbplyr")
  tbl_result <- kt_tbl("cards")
  expect_s3_class(tbl_result, "tbl_lazy")
})

test_that("kt_tbl rejects invalid table names", {
  expect_error(kt_tbl("nonexistent"), "Unknown table")
})

test_that("all sets have cards matching declared totals", {
  sets <- kt_sets()
  for (i in seq_len(nrow(sets))) {
    cards <- kt_cards(set = sets$set_code[i])
    expect_equal(
      nrow(cards), sets$total_cards[i],
      label = paste("Card count for set:", sets$set_code[i])
    )
  }
})

test_that("TF03 SSR contains confirmed combiner team data", {
  result <- kt_cards(set = "TF03", rarity = "SSR")
  expect_equal(nrow(result), 16)
  expect_true("Onslaught" %in% result$character_name)
  expect_true("Hot Spot" %in% result$character_name)
  expect_true("Sky Lynx" %in% result$character_name)
})

test_that("TFO01 has The Primes subset", {
  result <- kt_cards(set = "TFO01", rarity = "TP")
  expect_equal(nrow(result), 13)
  expect_true("Prima Prime" %in% result$character_name)
})

test_that("kt_sources returns tibble with expected columns", {
  result <- kt_sources()
  expect_s3_class(result, "tbl_df")
  expected_cols <- c("source_id", "set_code", "source_type", "source_url",
                     "local_path", "description", "access_date", "confidence",
                     "notes")
  for (col in expected_cols) {
    expect_true(col %in% names(result), info = paste("Missing column:", col))
  }
  expect_gt(nrow(result), 0)
})

test_that("kt_sources filters by set", {
  result <- kt_sources(set = "TFEU01")
  expect_true(all(result$set_code == "TFEU01"))
  expect_gt(nrow(result), 0)
})

test_that("kt_sources filters by type", {
  result <- kt_sources(type = "booklet")
  expect_true(all(result$source_type == "booklet"))
  expect_gt(nrow(result), 0)
})

test_that("all source set_codes exist in kt_sets", {
  sources <- kt_sources()
  sets <- kt_sets()
  invalid_sets <- setdiff(sources$set_code, sets$set_code)
  expect_equal(length(invalid_sets), 0,
               label = paste("Invalid set_codes in sources:",
                             paste(invalid_sets, collapse = ", ")))
})

test_that("kt_tbl works with sources table", {
  skip_if_not_installed("dplyr")
  skip_if_not_installed("dbplyr")
  tbl_result <- kt_tbl("sources")
  expect_s3_class(tbl_result, "tbl_lazy")
})

# --- Input validation tests ---

test_that("kt_cards rejects non-character set", {
  expect_error(kt_cards(set = 123), "character string")
})

test_that("kt_cards rejects non-character rarity", {
  expect_error(kt_cards(rarity = 1), "character string")
})

test_that("kt_cards rejects non-character character", {
  expect_error(kt_cards(character = TRUE), "character string")
})

test_that("kt_cards rejects non-character faction", {
  expect_error(kt_cards(faction = 42), "character string")
})

test_that("kt_rarities rejects non-character set", {
  expect_error(kt_rarities(set = 1), "character string")
})

test_that("kt_characters rejects non-character faction", {
  expect_error(kt_characters(faction = 1), "character string")
})

test_that("kt_products rejects non-character set", {
  expect_error(kt_products(set = 1), "character string")
})

test_that("kt_sources rejects non-character set", {
  expect_error(kt_sources(set = 1), "character string")
})

test_that("kt_sources rejects non-character type", {
  expect_error(kt_sources(type = 1), "character string")
})
