# Kiến trúc hệ thống

Tài liệu này mô tả kiến trúc hiện tại của HouseValue AI. README chính tập trung
vào cách chạy; tài liệu này giải thích cách các thành phần phối hợp với nhau.

## Mục tiêu thiết kế

- Đưa mô hình Python lên mobile thông qua API mà không nhúng model vào APK.
- Giữ quy trình huấn luyện tách biệt khỏi runtime dự đoán.
- Chấp nhận dữ liệu thiếu ở các trường không bắt buộc.
- Có thể kiểm tra chính xác model nào tạo ra mỗi kết quả.
- Backend stateless để dễ đóng gói và triển khai nhiều instance.

## Sơ đồ tổng thể

```text
┌────────────────────────────┐
│ Flutter mobile             │
│                            │
│ Form → API client → Result │
│          │                 │
│          └── Local history │
└─────────────┬──────────────┘
              │ HTTP(S) / JSON
              ▼
┌────────────────────────────┐
│ FastAPI                    │
│                            │
│ Middleware                 │
│   → Validation             │
│   → Location mapping       │
│   → ModelService           │
└─────────────┬──────────────┘
              │
              ▼
┌────────────────────────────┐
│ Random Forest v2           │
│ Pipeline + metadata + hash │
└────────────────────────────┘
```

## Mobile

Mã nguồn mobile nằm trong `mobile/lib`:

```text
lib/
├── models/          Request, response và danh mục địa giới
├── repositories/    Lưu lịch sử cục bộ
├── screens/         Form, kết quả và lịch sử
├── services/        HTTP client, timeout, retry và error mapping
├── theme/           Theme và design tokens
└── main.dart         Khởi tạo ứng dụng và dependency
```

`API_BASE_URL` và `API_BEARER_TOKEN` được truyền tại thời điểm build bằng
`--dart-define`. Lịch sử chỉ nằm trên điện thoại và không được đồng bộ lên
server.

## Backend

Backend nằm trong `backend/app`:

```text
app/
├── api/             Health, model, options và predictions
├── core/            Cấu hình và logging
├── schemas/         Pydantic request/response models
├── services/        ModelService và logic inference
├── main.py          Lifespan và router registration
└── middleware.py    Request ID, rate limit và error handling
```

Khi container khởi động, backend:

1. Đọc metadata và model artifact.
2. Kiểm tra SHA-256 của artifact.
3. Load model đúng một lần.
4. Chạy smoke prediction đã định nghĩa trong metadata.
5. Chỉ trả readiness thành công sau khi các bước trên đạt.

Không có endpoint huấn luyện và backend không lưu prediction vào database.

## Luồng dự đoán

```text
Người dùng nhập dữ liệu
        ↓
Flutter validation cơ bản
        ↓
POST /api/v1/predictions
        ↓
Pydantic validation + kiểm tra tỉnh/quận
        ↓
Chuyển mã API thành nhãn model
        ↓
Random Forest inference
        ↓
Giá ước tính + model version + warnings
        ↓
Hiển thị và lưu lịch sử cục bộ
```

`area_m2`, `province_code` và `district_code` là dữ liệu bắt buộc. Các thuộc
tính còn lại có thể là `null`; pipeline xử lý dữ liệu thiếu trước khi inference.

## Vòng đời model

```text
gianha.csv
    ↓
python -m ml.train
    ↓
artifacts/house_price_random_forest_v2.joblib
artifacts/model_v2_metadata.json
    ↓
python -m ml.generate_runtime_artifacts
    ↓
backend/model/metadata.json
backend/model/location_options.json
```

Model v2 sử dụng group split theo địa chỉ. Artifact được giới hạn độ sâu cây và
`min_samples_leaf` để giảm kích thước/RAM so với model notebook ban đầu.

## Quyết định vận hành

| Chủ đề | Quyết định hiện tại |
|---|---|
| API version | `/api/v1` |
| Model runtime | Đóng cùng Docker image |
| Worker | Một process/container |
| Cấu hình local | 2 CPU, giới hạn 2 GB RAM |
| Lịch sử | Tối đa 50 mục, lưu trên mobile |
| Authentication | Bearer token tùy chọn cho demo/staging |
| Rate limit | In-memory theo IP và từng container |
| Production transport | HTTPS bắt buộc |

## Bảo mật và riêng tư

- Không gửi địa chỉ chi tiết; client chỉ gửi mã tỉnh/thành và quận/huyện.
- Không log toàn bộ request body hoặc access token.
- API key nhúng trong APK không được xem là bí mật.
- Bản demo local cho phép HTTP trong LAN; bản production phải dùng HTTPS.
- Production nhiều instance cần rate limit tập trung tại gateway hoặc Redis.

## Giới hạn hiện tại

- Giá là ước tính điểm, chưa có khoảng tin cậy đã hiệu chỉnh.
- MAPE kiểm thử khoảng 22,18%; kết quả không phải chứng thư định giá.
- Danh mục địa giới được sinh từ dữ liệu huấn luyện, không phải danh mục hành
  chính quốc gia đầy đủ.
- APK demo phụ thuộc IP laptop; khi IP thay đổi phải build lại.
- Chưa có tài khoản người dùng, đồng bộ lịch sử hoặc database server.
