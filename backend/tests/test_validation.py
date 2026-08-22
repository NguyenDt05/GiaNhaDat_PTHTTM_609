def test_rejects_unknown_fields(client, valid_payload):
    valid_payload["unexpected"] = "value"
    response = client.post("/api/v1/predictions", json=valid_payload)
    assert response.status_code == 422
    assert response.json()["error"]["code"] == "VALIDATION_ERROR"


def test_rejects_invalid_area(client, valid_payload):
    valid_payload["area_m2"] = 0
    response = client.post("/api/v1/predictions", json=valid_payload)
    assert response.status_code == 422


def test_rejects_district_from_another_province(client, valid_payload):
    options = client.get("/api/v1/options").json()["provinces"]
    if len(options) < 2:
        return
    valid_payload["province_code"] = options[0]["code"]
    valid_payload["district_code"] = options[1]["districts"][0]["code"]
    response = client.post("/api/v1/predictions", json=valid_payload)
    assert response.status_code == 422
    assert response.json()["error"]["code"] == "INVALID_LOCATION"

