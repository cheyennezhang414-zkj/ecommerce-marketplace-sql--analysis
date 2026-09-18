"""Run the portfolio SQL files and export each result set as a CSV."""

from __future__ import annotations

import csv
import sqlite3
from pathlib import Path


ANALYSES = [
    ("01_data_quality.sql", "00_data_quality_summary.csv"),
    ("02_monthly_sales_trend.sql", "01_monthly_sales.csv"),
    ("03_customer_segmentation.sql", "02_customer_segments.csv"),
    ("04_top_sellers.sql", "03_top_sellers.csv"),
    ("05_category_performance.sql", "04_category_performance.csv"),
    ("06_seller_growth_gaps.sql", "05_seller_growth_gaps.csv"),
    ("07_marketplace_health.sql", "06_marketplace_health.csv"),
]


def export_query(connection: sqlite3.Connection, sql_path: Path, output_path: Path) -> int:
    cursor = connection.execute(sql_path.read_text(encoding="utf-8"))
    columns = [column[0] for column in cursor.description]
    rows = cursor.fetchall()

    with output_path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.writer(handle)
        writer.writerow(columns)
        writer.writerows(rows)
    return len(rows)


def main() -> None:
    project_root = Path(__file__).resolve().parents[1]
    database_path = project_root / "data" / "processed" / "olist_ecommerce.db"
    if not database_path.exists():
        raise FileNotFoundError(
            "Database not found. Run `python scripts/build_database.py --force` first."
        )

    results_dir = project_root / "results"
    results_dir.mkdir(exist_ok=True)
    connection = sqlite3.connect(database_path)
    try:
        for sql_filename, output_filename in ANALYSES:
            row_count = export_query(
                connection,
                project_root / "sql" / sql_filename,
                results_dir / output_filename,
            )
            print(f"Exported {row_count:,} rows to results/{output_filename}")
    finally:
        connection.close()


if __name__ == "__main__":
    main()

