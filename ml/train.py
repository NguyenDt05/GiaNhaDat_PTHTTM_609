from __future__ import annotations

import argparse
import json
import platform
import time
from datetime import UTC, datetime
from pathlib import Path

import joblib
import numpy as np
import pandas as pd
import sklearn
from sklearn.metrics import (
    mean_absolute_error,
    mean_absolute_percentage_error,
    mean_squared_error,
    r2_score,
)
from sklearn.model_selection import GroupShuffleSplit

from ml.data import MODEL_FEATURES, TARGET, file_sha256, load_training_data
from ml.pipeline import build_pipeline


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Train the production house-price model.")
    parser.add_argument("--data", type=Path, default=Path("gianha.csv"))
    parser.add_argument(
        "--output", type=Path, default=Path("artifacts/house_price_random_forest_v2.joblib")
    )
    parser.add_argument("--metadata", type=Path, default=Path("artifacts/model_v2_metadata.json"))
    parser.add_argument("--n-estimators", type=int, default=100)
    parser.add_argument("--max-depth", type=int, default=24)
    parser.add_argument("--min-samples-leaf", type=int, default=2)
    return parser.parse_args()


def regression_metrics(actual: pd.Series, predicted: np.ndarray) -> dict[str, float]:
    mse = mean_squared_error(actual, predicted)
    return {
        "mae_billion_vnd": round(float(mean_absolute_error(actual, predicted)), 6),
        "mse": round(float(mse), 6),
        "rmse_billion_vnd": round(float(np.sqrt(mse)), 6),
        "mape_percent": round(float(mean_absolute_percentage_error(actual, predicted) * 100), 6),
        "r2": round(float(r2_score(actual, predicted)), 6),
    }


def main() -> None:
    args = parse_args()
    frame = load_training_data(args.data.resolve())
    splitter = GroupShuffleSplit(n_splits=1, test_size=0.2, random_state=42)
    train_index, test_index = next(
        splitter.split(frame[MODEL_FEATURES], frame[TARGET], groups=frame["Address Group"])
    )
    train_frame = frame.iloc[train_index]
    test_frame = frame.iloc[test_index]

    model = build_pipeline(
        n_estimators=args.n_estimators,
        max_depth=args.max_depth,
        min_samples_leaf=args.min_samples_leaf,
    )
    started = time.perf_counter()
    model.fit(train_frame[MODEL_FEATURES], train_frame[TARGET])
    train_seconds = time.perf_counter() - started
    metrics = regression_metrics(
        test_frame[TARGET], model.predict(test_frame[MODEL_FEATURES])
    )

    # Refit the selected configuration on all data for the deployable artifact.
    model.fit(frame[MODEL_FEATURES], frame[TARGET])
    model.named_steps["model"].n_jobs = 1

    args.output.parent.mkdir(parents=True, exist_ok=True)
    joblib.dump(model, args.output, compress=3)
    forest = model.named_steps["model"]
    metadata = {
        "model_version": f"rf-v2-{datetime.now(UTC).strftime('%Y%m%dT%H%M%SZ')}",
        "created_at": datetime.now(UTC).isoformat(),
        "artifact_sha256": file_sha256(args.output),
        "artifact_size_bytes": args.output.stat().st_size,
        "training_data_sha256": file_sha256(args.data.resolve()),
        "training_rows": len(frame),
        "evaluation_protocol": "group_shuffle_split_by_normalized_address_80_20",
        "evaluation_rows": len(test_frame),
        "metrics": metrics,
        "training_seconds_before_full_refit": round(train_seconds, 3),
        "python_version": platform.python_version(),
        "sklearn_version": sklearn.__version__,
        "parameters": forest.get_params(),
        "total_tree_nodes": sum(tree.tree_.node_count for tree in forest.estimators_),
        "maximum_tree_depth": max(tree.tree_.max_depth for tree in forest.estimators_),
    }
    args.metadata.parent.mkdir(parents=True, exist_ok=True)
    args.metadata.write_text(json.dumps(metadata, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps(metadata, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()

