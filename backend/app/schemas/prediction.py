from __future__ import annotations

from enum import Enum

from pydantic import BaseModel, ConfigDict, Field


class Direction(str, Enum):
    NORTH = "NORTH"
    NORTHEAST = "NORTHEAST"
    EAST = "EAST"
    SOUTHEAST = "SOUTHEAST"
    SOUTH = "SOUTH"
    SOUTHWEST = "SOUTHWEST"
    WEST = "WEST"
    NORTHWEST = "NORTHWEST"


class LegalStatus(str, Enum):
    CERTIFICATE = "CERTIFICATE"
    SALE_CONTRACT = "SALE_CONTRACT"


class FurnitureState(str, Enum):
    FULL = "FULL"
    BASIC = "BASIC"


class PredictionRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    area_m2: float = Field(gt=0, le=5000)
    frontage_m: float | None = Field(default=None, gt=0, le=500)
    access_road_width_m: float | None = Field(default=None, gt=0, le=500)
    floors: int | None = Field(default=None, ge=1, le=100)
    bedrooms: int | None = Field(default=None, ge=1, le=100)
    bathrooms: int | None = Field(default=None, ge=1, le=100)
    house_direction: Direction | None = None
    balcony_direction: Direction | None = None
    legal_status: LegalStatus | None = None
    furniture_state: FurnitureState | None = None
    province_code: str = Field(min_length=1, max_length=80)
    district_code: str = Field(min_length=1, max_length=120)


class WarningItem(BaseModel):
    code: str
    message: str


class EstimatedPrice(BaseModel):
    value: float
    unit: str = "billion_vnd"


class ModelReference(BaseModel):
    version: str
    training_data_version: str


class PredictionResponse(BaseModel):
    prediction_id: str
    estimated_price: EstimatedPrice
    model: ModelReference
    warnings: list[WarningItem]
    request_id: str


class ErrorDetail(BaseModel):
    code: str
    message: str


class ErrorResponse(BaseModel):
    error: ErrorDetail
    request_id: str

