# Result files

Each CSV is generated directly from its matching SQL file using `scripts/run_analysis.py`.

| Result file | SQL source | What it shows |
|---|---|---|
| `00_data_quality_summary.csv` | `01_data_quality.sql` | Row counts and core join checks |
| `01_monthly_sales.csv` | `02_monthly_sales_trend.sql` | Monthly delivered orders, item revenue, AOV, and month-over-month change |
| `02_customer_segments.csv` | `03_customer_segmentation.sql` | Customer counts, delivered orders, revenue, and recency by value/frequency segment |
| `03_top_sellers.csv` | `04_top_sellers.sql` | Top-20 seller ranking and cumulative revenue share |
| `04_category_performance.csv` | `05_category_performance.sql` | Category volume, item revenue, price, and operating signal |
| `05_seller_growth_gaps.csv` | `06_seller_growth_gaps.sql` | Seller-month diagnostic queue: orders rose while item revenue did not |
| `06_marketplace_health.csv` | `07_marketplace_health.sql` | Executive marketplace KPIs and definitions |

