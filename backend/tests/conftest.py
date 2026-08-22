from __future__ import annotations

import pytest
from fastapi.testclient import TestClient

from backend.app.main import app


@pytest.fixture(scope="session")
def client() -> TestClient:
    with TestClient(app) as test_client:
        yield test_client


@pytest.fixture
def valid_payload(client: TestClient) -> dict[str, object]:
    options = client.get("/api/v1/options").json()
    province = options["provinces"][0]
    district = province["districts"][0]
    return {
        "area_m2": 60,
        "frontage_m": 5,
        "access_road_width_m": 6,
        "floors": 3,
        "bedrooms": 3,
        "bathrooms": 2,
        "house_direction": "SOUTHEAST",
        "balcony_direction": "EAST",
        "legal_status": "CERTIFICATE",
        "furniture_state": "FULL",
        "province_code": province["code"],
        "district_code": district["code"],
    }
