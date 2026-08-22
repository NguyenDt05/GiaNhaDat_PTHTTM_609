FROM python:3.13-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    HOUSE_API_MODEL_PATH=/app/model/house_price_random_forest_v2.joblib \
    HOUSE_API_METADATA_PATH=/app/backend/model/metadata.json \
    HOUSE_API_LOCATION_OPTIONS_PATH=/app/backend/model/location_options.json

WORKDIR /app

COPY backend/requirements.txt /app/backend/requirements.txt
RUN pip install --no-cache-dir -r /app/backend/requirements.txt

COPY backend /app/backend
COPY artifacts/house_price_random_forest_v2.joblib /app/model/house_price_random_forest_v2.joblib

RUN useradd --create-home --uid 10001 appuser \
    && chown -R appuser:appuser /app
USER appuser

EXPOSE 8000

CMD ["uvicorn", "backend.app.main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "1", "--proxy-headers"]
