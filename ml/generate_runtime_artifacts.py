from __future__ import annotations

import argparse
import json
import platform
from datetime import UTC, datetime
from pathlib import Path

import joblib
import pandas as pd
import sklearn

from ml.data import file_sha256, load_training_data, stable_code


OOD_RANGES = {
    "area_m2": {"low": 21.0, "high": 275.72, "unit": "m2"},
    "frontage_m": {"low": 3.0, "high": 29.36, "unit": "m"},
    "access_road_width_m": {"low": 2.0, "high": 40.0, "unit": "m"},
    "floors": {"low": 1, "high": 6},
    "bedrooms": {"low": 1, "high": 8},
    "bathrooms": {"low": 1, "high": 8},
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Generate API metadata and location catalog.")
    parser.add_argument("--model", type=Path, default=Path("house_price_random_forest.pkl"))
    parser.add_argument("--data", type=Path, default=Path("gianha.csv"))
    parser.add_argument("--output-dir", type=Path, default=Path("backend/model"))
    parser.add_argument(
        "--training-metadata",
        type=Path,
        help="Optional metadata emitted by ml.train for a production candidate.",
    )
    return parser.parse_args()


def build_catalog(frame: pd.DataFrame, model: object) -> dict[str, object]:
    encoder = model.named_steps["preprocessor"].named_transformers_["cat"].named_steps["onehot"]
    known_cities = {str(value) for value in encoder.categories_[4]}
    known_districts = {str(value) for value in encoder.categories_[5]}
    pairs = (
        frame[["City", "District"]]
        .drop_duplicates()
        .sort_values(["City", "District"], kind="stable")
    )
    provinces: list[dict[str, object]] = []
    for city, city_rows in pairs.groupby("City", sort=True):
        city = str(city)
        if city not in known_cities:
            continue
        province_code = stable_code("P", city)
        districts = []
        for district in city_rows["District"].astype(str).sort_values().unique():
            if district not in known_districts:
                continue
            districts.append(
                {
                    "code": stable_code("D", district, parent=city),
                    "label": district,
                    "model_value": district,
                }
            )
        if districts:
            provinces.append(
                {
                    "code": province_code,
                    "label": city,
                    "model_value": city,
                    "districts": districts,
                }
            )
    return {
        "generated_at": datetime.now(UTC).isoformat(),
        "code_system": "internal-stable-label-hash-v1",
        "provinces": provinces,
    }


def main() -> None:
    args = parse_args()
    model_path = args.model.resolve()
    data_path = args.data.resolve()
    output_dir = args.output_dir.resolve()
    output_dir.mkdir(parents=True, exist_ok=True)

    model = joblib.load(model_path)
    frame = load_training_data(data_path)
    catalog = build_catalog(frame, model)
    catalog_path = output_dir / "location_options.json"
    catalog_path.write_text(json.dumps(catalog, ensure_ascii=False, indent=2), encoding="utf-8")

    smoke_input = {
        "Area": 60.0,
        "Frontage": 5.0,
        "Access Road": 6.0,
        "House direction": "Đông - Nam",
        "Balcony direction": "Đông",
        "Floors": 3,
        "Bedrooms": 3,
        "Bathrooms": 2,
        "Legal status": "Have certificate",
        "Furniture state": "Full",
        "City": "Hà Nội",
        "District": "Hà Đông",
    }
    smoke_prediction = float(model.predict(pd.DataFrame([smoke_input]))[0])
    forest = model.named_steps["model"]
    training_metadata = {}
    if args.training_metadata:
        training_metadata = json.loads(
            args.training_metadata.resolve().read_text(encoding="utf-8")
        )
    metadata = {
        "model_version": training_metadata.get(
            "model_version", f"rf-{file_sha256(model_path)[:12]}"
        ),
        "generated_at": datetime.now(UTC).isoformat(),
        "artifact_filename": model_path.name,
        "artifact_sha256": file_sha256(model_path),
        "artifact_size_bytes": model_path.stat().st_size,
        "training_data_sha256": file_sha256(data_path),
        "python_version": platform.python_version(),
        "sklearn_version": sklearn.__version__,
        "evaluation_protocol": training_metadata.get(
            "evaluation_protocol",
            "legacy_random_split; production re-evaluation pending",
        ),
        "evaluation_rows": training_metadata.get("evaluation_rows"),
        "metrics": training_metadata.get(
            "metrics",
            {
                "mae_billion_vnd": 1.007,
                "rmse_billion_vnd": 1.3775,
                "mape_percent": 21.0177,
                "r2": 0.6108,
            },
        ),
        "n_estimators": len(forest.estimators_),
        "total_tree_nodes": sum(tree.tree_.node_count for tree in forest.estimators_),
        "maximum_tree_depth": max(tree.tree_.max_depth for tree in forest.estimators_),
        "parameters": forest.get_params(),
        "ood_ranges": OOD_RANGES,
        "smoke_test": {
            "input": smoke_input,
            "expected_prediction": smoke_prediction,
            "absolute_tolerance": 1e-9,
        },
    }
    metadata_path = output_dir / "metadata.json"
    metadata_path.write_text(json.dumps(metadata, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"Wrote {metadata_path}")
    print(f"Wrote {catalog_path}")
    print(f"Smoke prediction: {smoke_prediction:.6f} billion VND")


if __name__ == "__main__":
    main()
