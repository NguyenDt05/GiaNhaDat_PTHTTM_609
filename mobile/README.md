# HouseValue Mobile

Ứng dụng Flutter cho phép nhập thông tin bất động sản, gọi HouseValue API, hiển
thị giá ước tính và lưu lịch sử trên thiết bị.

Phiên bản hiện tại: `1.1.0+2`.

Quay lại [README chính](../README.md) · Xem
[hướng dẫn demo Android](../docs/ANDROID_DEMO.md)

## Tính năng

- Giao diện Material 3 responsive cho điện thoại.
- Dropdown tỉnh/thành và quận/huyện phụ thuộc nhau.
- Validation số và hỗ trợ trường optional.
- Timeout 15 giây, retry một lần với lỗi mạng hoặc server `5xx`.
- Hiển thị cảnh báo của model và model version.
- Lưu tối đa 50 kết quả gần nhất bằng SharedPreferences.
- Cập nhật APK giữ nguyên lịch sử khi dùng cùng application ID và signing key.

## Yêu cầu

- Flutter 3.44 hoặc phiên bản tương thích với Dart SDK trong `pubspec.yaml`.
- Android Studio và Android SDK cho Android.
- macOS, Xcode và Apple Developer signing nếu build iOS.

Kiểm tra môi trường:

```powershell
flutter doctor -v
```

## Cài dependencies và kiểm thử

```powershell
Set-Location mobile
flutter pub get
flutter analyze
flutter test
```

Nếu sử dụng Flutter SDK cục bộ của workspace:

```powershell
..\.tools\flutter\bin\flutter.bat analyze
..\.tools\flutter\bin\flutter.bat test
```

## Cấu hình API

Ứng dụng đọc cấu hình tại compile time:

| Dart define | Bắt buộc | Mô tả |
|---|---|---|
| `API_BASE_URL` | Có cho thiết bị thật | URL gốc của FastAPI, không có dấu `/` cuối |
| `API_BEARER_TOKEN` | Không | Bearer token cho demo/staging |

| Môi trường | `API_BASE_URL` |
|---|---|
| Android Emulator | `http://10.0.2.2:8000` |
| Điện thoại qua `adb reverse` | `http://127.0.0.1:8000` |
| Điện thoại cùng Wi-Fi | `http://<IP-LAPTOP>:8000` |
| Production | `https://api.example.com` |

Token nhúng trong APK có thể bị trích xuất và không được xem là bí mật.

## Chạy trong development

Android Emulator:

```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

Điện thoại qua USB:

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" reverse `
  tcp:8000 tcp:8000
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

## Build Android

APK demo cùng Wi-Fi:

```powershell
flutter build apk --release `
  --dart-define=API_BASE_URL=http://<IP-LAPTOP>:8000
```

APK production:

```powershell
flutter build apk --release `
  --dart-define=API_BASE_URL=https://api.example.com
```

Đầu ra:

```text
build/app/outputs/flutter-apk/app-release.apk
```

Trước khi phát hành phiên bản mới, tăng `version` trong `pubspec.yaml`:

```yaml
version: 1.2.0+3
```

Phần trước dấu `+` là version name; phần sau là Android version code và phải
tăng sau mỗi bản phát hành.

## Signing

Cấu hình hiện tại dùng Android debug signing key cho bản demo. Điều này đủ để
cài trực tiếp nhưng không phù hợp Google Play hoặc production.

Trước production:

1. Tạo keystore riêng và lưu ngoài repository.
2. Cấu hình `key.properties` hoặc secret của CI.
3. Không commit keystore, mật khẩu hoặc signing credentials.
4. Lưu backup keystore an toàn; mất key sẽ không thể cập nhật ứng dụng cũ.

## HTTP local và HTTPS production

Biến thể Android release hiện cho phép cleartext HTTP để demo với backend trong
LAN. Khi chuyển sang production, dùng HTTPS và bỏ cấu hình cleartext trong
`android/app/src/release/AndroidManifest.xml`.

## Cấu trúc mã nguồn

```text
lib/
├── models/          Prediction và location models
├── repositories/    Local history
├── screens/         Form, result và history
├── services/        API client
├── theme/           Material theme và design tokens
└── main.dart         App entrypoint
```

## Build iOS và Web

iOS runner đã có nhưng cần macOS, Xcode, CocoaPods và Apple signing. Web có thể
build bằng:

```powershell
flutter build web --release `
  --dart-define=API_BASE_URL=https://api.example.com
```

Web client còn phụ thuộc cấu hình CORS của backend.
