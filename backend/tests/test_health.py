def test_liveness(client):
    response = client.get("/health/live")
    assert response.status_code == 200
    assert response.json() == {"status": "alive"}


def test_readiness(client):
    response = client.get("/health/ready")
    assert response.status_code == 200
    assert response.json()["status"] == "ready"
    assert response.json()["model_version"]


def test_web_is_served_with_its_assets(client):
    page = client.get("/")
    assert page.status_code == 200
    assert "Thông tin bất động sản" in page.text
    assert 'src="/assets/app.js"' in page.text
    script = client.get("/assets/app.js")
    assert script.status_code == 200
    assert "/api/v1/predictions" in script.text
