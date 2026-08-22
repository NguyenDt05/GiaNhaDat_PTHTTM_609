# Chạy demo trên điện thoại Android

Hướng dẫn này dành cho mô hình demo: backend chạy trên laptop, ứng dụng chạy
trên điện thoại và hai thiết bị giao tiếp qua cùng mạng Wi-Fi.

## Điều kiện

- Windows 11 và Docker Desktop.
- Flutter SDK 3.44 hoặc tương thích.
- Android Studio, Android SDK Platform 36 và Command-line Tools.
- Điện thoại Android 7.0 trở lên.
- Laptop và điện thoại ở cùng mạng Wi-Fi.

Kiểm tra môi trường:

```powershell
flutter doctor -v
```

Nếu Flutter chưa có trong `PATH`, tại repository root dùng:

```powershell
.\.tools\flutter\bin\flutter.bat doctor -v
```

## 1. Khởi động backend

Tại repository root:

```powershell
docker compose up --build -d
Invoke-RestMethod http://127.0.0.1:8000/health/ready
```

Kết quả phải có `status: ready`.

## 2. Lấy IP Wi-Fi của laptop

```powershell
ipconfig
```

Trong mục `Wireless LAN adapter Wi-Fi`, ghi lại `IPv4 Address`, ví dụ
`192.168.1.20`. Không dùng `127.0.0.1`: trên điện thoại địa chỉ đó trỏ tới chính
điện thoại.

Mở trình duyệt điện thoại và truy cập:

```text
http://192.168.1.20:8000/health/ready
```

Chỉ build APK sau khi điện thoại mở được URL này.

## 3. Build APK release

Thay `192.168.1.20` bằng IP thật:

```powershell
Set-Location mobile
flutter pub get
flutter build apk --release `
  --dart-define=API_BASE_URL=http://192.168.1.20:8000
```

Nếu backend bật bearer token:

```powershell
flutter build apk --release `
  --dart-define=API_BASE_URL=http://192.168.1.20:8000 `
  --dart-define=API_BEARER_TOKEN=<DEMO-TOKEN>
```

File đầu ra:

```text
mobile/build/app/outputs/flutter-apk/app-release.apk
```

## 4. Gửi qua Zalo và cài đặt

1. Gửi `app-release.apk` bằng chức năng gửi **File** của Zalo.
2. Tải file trên điện thoại và mở bằng Zalo hoặc ứng dụng Files.
3. Khi Android yêu cầu, bật **Cho phép cài ứng dụng không xác định** cho ứng
   dụng đang mở APK.
4. Chọn **Cài đặt**. Nếu đã có bản cũ, chọn **Cập nhật**.
5. Không gỡ bản cũ nếu muốn giữ lịch sử dự đoán.

Play Protect có thể cảnh báo với APK demo không phát hành qua Google Play. Chỉ
tiếp tục khi file do chính bạn build từ repository này.

## Cài trực tiếp qua USB

Bật Developer options và USB debugging trên điện thoại, sau đó:

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" devices
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" install -r `
  .\build\app\outputs\flutter-apk\app-release.apk
```

Tham số `-r` cập nhật ứng dụng và giữ dữ liệu hiện có.

Trong quá trình phát triển, có thể chuyển tiếp cổng bằng USB:

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" reverse `
  tcp:8000 tcp:8000
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

## Xử lý sự cố

| Hiện tượng | Cách kiểm tra |
|---|---|
| App báo không kết nối được | Mở `/health/ready` từ trình duyệt điện thoại |
| Laptop mở được nhưng điện thoại không mở được | Cho phép Docker Desktop hoặc TCP 8000 trong Windows Firewall trên mạng Private |
| Cùng Wi-Fi nhưng không nhìn thấy nhau | Mạng có thể bật client isolation; thử mạng cá nhân khác |
| App cũ chạy được, APK mới không cập nhật | Đảm bảo APK mới có version code lớn hơn và cùng signing key |
| `App not installed` | Kiểm tra còn dung lượng, mở APK bằng Files hoặc gỡ bản có chữ ký khác |
| IP laptop thay đổi | Build lại APK với `API_BASE_URL` mới |
| Backend dừng sau khi khởi động lại máy | Mở Docker Desktop và chạy `docker compose up -d` |

Xem log backend:

```powershell
docker compose logs --tail 100 api
```

## Khi chuyển sang production

Triển khai backend lên một domain HTTPS ổn định rồi build APK với URL đó:

```powershell
flutter build apk --release `
  --dart-define=API_BASE_URL=https://api.example.com
```

Production cần keystore riêng; không sử dụng Android debug signing key.
