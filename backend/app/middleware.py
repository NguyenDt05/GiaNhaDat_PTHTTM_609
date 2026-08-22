from __future__ import annotations

import logging
import threading
import time
import uuid
from collections import defaultdict, deque

from fastapi import Request
from fastapi.responses import JSONResponse
from starlette.middleware.base import BaseHTTPMiddleware, RequestResponseEndpoint
from starlette.responses import Response


LOGGER = logging.getLogger("house_api.request")


class RequestContextMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next: RequestResponseEndpoint) -> Response:
        request_id = request.headers.get("X-Request-ID") or str(uuid.uuid4())
        request.state.request_id = request_id
        started = time.perf_counter()
        response = await call_next(request)
        duration_ms = round((time.perf_counter() - started) * 1000, 2)
        response.headers["X-Request-ID"] = request_id
        LOGGER.info(
            "request completed",
            extra={
                "request_id": request_id,
                "method": request.method,
                "path": request.url.path,
                "status_code": response.status_code,
                "duration_ms": duration_ms,
            },
        )
        return response


class RateLimitMiddleware(BaseHTTPMiddleware):
    def __init__(self, app: object, requests: int, window_seconds: int):
        super().__init__(app)
        self.limit = requests
        self.window = window_seconds
        self._requests: dict[str, deque[float]] = defaultdict(deque)
        self._lock = threading.Lock()

    async def dispatch(self, request: Request, call_next: RequestResponseEndpoint) -> Response:
        if request.url.path.startswith(("/health/", "/docs", "/openapi.json")):
            return await call_next(request)
        client = request.client.host if request.client else "unknown"
        now = time.monotonic()
        with self._lock:
            bucket = self._requests[client]
            while bucket and bucket[0] <= now - self.window:
                bucket.popleft()
            if len(bucket) >= self.limit:
                request_id = getattr(request.state, "request_id", str(uuid.uuid4()))
                return JSONResponse(
                    status_code=429,
                    content={
                        "error": {
                            "code": "RATE_LIMITED",
                            "message": "Đã vượt quá số request cho phép. Vui lòng thử lại sau.",
                        },
                        "request_id": request_id,
                    },
                    headers={"Retry-After": str(self.window)},
                )
            bucket.append(now)
        return await call_next(request)

