"""Create a SQLite database from the downloaded Olist CSV files."""

from __future__ import annotations

import argparse
import csv
import sqlite3
from pathlib import Path


IMPORT_ORDER = [
    ("olist_customers_dataset.csv", "customers"),
    ("olist_sellers_dataset.csv", "sellers"),
    ("olist_products_dataset.csv", "products"),
    ("product_category_name_translation.csv", "category_translation"),
    ("olist_geolocation_dataset.csv", "geolocation"),
    ("olist_orders_dataset.csv", "orders"),
    ("olist_order_items_dataset.csv", "order_items"),
    ("olist_order_payments_dataset.csv", "order_payments"),
    ("olist_order_reviews_dataset.csv", "order_reviews"),
]


def import_csv(connection: sqlite3.Connection, csv_path: Path, table: str) -> int:
    # The category translation CSV contains a UTF-8 byte-order mark. utf-8-sig
    # removes it when present and behaves as normal UTF-8 for every other file.
    with csv_path.open("r", encoding="utf-8-sig", newline="") as handle:
        reader = csv.DictReader(handle)
        if not reader.fieldnames:
            raise ValueError(f"No header row found in {csv_path.name}")

        columns = reader.fieldnames
        placeholders = ", ".join("?" for _ in columns)
        quoted_columns = ", ".join(f'"{column}"' for column in columns)
        statement = f'INSERT INTO "{table}" ({quoted_columns}) VALUES ({placeholders})'

        batch: list[tuple[str | None, ...]] = []
        imported = 0
        for row in reader:
            batch.append(tuple(row[column] or None for column in columns))
            if len(batch) == 5_000:
                connection.executemany(statement, batch)
                imported += len(batch)
                batch.clear()

        if batch:
            connection.executemany(statement, batch)
            imported += len(batch)

    return imported


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--force",
        action="store_true",
        help="Replace an existing generated SQLite database.",
    )
    args = parser.parse_args()

    project_root = Path(__file__).resolve().parents[1]
    raw_dir = project_root / "data" / "raw"
    database_path = project_root / "data" / "processed" / "olist_ecommerce.db"
    schema_path = project_root / "sql" / "00_schema.sql"

    absent = [filename for filename, _ in IMPORT_ORDER if not (raw_dir / filename).exists()]
    if absent:
        raise FileNotFoundError(
            "Missing source data. Run `python scripts/download_data.py` first. "
            f"Missing: {', '.join(absent)}"
        )

    if database_path.exists():
        if not args.force:
            raise FileExistsError(
                f"{database_path.name} already exists. Re-run with --force to rebuild it."
            )
        database_path.unlink()

    database_path.parent.mkdir(parents=True, exist_ok=True)
    connection = sqlite3.connect(database_path)
    try:
        connection.execute("PRAGMA foreign_keys = ON")
        connection.executescript(schema_path.read_text(encoding="utf-8"))
        for filename, table in IMPORT_ORDER:
            count = import_csv(connection, raw_dir / filename, table)
            connection.commit()
            print(f"Imported {count:,} rows into {table}")

        connection.execute("ANALYZE")
        connection.commit()

        count_path = project_root / "data" / "processed" / "table_row_counts.csv"
        with count_path.open("w", encoding="utf-8", newline="") as handle:
            writer = csv.writer(handle)
            writer.writerow(["table_name", "row_count"])
            for _, table in IMPORT_ORDER:
                row_count = connection.execute(f'SELECT COUNT(*) FROM "{table}"').fetchone()[0]
                writer.writerow([table, row_count])
        print(f"Created {database_path}")
    finally:
        connection.close()


if __name__ == "__main__":
    main()
