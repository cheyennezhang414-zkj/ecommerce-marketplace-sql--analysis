# Marketplace Seller & Customer Analytics with SQL

An end-to-end SQL portfolio project that analyzes customer behavior, seller performance, product categories, and fulfillment signals in a multi-sided e-commerce marketplace.

> **Interview positioning:** This is an independent analysis of the public **Olist Brazilian E-Commerce Dataset**. It is **not JD data** and does not make claims about JD's performance. I use a JD-style marketplace business-analysis and merchant-operations lens to frame transferable questions: how to grow quality merchants, improve customer retention, protect key categories, and monitor fulfillment experience.

## Executive summary

The analysis uses **96,478 delivered orders** between 2016-09-15 and 2018-08-29. “Item revenue” is calculated as the sum of delivered `order_items.price`; it is a transparent revenue proxy in BRL, not a statement of marketplace GMV or profit.

| Finding | Evidence | Business implication |
|---|---:|---|
| Retention is the clearest growth opportunity | Only **3.0%** of unique customers placed at least two delivered orders; high-value one-time buyers contributed **BRL 8.14M** | Prioritize post-purchase reactivation before spending only on acquisition. |
| Category concentration needs focused operating attention | Health & Beauty led item revenue at **BRL 1.23M (9.33%)**; the five largest categories made up **39.83%** | Protect availability, assortment, and merchant quality in high-value categories. |
| Revenue is distributed beyond the largest sellers | The top 10 sellers generated **13.27%** of delivered item revenue | Support strategic sellers, while scaling repeatable operating playbooks for the long tail. |
| Fulfillment is material to customer experience | **8.11%** of dated delivered orders arrived after the estimated date | Segment late deliveries by merchant, category, and region before setting seller service interventions. |

Read the evidence and recommendations in [insights/business_recommendations.md](insights/business_recommendations.md).

## Business questions

| Area | Question | Output |
|---|---|---|
| Data quality | Are the core order, product, seller, and customer joins complete? | [00_data_quality_summary.csv](results/00_data_quality_summary.csv) |
| Customer analytics | How have delivered orders and item revenue changed by month? Which customer segments create value? | [01_monthly_sales.csv](results/01_monthly_sales.csv), [02_customer_segments.csv](results/02_customer_segments.csv) |
| Seller analytics | Who are the leading sellers, and how concentrated is marketplace revenue? Which sellers gained orders but not revenue? | [03_top_sellers.csv](results/03_top_sellers.csv), [05_seller_growth_gaps.csv](results/05_seller_growth_gaps.csv) |
| Product analytics | Which categories lead on revenue and volume? Where could bundles or cross-sell improve basket value? | [04_category_performance.csv](results/04_category_performance.csv) |
| Business health | What are the marketplace-level customer, seller, and delivery KPIs? | [06_marketplace_health.csv](results/06_marketplace_health.csv) |

## Dataset and scope

- **Source:** [Brazilian E-Commerce Public Dataset by Olist on Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
- **Coverage:** roughly 100,000 orders made from 2016 to 2018 across multiple Brazilian marketplaces.
- **Grain:** one row in `order_items` is one product line within an order. All revenue queries aggregate to the **order** or **seller/category** grain before calculating metrics, which avoids counting multi-item orders as multiple orders.
- **Data handling:** raw CSVs and the generated SQLite database are intentionally ignored by Git. The project includes reproducible scripts that download and rebuild them. Use the source under Kaggle's applicable terms.

### Data model

```text
customers ──< orders ──< order_items >── products ──< category_translation
                   │            │
                   │            └────────> sellers
                   ├──< order_payments
                   └──< order_reviews
```

The `geolocation` table is loaded for future geographic analysis but is not used in the core outputs.

### Metric definitions

| Metric | Definition |
|---|---|
| Delivered order | `orders.order_status = 'delivered'` |
| Item revenue (BRL) | `SUM(order_items.price)` on delivered orders; excludes freight, discounts, fees, and profit |
| Customer | `customer_unique_id`, not `customer_id`; the latter is unique to an order and would overstate repeat buyers |
| Repeat customer rate | Unique customers with two or more delivered orders / all unique customers with a delivered order |
| Late delivery rate | Actual customer delivery date is later than estimated delivery date, among dated delivered orders |
| High-value customer | Customer whose delivered item revenue is at or above the delivered-customer average in this dataset |

## SQL methods demonstrated

| Technique | Why it is used | Example |
|---|---|---|
| CTEs (`WITH`) | Break a business question into auditable steps, such as item lines → order value → customer metrics | [03_customer_segmentation.sql](sql/03_customer_segmentation.sql) |
| `LAG()` | Compare a seller or marketplace month with its prior month | [02_monthly_sales_trend.sql](sql/02_monthly_sales_trend.sql), [06_seller_growth_gaps.sql](sql/06_seller_growth_gaps.sql) |
| `RANK()` + cumulative `SUM() OVER()` | Rank sellers and quantify revenue concentration without a separate calculation | [04_top_sellers.sql](sql/04_top_sellers.sql) |
| `ROW_NUMBER()` | Create an unambiguous priority order for merchant diagnostic cases | [06_seller_growth_gaps.sql](sql/06_seller_growth_gaps.sql) |
| `NTILE()` | Identify high-volume, low-price category opportunities with transparent quartile rules | [05_category_performance.sql](sql/05_category_performance.sql) |

## Repository structure

```text
olist-marketplace-sql-analysis/
├── data/
│   ├── raw/                     # Downloaded CSVs (ignored by Git)
│   └── processed/               # Generated SQLite database (ignored by Git)
├── docs/
│   └── interview_talk_track_zh.md
├── insights/
│   └── business_recommendations.md
├── results/                     # Versioned CSV outputs from the SQL analyses
├── scripts/
│   ├── download_data.py
│   ├── build_database.py
│   └── run_analysis.py
└── sql/
    ├── 00_schema.sql
    ├── 01_data_quality.sql
    ├── 02_monthly_sales_trend.sql
    ├── 03_customer_segmentation.sql
    ├── 04_top_sellers.sql
    ├── 05_category_performance.sql
    ├── 06_seller_growth_gaps.sql
    └── 07_marketplace_health.sql
```

## Reproduce the analysis

The project uses Python's standard library and SQLite only. No package installation is required.

**Windows (Python launcher):**

```powershell
py -3 scripts/download_data.py
py -3 scripts/build_database.py --force
py -3 scripts/run_analysis.py
```

**macOS/Linux:**

```bash
python3 scripts/download_data.py
python3 scripts/build_database.py --force
python3 scripts/run_analysis.py
```

The analysis has been run against the source snapshot and the resulting CSVs are checked into `results/`. Re-running the pipeline replaces only the local generated database and refreshes those outputs.

## Limitations and responsible interpretation

- The dataset is historical and Brazilian; it is not a benchmark for current JD, Olist, or any other marketplace performance.
- No traffic, impression, margin, promotion, inventory, or platform-fee data is available. The project therefore does not claim conversion, profitability, or causal uplift.
- Seller and customer identifiers are opaque source IDs. Recommendations describe operating hypotheses to validate, not actions based on personally identifiable information.
- The final observed purchase month is treated cautiously in time-series interpretation because source coverage ends on 2018-08-29.

## Interview support

Use [docs/interview_talk_track_zh.md](docs/interview_talk_track_zh.md) for a 60-second Chinese project introduction, likely follow-up questions, and a clear explanation of why each SQL design choice matters.

