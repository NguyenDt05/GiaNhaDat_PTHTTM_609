from __future__ import annotations

import hashlib
import re
import unicodedata
from pathlib import Path

import pandas as pd


NUMERIC_FEATURES = [
    "Area",
    "Frontage",
    "Access Road",
    "Floors",
    "Bedrooms",
    "Bathrooms",
]

CATEGORICAL_FEATURES = [
    "House direction",
    "Balcony direction",
    "Legal status",
    "Furniture state",
    "City",
    "District",
]

MODEL_FEATURES = NUMERIC_FEATURES + CATEGORICAL_FEATURES
TARGET = "Price"

CITY_MAPPING = {
    "TP Hồ Chí Minh": "Hồ Chí Minh",
    "TP. Hồ Chí Minh": "Hồ Chí Minh",
    "TP.Hồ Chí Minh": "Hồ Chí Minh",
    "TP HCM": "Hồ Chí Minh",
    "TP.HCM": "Hồ Chí Minh",
}


def file_sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def normalize_location(value: object) -> str:
    text = str(value).strip()
    text = re.sub(r"\.$", "", text).strip()
    return text or "Unknown"


def extract_location(address: object) -> tuple[str, str]:
    parts = [part.strip() for part in str(address).split(",") if part.strip()]
    city = parts[-1] if parts else "Unknown"
    district = parts[-2] if len(parts) >= 2 else "Unknown"
    city = CITY_MAPPING.get(normalize_location(city), normalize_location(city))
    return city, normalize_location(district)


def load_training_data(csv_path: Path) -> pd.DataFrame:
    frame = pd.read_csv(csv_path)
    required = {
        "Address",
        *NUMERIC_FEATURES,
        "House direction",
        "Balcony direction",
        "Legal status",
        "Furniture state",
        TARGET,
    }
    missing = sorted(required.difference(frame.columns))
    if missing:
        raise ValueError(f"Dataset is missing columns: {', '.join(missing)}")

    frame = frame.drop_duplicates().reset_index(drop=True).copy()
    locations = frame["Address"].map(extract_location)
    frame["City"] = locations.map(lambda value: value[0])
    frame["District"] = locations.map(lambda value: value[1])
    frame["Address Group"] = frame["Address"].astype(str).str.strip().str.casefold()
    return frame


def stable_code(prefix: str, label: str, parent: str = "") -> str:
    normalized = unicodedata.normalize("NFKD", label)
    ascii_label = "".join(char for char in normalized if not unicodedata.combining(char))
    slug = re.sub(r"[^A-Za-z0-9]+", "_", ascii_label).strip("_").upper()
    slug = slug[:32] or "UNKNOWN"
    suffix = hashlib.sha1(f"{parent}\0{label}".encode("utf-8")).hexdigest()[:8].upper()
    return f"{prefix}_{slug}_{suffix}"

