from fastapi import APIRouter, Response, status

from backend.app.services.model_service import model_service


router = APIRouter(tags=["health"])


@router.get("/health/live")
def liveness() -> dict[str, str]:
    return {"status": "alive"}


@router.get("/health/ready")
def readiness(response: Response) -> dict[str, str]:
    if not model_service.ready:
        response.status_code = status.HTTP_503_SERVICE_UNAVAILABLE
        return {"status": "not_ready"}
    return {
        "status": "ready",
        "model_version": model_service.metadata["model_version"],
    }

