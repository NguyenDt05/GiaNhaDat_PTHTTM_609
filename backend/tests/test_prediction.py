def test_prediction_success(client, valid_payload):
    response = client.post("/api/v1/predictions", json=valid_payload)
    assert response.status_code == 200, response.text
    payload = response.json()
    assert payload["estimated_price"]["value"] > 0
    assert payload["estimated_price"]["unit"] == "billion_vnd"
    assert payload["model"]["version"]
    assert payload["request_id"] == response.headers["X-Request-ID"]
    assert any(item["code"] == "REFERENCE_ONLY" for item in payload["warnings"])


def test_optional_fields_accept_null(client, valid_payload):
    for field in (
        "frontage_m",
        "access_road_width_m",
        "floors",
        "bedrooms",
        "bathrooms",
        "house_direction",
        "balcony_direction",
        "legal_status",
        "furniture_state",
    ):
        valid_payload[field] = None
    response = client.post("/api/v1/predictions", json=valid_payload)
    assert response.status_code == 200, response.text


def test_out_of_distribution_warning(client, valid_payload):
    valid_payload["area_m2"] = 450
    response = client.post("/api/v1/predictions", json=valid_payload)
    assert response.status_code == 200
    assert any(
        item["code"] == "OUT_OF_DISTRIBUTION"
        for item in response.json()["warnings"]
    )

