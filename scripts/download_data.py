"""Download the public Olist dataset without committing source files to Git."""

from __future__ import annotations

import io
import sys
import urllib.request
import zipfile
from pathlib import Path


DATASET_URL = "https://www.kaggle.com/api/v1/datasets/download/olistbr/brazilian-ecommerce"
REQUIRED_FILES = {
    "olist_customers_dataset.csv",
    "olist_geolocation_dataset.csv",
    "olist_order_items_dataset.csv",
    "olist_order_payments_dataset.csv",
    "olist_order_reviews_dataset.csv",
    "olist_orders_dataset.csv",
    "olist_products_dataset.csv",
    "olist_sellers_dataset.csv",
    "product_category_name_translation.csv",
}


def main() -> None:
    project_root = Path(__file__).resolve().parents[1]
    raw_dir = project_root / "data" / "raw"
    raw_dir.mkdir(parents=True, exist_ok=True)

    missing = REQUIRED_FILES - {path.name for path in raw_dir.glob("*.csv")}
    if not missing:
        print("All required Olist CSV files are already present.")
        return

    print("Downloading the public Olist dataset from Kaggle...")
    request = urllib.request.Request(
        DATASET_URL,
        headers={"User-Agent": "Mozilla/5.0 (portfolio-project-download)"},
    )
    with urllib.request.urlopen(request, timeout=120) as response:
        archive_bytes = response.read()

    with zipfile.ZipFile(io.BytesIO(archive_bytes)) as archive:
        archive_files = {Path(name).name: name for name in archive.namelist()}
        absent = REQUIRED_FILES - set(archive_files)
        if absent:
            raise RuntimeError(f"Archive is missing expected files: {sorted(absent)}")

        for filename in sorted(REQUIRED_FILES):
            destination = raw_dir / filename
            with archive.open(archive_files[filename]) as source, destination.open("wb") as target:
                target.write(source.read())
            print(f"Saved {filename}")

    print(f"Download complete: {raw_dir}")


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        print(f"Download failed: {error}", file=sys.stderr)
        raise

