from __future__ import annotations

import hmac

from fastapi import Header, HTTPException, status

from backend.app.core.config import get_settings


def require_auth(authorization: str | None = Header(default=None)) -> None:
    expected = get_settings().bearer_token
    if not expected:
        return
    scheme, _, token = (authorization or "").partition(" ")
    if scheme.lower() != "bearer" or not hmac.compare_digest(token, expected):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"code": "UNAUTHORIZED", "message": "Token không hợp lệ."},
            headers={"WWW-Authenticate": "Bearer"},
        )

