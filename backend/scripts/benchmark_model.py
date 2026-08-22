from __future__ import annotations

import argparse
import json
import statistics
import time
from pathlib import Path

import joblib
import pandas as pd
import psutil


def percentile(values: list[float], percentage: float) -> float:
    ordered = sorted(values)
    index = min(len(ordered) - 1, round((len(ordered) - 1) * percentage))
    return ordered[index]


def main() -> None:
    parser = argparse.ArgumentParser(description="Benchmark local model loading and inference.")
    parser.add_argument(
        "--model",
        type=Path,
        default=Path("artifacts/house_price_random_forest_v2.joblib"),
    )
    parser.add_argument(
        "--metadata", type=Path, default=Path("backend/model/metadata.json")
    )
    parser.add_argument("--iterations", type=int, default=200)
    args = parser.parse_args()

    process = psutil.Process()
    rss_before = process.memory_info().rss
    started = time.perf_counter()
    model = joblib.load(args.model)
    model.named_steps["model"].n_jobs = 1
    load_seconds = time.perf_counter() - started
    rss_after = process.memory_info().rss

    metadata = json.loads(args.metadata.read_text(encoding="utf-8"))
    frame = pd.DataFrame([metadata["smoke_test"]["input"]])
    for _ in range(10):
        model.predict(frame)

    durations = []
    for _ in range(args.iterations):
        started = time.perf_counter()
        model.predict(frame)
        durations.append((time.perf_counter() - started) * 1000)

    result = {
        "artifact": str(args.model),
        "artifact_size_mb": round(args.model.stat().st_size / 1048576, 2),
        "load_seconds": round(load_seconds, 4),
        "rss_before_mb": round(rss_before / 1048576, 2),
        "rss_after_mb": round(rss_after / 1048576, 2),
        "rss_delta_mb": round((rss_after - rss_before) / 1048576, 2),
        "iterations": args.iterations,
        "latency_ms": {
            "mean": round(statistics.mean(durations), 4),
            "p50": round(percentile(durations, 0.50), 4),
            "p95": round(percentile(durations, 0.95), 4),
            "p99": round(percentile(durations, 0.99), 4),
            "max": round(max(durations), 4),
        },
    }
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()

