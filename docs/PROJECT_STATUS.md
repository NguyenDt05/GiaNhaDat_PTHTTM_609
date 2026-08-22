# Trạng thái dự án

Cập nhật: 23/08/2026.

## Tổng quan

Phiên bản demo local của HouseValue AI đã hoàn thành toàn bộ luồng:

```text
Nhập dữ liệu trên Android
  → gọi FastAPI trong Docker
  → Random Forest inference
  → hiển thị kết quả
  → lưu lịch sử trên điện thoại
```

Mobile hiện tại: `1.1.0+2`.

## Phần đã hoàn thành

### Machine learning

- Pipeline huấn luyện độc lập với notebook.
- Group split theo địa chỉ để giảm rò rỉ train/test.
- Random Forest v2 giới hạn độ sâu và leaf size.
- Metadata, checksum, smoke input và runtime location catalog.
- Artifact giảm từ khoảng 249 MB xuống 20,68 MB.

### Backend

- FastAPI version hóa dưới `/api/v1`.
- Validation, error mapping và kiểm tra quan hệ tỉnh/quận.
- Model load một lần trong application lifespan.
- Liveness, readiness, request ID và structured logging.
- Bearer token tùy chọn và rate limit cho MVP.
- Dockerfile, Docker Compose và OpenAPI specification.

### Mobile

- Flutter runner cho Android, iOS và Web.
- Giao diện Material 3 responsive.
- Form, kết quả, cảnh báo và lịch sử cục bộ.
- HTTP client có UTF-8, timeout, retry giới hạn và error mapping.
- APK Android release đã build và chạy trên thiết bị thật.
- Hỗ trợ cập nhật APK mà không mất lịch sử nếu dùng cùng signing key.

### Tự động hóa

- GitHub Actions cho backend và mobile.
- Render Blueprint.
- Runbook triển khai Google Cloud Run.

## Kết quả xác minh

| Hạng mục | Kết quả |
|---|---|
| Backend tests | 9 passed |
| Flutter analyze | No issues found |
| Flutter tests | 6 passed |
| Docker build | Passed |
| Docker readiness | Passed |
| Prediction end-to-end | Passed |
| APK signature v2 | Valid |
| Android thiết bị thật | Đã cài và chạy thành công |

## Chất lượng và hiệu năng model v2

| Chỉ số | Giá trị |
|---|---:|
| Evaluation rows | 6.361 |
| MAE | 1,0822 tỷ VNĐ |
| RMSE | 1,4325 tỷ VNĐ |
| MAPE | 22,18% |
| R² | 0,5628 |
| Load model | 1,73 giây |
| Prediction p95 | 17,75 ms |
| Host RSS delta | Khoảng 148 MB |
| Container RAM sau load | Khoảng 283,6 MiB |

Số liệu benchmark chi tiết:
[`backend/model/benchmark.json`](../backend/model/benchmark.json).

## Việc còn lại trước production

- Chọn Render, Cloud Run hoặc hạ tầng production khác.
- Cấu hình domain HTTPS ổn định.
- Tạo Android production keystore và quản lý signing an toàn.
- Chọn cơ chế authentication production; token tĩnh trong APK không an toàn.
- Thiết lập monitoring, budget alert, log retention và rollback.
- Chạy load test trên hạ tầng thật.
- Nếu phát hành iOS: cần macOS, Xcode và Apple Developer signing.
- Khởi tạo Git repository/push remote nếu muốn kích hoạt GitHub Actions.

Các hạng mục trên cần tài khoản, billing hoặc thông tin xác thực của chủ dự án;
chúng không chặn bản demo môn học chạy local.

## Lệnh xác minh lại

Backend:

```powershell
.\.venv\Scripts\python.exe -m pytest backend\tests -q
docker compose config -q
docker compose up --build -d
Invoke-RestMethod http://127.0.0.1:8000/health/ready
```

Mobile:

```powershell
Set-Location mobile
flutter analyze
flutter test
flutter build apk --release `
  --dart-define=API_BASE_URL=http://<IP-LAPTOP>:8000
```
