# HouseValue AI

Ứng dụng web ước tính giá nhà bằng mô hình Random Forest. Giao diện và FastAPI chạy cùng một dịch vụ, nên trình duyệt gọi API trên cùng địa chỉ. Kết quả chỉ mang tính tham khảo, không thay thế thẩm định chuyên nghiệp.

## Chạy trên máy

Yêu cầu Python 3.13 và model tại `artifacts/house_price_random_forest_v2.joblib`.

```powershell
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r backend\requirements-dev.txt
.\.venv\Scripts\python.exe -m uvicorn backend.app.main:app --host 127.0.0.1 --port 8000
```

Mở <http://127.0.0.1:8000/>. API docs ở <http://127.0.0.1:8000/docs> khi chạy chế độ development.

Nếu Docker Desktop đang chạy:

```powershell
docker compose up --build -d
```

## Triển khai trên Render

Repository có một [Render Blueprint](render.yaml) cho dịch vụ `house-price-api`. Dịch vụ Docker này phục vụ cả web ở `/` và API ở `/api/v1`; không cần tạo static site hay API thứ hai.

1. Đẩy nhánh chứa các thay đổi lên GitHub.
2. Trong Render, kết nối repository và tạo hoặc đồng bộ Blueprint từ `render.yaml`. Nếu `house-price-api` đã thuộc Blueprint, đồng bộ Blueprint hiện có để dùng bản mới.
3. Chờ health check `/health/ready` thành công, rồi mở URL của dịch vụ để kiểm tra form và thử một dự đoán.

Blueprint giữ nguyên gói của dịch vụ Render đã có. Nếu tạo dịch vụ mới, Render sẽ dùng gói mặc định; kiểm tra gói và chi phí trên Dashboard trước khi tạo. Nếu service cũ từng đặt `HOUSE_API_BEARER_TOKEN`, Blueprint đặt giá trị rỗng để web công khai gọi API; kiểm tra biến môi trường thực tế sau khi đồng bộ.

## Tính năng web

- Chọn tỉnh/thành và quận/huyện từ danh mục của API.
- Nhập diện tích, kết cấu, hướng nhà, giấy tờ và nội thất; các trường phụ có thể bỏ trống.
- Xem giá ước tính, cảnh báo, phiên bản mô hình và mã dự đoán.
- Lưu tối đa 50 kết quả gần nhất trong trình duyệt bằng `localStorage`.
- Giao diện responsive cho máy tính và điện thoại.

## Kiểm thử

```powershell
.\.venv\Scripts\python.exe -m pytest backend\tests -q
```

## Cấu trúc

| Thư mục | Nội dung |
|---|---|
| `backend/web` | Giao diện web thuần HTML, CSS và JavaScript |
| `backend/app` | FastAPI, validation và dự đoán |
| `backend/model` | Metadata và danh mục địa điểm runtime |
| `artifacts` | Model đã huấn luyện |
| `ml` | Pipeline huấn luyện |
| `mobile` | Ứng dụng Flutter cũ, được giữ để tham khảo và chạy độc lập |

Chi tiết API: [backend/README.md](backend/README.md). Kiến trúc: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md). Lịch sử dự án: [docs/PROJECT_STATUS.md](docs/PROJECT_STATUS.md).
