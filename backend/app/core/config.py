from __future__ import annotations

from functools import lru_cache
from pathlib import Path

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


PROJECT_ROOT = Path(__file__).resolve().parents[3]


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_prefix="HOUSE_API_",
        env_file=PROJECT_ROOT / ".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    app_name: str = "House Price Prediction API"
    environment: str = "development"
    api_prefix: str = "/api/v1"
    model_path: Path = PROJECT_ROOT / "artifacts" / "house_price_random_forest_v2.joblib"
    metadata_path: Path = PROJECT_ROOT / "backend" / "model" / "metadata.json"
    location_options_path: Path = (
        PROJECT_ROOT / "backend" / "model" / "location_options.json"
    )
    bearer_token: str | None = None
    rate_limit_requests: int = Field(default=60, ge=1)
    rate_limit_window_seconds: int = Field(default=60, ge=1)
    allowed_origins: str = ""

    @property
    def cors_origins(self) -> list[str]:
        return [origin.strip() for origin in self.allowed_origins.split(",") if origin.strip()]


@lru_cache
def get_settings() -> Settings:
    return Settings()
