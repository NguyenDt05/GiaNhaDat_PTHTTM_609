import pandas as pd

from backend.app.services.model_service import model_service


def test_model_matches_recorded_smoke_prediction(client):
    metadata = model_service.metadata
    smoke = metadata["smoke_test"]
    prediction = float(
        model_service._model.predict(pd.DataFrame([smoke["input"]]))[0]
    )
    assert abs(prediction - smoke["expected_prediction"]) <= smoke["absolute_tolerance"]

