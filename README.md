# HouseValue AI

Ứng dụng mobile ước tính giá nhà bằng mô hình học máy, gồm ứng dụng Flutter,
FastAPI backend, pipeline huấn luyện và cấu hình triển khai Docker.

> Kết quả của hệ thống chỉ mang tính tham khảo, không thay thế chứng thư hoặc
> tư vấn của đơn vị thẩm định giá chuyên nghiệp.

## Tổng quan

```text
Ứng dụng Flutter
      │
      │ HTTP(S) / JSON
      ▼
FastAPI backend
      │
      ├── Validation và chuẩn hóa địa giới
      ├── Rate limit, request ID và structured logging
      └── Random Forest v2
              │
              ▼
       Giá ước tính (tỷ VNĐ)
```

### Thành phần chính

| Thành phần | Công nghệ | Vai trò |
|---|---|---|
| Mobile | Flutter 3.44, Dart 3.12 | Nhập thông tin, hiển thị kết quả và lưu lịch sử cục bộ |
| API | FastAPI, Pydantic | Validation, danh mục địa giới và phục vụ dự đoán |
| Model | scikit-learn Random Forest | Ước tính giá từ 12 thuộc tính bất động sản |
| Đóng gói | Docker, Docker Compose | Môi trường backend nhất quán |
| CI | GitHub Actions | Kiểm tra backend và mobile tự động |

## Tính năng

- Form định giá tối ưu cho điện thoại, hỗ trợ dữ liệu không đầy đủ.
- Danh sách tỉnh/thành và quận/huyện phụ thuộc nhau.
- Retry có giới hạn, timeout và thông báo lỗi mạng thân thiện.
- Cảnh báo khi đầu vào nằm ngoài vùng dữ liệu phổ biến.
- Lưu tối đa 50 kết quả gần nhất trên thiết bị.
- Kiểm tra checksum và smoke test model khi backend khởi động.
- Health check, rate limit, bearer token tùy chọn và API versioning.
- Giao diện Material 3 với thiết kế responsive.

## Chạy bản demo nhanh

### 1. Khởi động backend

Yêu cầu: Docker Desktop đang chạy.

```powershell
docker compose up --build -d
Invoke-RestMethod http://127.0.0.1:8000/health/ready
```

Kết quả hợp lệ có `status` là `ready`. Swagger UI chạy tại
<http://127.0.0.1:8000/docs> trong môi trường development.

### 2. Xác định địa chỉ IP của laptop

```powershell
ipconfig
```

Tìm `IPv4 Address` của card Wi-Fi đang kết nối. Điện thoại và laptop phải ở
cùng mạng. Kiểm tra từ trình duyệt điện thoại:

```text
http://<IP-LAPTOP>:8000/health/ready
```

### 3. Build APK

```powershell
Set-Location mobile
flutter pub get
flutter build apk --release `
  --dart-define=API_BASE_URL=http://<IP-LAPTOP>:8000
```

APK được tạo tại:

```text
mobile/build/app/outputs/flutter-apk/app-release.apk
```

Gửi APK qua Zalo hoặc cáp USB và chọn **Cập nhật** nếu điện thoại đã có phiên
bản cũ. Không gỡ ứng dụng trước khi cập nhật nếu muốn giữ lịch sử dự đoán.

Hướng dẫn chi tiết và xử lý sự cố: [docs/ANDROID_DEMO.md](docs/ANDROID_DEMO.md).

## Phát triển

### Backend không dùng Docker

Yêu cầu Python 3.13.

```powershell
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r backend\requirements-dev.txt
.\.venv\Scripts\python.exe -m uvicorn backend.app.main:app `
  --host 0.0.0.0 --port 8000
```

Chạy kiểm thử:

```powershell
.\.venv\Scripts\python.exe -m pytest backend\tests -q
docker compose config -q
```

### Flutter

```powershell
Set-Location mobile
flutter pub get
flutter analyze
flutter test
```

Chạy trên Android Emulator:

```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

Nếu Flutter chưa nằm trong `PATH`, có thể thay `flutter` bằng SDK cục bộ:

```powershell
..\.tools\flutter\bin\flutter.bat
```

## API

| Method | Endpoint | Chức năng |
|---|---|---|
| `GET` | `/health/live` | Kiểm tra process API |
| `GET` | `/health/ready` | Kiểm tra model đã sẵn sàng |
| `GET` | `/api/v1/options` | Danh mục địa giới và lựa chọn form |
| `GET` | `/api/v1/model` | Phiên bản và chỉ số model |
| `POST` | `/api/v1/predictions` | Tạo dự đoán giá nhà |

OpenAPI tĩnh được lưu tại [backend/openapi.json](backend/openapi.json).

## Chất lượng model

Model v2 được đánh giá bằng group split theo địa chỉ để giảm rò rỉ giữa tập
huấn luyện và tập kiểm thử.

| Chỉ số | Kết quả |
|---|---:|
| Số dòng đánh giá | 6.361 |
| MAE | 1,0822 tỷ VNĐ |
| RMSE | 1,4325 tỷ VNĐ |
| MAPE | 22,18% |
| R² | 0,5628 |
| Kích thước artifact | 20,68 MB |

Benchmark local: model load khoảng 1,73 giây; prediction đơn p95 khoảng 17,75
ms. Số liệu đầy đủ nằm tại
[backend/model/benchmark.json](backend/model/benchmark.json).

## Cấu trúc repository

```text
.
├── artifacts/                 Model đã huấn luyện và metadata
├── backend/                   FastAPI, schema, service và tests
├── deploy/                    Runbook triển khai cloud
├── docs/                      Kiến trúc, trạng thái và hướng dẫn demo
├── ml/                        Pipeline huấn luyện và sinh runtime artifact
├── mobile/                    Ứng dụng Flutter Android/iOS/Web
├── .github/workflows/         CI backend và mobile
├── docker-compose.yml         Backend local
└── README.md                  Điểm bắt đầu của dự án
```

## Tài liệu

| Tài liệu | Nội dung |
|---|---|
| [Kiến trúc hệ thống](docs/ARCHITECTURE.md) | Luồng dữ liệu, thiết kế model và quyết định kỹ thuật |
| [Hướng dẫn demo Android](docs/ANDROID_DEMO.md) | Build, cài APK và xử lý lỗi kết nối |
| [Trạng thái dự án](docs/PROJECT_STATUS.md) | Phần đã hoàn thành, kết quả kiểm thử và việc còn lại |
| [Backend](backend/README.md) | Chạy API, cấu hình, kiểm thử và huấn luyện lại |
| [Mobile](mobile/README.md) | Phát triển Flutter và tạo bản phát hành |
| [Cloud Run](deploy/CLOUD_RUN.md) | Triển khai backend lên Google Cloud Run |

## Trạng thái phát hành

- Bản demo Android local: hoàn thành.
- Mobile version: `1.1.0+2`.
- Backend Docker và kiểm thử end-to-end: hoàn thành.
- Cloud production, domain HTTPS và production signing: chưa cấu hình vì cần
  tài khoản và thông tin xác thực của chủ dự án.

Xem chi tiết tại [docs/PROJECT_STATUS.md](docs/PROJECT_STATUS.md).
