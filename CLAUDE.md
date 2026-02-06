# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

This is a reference/data repository for **Kayou Transformers** trading card game products (能量临界典藏卡 / Energon Universe). It stores product booklet scans (PDF) that document card checklists, rarity tiers, and set compositions for each release.

This is **not** a code project — there are no build steps, tests, or linting.

## Structure

Each top-level directory represents a product set identified by its set code:

- `TFEU01/` — First Transformers Energon Universe release. Contains two booklet PDFs covering the **超量包** (Super Quantum Pack, 254 cards across 16 rarities) and the **精英包** (Elite Pack, 239 cards across 14 rarities).

## Card Rarity Tiers (TFEU01)

From the booklets, the rarity hierarchy (highest to lowest):

| Rarity | Chinese Name | English Approximation | Notes |
|--------|-------------|----------------------|-------|
| BP | Hit Pack限定 | Box-Pull exclusive | 5 cards, pack-hit exclusive |
| XR☆ | 暗金辉迪卡 | Dark Gold XR | 9 cards, super quantum pack exclusive art |
| XR☆ | 臻红辉迪卡 | Red XR | 4 cards, limited edition |
| XR | 辉迪卡 | XR | 9 cards |
| OR☆ | 集结卡☆ | Assembly Star | 8 cards, limited 380 copies |
| OR | 集结卡 | Assembly | 8 cards, unique card face per pack type |
| WR | 战役卡 | War | 6 cards, unique card face per pack type |
| LR☆ | 群英卡☆ | Heroes Star | 12 cards, more variants |
| LR | 群英卡 | Heroes | 12 cards |
| UR☆ | 封面变体卡☆ | Cover Variant Star | 20 cards, pack-exclusive art |
| UR | 封面变体卡 | Cover Variant | 20 cards |
| SR | 蒙太奇卡 | Montage | 36 cards |
| SSR | 漫画破格卡 | Comic Breakout | 20 cards |
| HR | 立体阵营卡 | 3D Faction | 3 cards (shaped/die-cut) |
| AR | 肖像卡 | Portrait | 3 cards |
| 兑换卡 | 连拼卡/皮卡册兑换卡 | Redemption cards | Puzzle cards and binder redemptions |

## Planned: kayoutf R Package

See `CONTINUE_HERE.md` for the full implementation plan to build an R package (`kayoutf`) with a DuckDB/Parquet-backed database of all Kayou Transformers cards across all known sets (TF01, TF02, TF03, TFH01, TFO01, TF40Y, TFEU01).

## Conventions

- Set directories use the set code as the folder name (e.g., `TFEU01`)
- Booklet scans are named `booklet_1.pdf`, `booklet_2.pdf`, etc.
- Future sets should follow the same naming pattern
- Keep PDF files at original scan quality for reference accuracy
