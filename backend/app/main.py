from __future__ import annotations

import logging
import time
import uuid
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException, Request
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from backend.app.api import health, model, predictions
from backend.app.core.config import get_settings
from backend.app.core.logging import configure_logging
from backend.app.middleware import RateLimitMiddleware, RequestContextMiddleware
from backend.app.services.model_service import (
    InvalidLocationError,
    ModelNotReadyError,
    model_service,
)


configure_logging()
LOGGER = logging.getLogger(__name__)
SETTINGS = get_settings()


@asynccontextmanager
async def lifespan(_: FastAPI):
    started = time.perf_counter()
    model_service.load(
        SETTINGS.model_path,
        SETTINGS.metadata_path,
        SETTINGS.location_options_path,
    )
    LOGGER.info("Application startup completed in %.3f seconds", time.perf_counter() - started)
    yield


app = FastAPI(
    title=SETTINGS.app_name,
    version="1.0.0",
    lifespan=lifespan,
    docs_url="/docs" if SETTINGS.environment != "production" else None,
    redoc_url=None,
)

app.add_middleware(
    RateLimitMiddleware,
    requests=SETTINGS.rate_limit_requests,
    window_seconds=SETTINGS.rate_limit_window_seconds,
)
app.add_middleware(RequestContextMiddleware)
if SETTINGS.cors_origins:
    app.add_middleware(
        CORSMiddleware,
        allow_origins=SETTINGS.cors_origins,
        allow_credentials=False,
        allow_methods=["GET", "POST"],
        allow_headers=["Authorization", "Content-Type", "X-Request-ID"],
    )

app.include_router(health.router)
app.include_router(predictions.router, prefix=SETTINGS.api_prefix)
app.include_router(model.router, prefix=SETTINGS.api_prefix)


def request_id(request: Request) -> str:
    return getattr(request.state, "request_id", str(uuid.uuid4()))


@app.exception_handler(RequestValidationError)
async def validation_error(request: Request, exc: RequestValidationError) -> JSONResponse:
    errors = []
    for item in exc.errors():
        location = ".".join(str(part) for part in item["loc"] if part != "body")
        errors.append({"field": location, "message": item["msg"]})
    return JSONResponse(
        status_code=422,
        content={
            "error": {
                "code": "VALIDATION_ERROR",
                "message": "Dữ liệu đầu vào không hợp lệ.",
                "fields": errors,
            },
            "request_id": request_id(request),
        },
    )


@app.exception_handler(InvalidLocationError)
async def invalid_location(request: Request, exc: InvalidLocationError) -> JSONResponse:
    return JSONResponse(
        status_code=422,
        content={
            "error": {"code": "INVALID_LOCATION", "message": str(exc)},
            "request_id": request_id(request),
        },
    )


@app.exception_handler(ModelNotReadyError)
async def model_not_ready(request: Request, _: ModelNotReadyError) -> JSONResponse:
    return JSONResponse(
        status_code=503,
        content={
            "error": {"code": "MODEL_NOT_READY", "message": "Mô hình chưa sẵn sàng."},
            "request_id": request_id(request),
        },
    )


@app.exception_handler(HTTPException)
async def http_error(request: Request, exc: HTTPException) -> JSONResponse:
    detail = exc.detail if isinstance(exc.detail, dict) else {
        "code": "HTTP_ERROR",
        "message": str(exc.detail),
    }
    return JSONResponse(
        status_code=exc.status_code,
        content={"error": detail, "request_id": request_id(request)},
        headers=exc.headers,
    )


@app.exception_handler(Exception)
async def internal_error(request: Request, exc: Exception) -> JSONResponse:
    LOGGER.exception("Unhandled request error", exc_info=exc)
    return JSONResponse(
        status_code=500,
        content={
            "error": {
                "code": "INTERNAL_ERROR",
                "message": "Hệ thống gặp lỗi. Vui lòng thử lại sau.",
            },
            "request_id": request_id(request),
        },
    )

