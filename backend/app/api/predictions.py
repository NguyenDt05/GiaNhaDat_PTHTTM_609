from fastapi import APIRouter, Depends, Request

from backend.app.api.dependencies import require_auth
from backend.app.schemas.prediction import PredictionRequest, PredictionResponse
from backend.app.services.model_service import model_service


router = APIRouter(tags=["predictions"], dependencies=[Depends(require_auth)])


@router.post("/predictions", response_model=PredictionResponse)
def predict(payload: PredictionRequest, request: Request) -> PredictionResponse:
    return model_service.predict(payload, request.state.request_id)

