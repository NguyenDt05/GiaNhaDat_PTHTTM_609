from __future__ import annotations

import hashlib
import json
import logging
import threading
import uuid
from dataclasses import dataclass
from pathlib import Path
from typing import Any

import joblib
import pandas as pd

from backend.app.schemas.prediction import (
    EstimatedPrice,
    FurnitureState,
    LegalStatus,
    ModelReference,
    PredictionRequest,
    PredictionResponse,
    WarningItem,
)


LOGGER = logging.getLogger(__name__)

DIRECTION_TO_MODEL = {
    "NORTH": "Bắc",
    "NORTHEAST": "Đông - Bắc",
    "EAST": "Đông",
    "SOUTHEAST": "Đông - Nam",
    "SOUTH": "Nam",
    "SOUTHWEST": "Tây - Nam",
    "WEST": "Tây",
    "NORTHWEST": "Tây - Bắc",
}

LEGAL_TO_MODEL = {
    LegalStatus.CERTIFICATE: "Have certificate",
    LegalStatus.SALE_CONTRACT: "Sale contract",
}

FURNITURE_TO_MODEL = {
    FurnitureState.FULL: "Full",
    FurnitureState.BASIC: "Basic",
}


class ModelNotReadyError(RuntimeError):
    pass


class InvalidLocationError(ValueError):
    pass


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


@dataclass(frozen=True)
class Location:
    province_label: str
    district_label: str


class LocationCatalog:
    def __init__(self, payload: dict[str, Any]):
        self.payload = payload
        self._provinces: dict[str, dict[str, Any]] = {}
        self._districts: dict[tuple[str, str], dict[str, Any]] = {}
        for province in payload.get("provinces", []):
            self._provinces[province["code"]] = province
            for district in province.get("districts", []):
                self._districts[(province["code"], district["code"])] = district

    @classmethod
    def from_path(cls, path: Path) -> "LocationCatalog":
        return cls(json.loads(path.read_text(encoding="utf-8")))

    def resolve(self, province_code: str, district_code: str) -> Location:
        province = self._provinces.get(province_code)
        if province is None:
            raise InvalidLocationError("Mã tỉnh/thành không được hỗ trợ.")
        district = self._districts.get((province_code, district_code))
        if district is None:
            raise InvalidLocationError("Quận/huyện không thuộc tỉnh/thành đã chọn.")
        return Location(
            province_label=province["model_value"],
            district_label=district["model_value"],
        )


class ModelService:
    def __init__(self) -> None:
        self._model: Any | None = None
        self._metadata: dict[str, Any] = {}
        self._catalog: LocationCatalog | None = None
        self._error: str | None = None
        self._lock = threading.RLock()

    @property
    def ready(self) -> bool:
        return self._model is not None and self._catalog is not None and self._error is None

    @property
    def error(self) -> str | None:
        return self._error

    @property
    def metadata(self) -> dict[str, Any]:
        return self._metadata

    @property
    def options(self) -> dict[str, Any]:
        if self._catalog is None:
            raise ModelNotReadyError("Danh mục địa điểm chưa sẵn sàng.")
        return self._catalog.payload

    def load(self, model_path: Path, metadata_path: Path, options_path: Path) -> None:
        with self._lock:
            try:
                metadata = json.loads(metadata_path.read_text(encoding="utf-8"))
                actual_hash = _sha256(model_path)
                expected_hash = metadata.get("artifact_sha256")
                if expected_hash and actual_hash != expected_hash:
                    raise ValueError("Model checksum does not match metadata")

                model = joblib.load(model_path)
                if not hasattr(model, "named_steps") or "model" not in model.named_steps:
                    raise ValueError("Unsupported model artifact")
                model.named_steps["model"].n_jobs = 1

                smoke = metadata["smoke_test"]
                prediction = float(model.predict(pd.DataFrame([smoke["input"]]))[0])
                tolerance = float(smoke.get("absolute_tolerance", 1e-9))
                if abs(prediction - float(smoke["expected_prediction"])) > tolerance:
                    raise ValueError("Model smoke prediction does not match metadata")

                self._model = model
                self._metadata = metadata
                self._catalog = LocationCatalog.from_path(options_path)
                self._error = None
                LOGGER.info("Model %s loaded and verified", metadata["model_version"])
            except Exception as exc:
                self._model = None
                self._catalog = None
                self._error = str(exc)
                LOGGER.exception("Model initialization failed")

    def predict(self, request: PredictionRequest, request_id: str) -> PredictionResponse:
        if not self.ready or self._model is None or self._catalog is None:
            raise ModelNotReadyError("Mô hình chưa sẵn sàng.")

        location = self._catalog.resolve(request.province_code, request.district_code)
        row = {
            "Area": request.area_m2,
            "Frontage": request.frontage_m,
            "Access Road": request.access_road_width_m,
            "House direction": (
                DIRECTION_TO_MODEL[request.house_direction.value]
                if request.house_direction
                else None
            ),
            "Balcony direction": (
                DIRECTION_TO_MODEL[request.balcony_direction.value]
                if request.balcony_direction
                else None
            ),
            "Floors": request.floors,
            "Bedrooms": request.bedrooms,
            "Bathrooms": request.bathrooms,
            "Legal status": LEGAL_TO_MODEL.get(request.legal_status),
            "Furniture state": FURNITURE_TO_MODEL.get(request.furniture_state),
            "City": location.province_label,
            "District": location.district_label,
        }
        prediction = float(self._model.predict(pd.DataFrame([row]))[0])
        warnings = self._warnings(request)
        return PredictionResponse(
            prediction_id=str(uuid.uuid4()),
            estimated_price=EstimatedPrice(value=round(prediction, 2)),
            model=ModelReference(
                version=self._metadata["model_version"],
                training_data_version=self._metadata.get(
                    "training_data_sha256", "unknown"
                )[:12],
            ),
            warnings=warnings,
            request_id=request_id,
        )

    def _warnings(self, request: PredictionRequest) -> list[WarningItem]:
        warnings = [
            WarningItem(
                code="REFERENCE_ONLY",
                message=(
                    "Kết quả chỉ mang tính tham khảo; MAPE kiểm thử hiện tại khoảng "
                    f"{self._metadata['metrics']['mape_percent']:.2f}%."
                ),
            )
        ]
        ranges = self._metadata.get("ood_ranges", {})
        values = request.model_dump()
        for field, limits in ranges.items():
            value = values.get(field)
            if value is None:
                continue
            if value < limits["low"] or value > limits["high"]:
                warnings.append(
                    WarningItem(
                        code="OUT_OF_DISTRIBUTION",
                        message=f"{field} nằm ngoài vùng dữ liệu phổ biến của mô hình.",
                    )
                )
        return warnings


model_service = ModelService()

