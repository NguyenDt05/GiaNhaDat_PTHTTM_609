# HouseValue API

FastAPI service phục vụ Random Forest v2. Backend kiểm tra checksum, load model
một lần và chạy smoke prediction trước khi nhận traffic.

Quay lại [README chính](../README.md) · Xem
[kiến trúc hệ thống](../docs/ARCHITECTURE.md)

## Yêu cầu

- Python 3.13 nếu chạy trực tiếp.
- Docker Desktop nếu chạy bằng container.
- Model artifact tại `artifacts/house_price_random_forest_v2.joblib`.

## Chạy bằng Docker

Tại repository root:

```powershell
docker compose up --build -d
docker compose ps
Invoke-RestMethod http://127.0.0.1:8000/health/ready
```

Swagger UI: <http://127.0.0.1:8000/docs>.

Dừng service:

```powershell
docker compose down
```

## Chạy trực tiếp bằng Python

Tại repository root:

```powershell
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r backend\requirements-dev.txt
.\.venv\Scripts\python.exe -m uvicorn backend.app.main:app `
  --host 0.0.0.0 --port 8000
```

Dependencies production nằm trong `backend/requirements.txt`; file
`requirements-dev.txt` bổ sung công cụ kiểm thử.

## API endpoints

| Method | Path | Mô tả |
|---|---|---|
| `GET` | `/health/live` | Process API còn hoạt động |
| `GET` | `/health/ready` | Model đã load và smoke test đạt |
| `GET` | `/api/v1/options` | Danh mục tỉnh/quận, hướng, pháp lý và nội thất |
| `GET` | `/api/v1/model` | Metadata và chỉ số model |
| `POST` | `/api/v1/predictions` | Dự đoán giá nhà |

Luôn lấy mã tỉnh/quận từ `/api/v1/options`; không tự suy diễn mã từ tên hiển
thị.

Ví dụ PowerShell:

```powershell
$Body = @{
  area_m2            = 60
  frontage_m         = 5
  access_road_width_m = 6
  floors             = 3
  bedrooms           = 3
  bathrooms          = 2
  house_direction    = 'SOUTHEAST'
  balcony_direction  = 'EAST'
  legal_status       = 'CERTIFICATE'
  furniture_state    = 'FULL'
  province_code      = 'P_HA_NOI_D3C20E45'
  district_code      = 'D_HA_ONG_F1C75DF0'
} | ConvertTo-Json

Invoke-RestMethod `
  -Method Post `
  -Uri http://127.0.0.1:8000/api/v1/predictions `
  -ContentType 'application/json; charset=utf-8' `
  -Body $Body
```

`area_m2`, `province_code` và `district_code` là bắt buộc. Các trường còn lại
có thể là `null` hoặc được bỏ khỏi request.

## Cấu hình

Backend đọc `.env` tại repository root. Mọi biến có tiền tố `HOUSE_API_`.

| Biến | Mặc định | Ý nghĩa |
|---|---|---|
| `HOUSE_API_ENVIRONMENT` | `development` | `production` sẽ tắt Swagger/OpenAPI UI |
| `HOUSE_API_MODEL_PATH` | Artifact v2 | Đường dẫn model |
| `HOUSE_API_METADATA_PATH` | `backend/model/metadata.json` | Metadata, checksum và smoke input |
| `HOUSE_API_LOCATION_OPTIONS_PATH` | `backend/model/location_options.json` | Danh mục địa giới runtime |
| `HOUSE_API_BEARER_TOKEN` | Rỗng | Token tĩnh cho demo/staging |
| `HOUSE_API_RATE_LIMIT_REQUESTS` | `60` | Số request tối đa mỗi cửa sổ/IP |
| `HOUSE_API_RATE_LIMIT_WINDOW_SECONDS` | `60` | Độ dài cửa sổ tính bằng giây |
| `HOUSE_API_ALLOWED_ORIGINS` | Rỗng | Danh sách CORS phân tách bằng dấu phẩy |

Sao chép `.env.example` thành `.env` nếu cần thay đổi cấu hình. Không commit
token hoặc secret thật.

## Kiểm thử

```powershell
.\.venv\Scripts\python.exe -m pytest backend\tests -q
docker compose config -q
```

Bộ test bao gồm health/readiness, validation, location mapping, prediction,
warning ngoài miền và golden model parity.

OpenAPI tĩnh:

```text
backend/openapi.json
```

## Huấn luyện lại model

Từ repository root:

```powershell
.\.venv\Scripts\python.exe -m ml.train
.\.venv\Scripts\python.exe -m ml.generate_runtime_artifacts `
  --model artifacts\house_price_random_forest_v2.joblib `
  --training-metadata artifacts\model_v2_metadata.json
```

Trước khi thay model đang sử dụng, cần xem xét:

- Group-split metrics và thay đổi so với phiên bản hiện tại.
- Kích thước artifact và RAM sau khi load.
- Checksum, smoke prediction và golden parity tests.
- Benchmark latency và startup trong Docker.

## Ghi chú production

- Chạy một process trên mỗi container vì model dùng bộ nhớ đáng kể.
- Rate limiter hiện là in-memory; nhiều instance cần gateway hoặc Redis.
- Token tĩnh chỉ phù hợp demo/staging, không phải xác thực production hoàn chỉnh.
- Không log token, địa chỉ chi tiết hoặc toàn bộ prediction payload.
