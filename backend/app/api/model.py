from fastapi import APIRouter, Depends

from backend.app.api.dependencies import require_auth
from backend.app.services.model_service import ModelNotReadyError, model_service


router = APIRouter(tags=["model"], dependencies=[Depends(require_auth)])


@router.get("/options")
def options() -> dict[str, object]:
    return model_service.options


@router.get("/model")
def model_metadata() -> dict[str, object]:
    if not model_service.ready:
        raise ModelNotReadyError("Mô hình chưa sẵn sàng.")
    metadata = model_service.metadata
    return {
        "model_version": metadata["model_version"],
        "metrics": metadata["metrics"],
        "evaluation_protocol": metadata["evaluation_protocol"],
        "ood_ranges": metadata["ood_ranges"],
    }

