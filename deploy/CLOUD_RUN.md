# Triển khai backend lên Google Cloud Run

Runbook này build Docker image bằng Cloud Build, lưu image trong Artifact
Registry và triển khai FastAPI lên Cloud Run tại Singapore.

## Điều kiện

- Google Cloud project đã bật billing.
- Google Cloud CLI (`gcloud`) đã cài và đăng nhập.
- Tài khoản có quyền với Cloud Build, Artifact Registry và Cloud Run.
- Đã kiểm thử Docker image tại local.

```powershell
gcloud auth login
gcloud auth application-default login
```

## 1. Khai báo cấu hình

Thay project ID trước khi chạy:

```powershell
$ProjectId = '<GOOGLE-CLOUD-PROJECT-ID>'
$Region = 'asia-southeast1'
$Repository = 'house-price'
$Service = 'house-price-api'
$Tag = 'rf-v2'
$Image = "$Region-docker.pkg.dev/$ProjectId/$Repository/api:$Tag"

gcloud config set project $ProjectId
gcloud config set run/region $Region
```

## 2. Bật API cần thiết

```powershell
gcloud services enable `
  run.googleapis.com `
  cloudbuild.googleapis.com `
  artifactregistry.googleapis.com `
  secretmanager.googleapis.com `
  --project $ProjectId
```

## 3. Tạo Artifact Registry

Chỉ chạy một lần cho mỗi repository:

```powershell
gcloud artifacts repositories create $Repository `
  --project $ProjectId `
  --repository-format docker `
  --location $Region `
  --description 'HouseValue API images'
```

Nếu repository đã tồn tại, bỏ qua bước này.

## 4. Build và lưu Docker image

Chạy tại repository root:

```powershell
gcloud builds submit `
  --project $ProjectId `
  --region $Region `
  --tag $Image `
  .
```

Model v2 được đóng trong image theo `backend/Dockerfile`.

## 5. Deploy service

Cấu hình khởi đầu phù hợp với benchmark local:

```powershell
gcloud run deploy $Service `
  --project $ProjectId `
  --region $Region `
  --image $Image `
  --port 8000 `
  --memory 2Gi `
  --cpu 2 `
  --concurrency 4 `
  --timeout 300 `
  --min-instances 0 `
  --max-instances 3 `
  --set-env-vars 'HOUSE_API_ENVIRONMENT=production,HOUSE_API_RATE_LIMIT_REQUESTS=60,HOUSE_API_RATE_LIMIT_WINDOW_SECONDS=60' `
  --allow-unauthenticated
```

`--allow-unauthenticated` phù hợp khi mobile gọi API công khai. Backend vẫn có
thể bật bearer token ứng dụng, nhưng token tĩnh nhúng trong APK không phải cơ
chế bảo mật production hoàn chỉnh.

## 6. Kiểm tra sau deploy

```powershell
$ServiceUrl = gcloud run services describe $Service `
  --project $ProjectId `
  --region $Region `
  --format 'value(status.url)'

Invoke-RestMethod "$ServiceUrl/health/live"
Invoke-RestMethod "$ServiceUrl/health/ready"
Invoke-RestMethod "$ServiceUrl/api/v1/model"
```

Readiness lần đầu có thể chậm hơn do cold start và thời gian load model.

## 7. Kết nối ứng dụng mobile

Cloud Run cung cấp URL HTTPS. Build APK bằng URL vừa nhận:

```powershell
Set-Location mobile
flutter build apk --release `
  --dart-define=API_BASE_URL=$ServiceUrl
```

APK production còn cần Android keystore riêng; xem
[`mobile/README.md`](../mobile/README.md#signing).

## Secrets

Không đưa secret thật vào `--set-env-vars`. Với Secret Manager, cấp cho service
identity quyền đọc secret rồi ánh xạ secret thành biến môi trường:

```powershell
gcloud run services update $Service `
  --project $ProjectId `
  --region $Region `
  --set-secrets 'HOUSE_API_BEARER_TOKEN=house-api-token:latest'
```

Nếu mobile dùng token này thì token vẫn có thể bị trích xuất từ APK. Với sản
phẩm thật, nên dùng token ngắn hạn từ hệ thống xác thực.

## Quan sát và điều chỉnh

Sau UAT, theo dõi:

- Container startup và model load time.
- RAM, CPU, request latency và tỷ lệ `5xx`.
- Số lần scale-to-zero/cold start.
- Tỷ lệ `429` do rate limit.

Đặt `--min-instances 1` nếu cold start không chấp nhận được. Thiết lập budget
alert trước khi tăng số instance hoặc tài nguyên.

Xem log:

```powershell
gcloud run services logs read $Service `
  --project $ProjectId `
  --region $Region `
  --limit 100
```

## Rollback

Liệt kê revision:

```powershell
gcloud run revisions list `
  --project $ProjectId `
  --region $Region `
  --service $Service
```

Chuyển 100% traffic về revision ổn định:

```powershell
$Revision = '<REVISION-NAME>'
gcloud run services update-traffic $Service `
  --project $ProjectId `
  --region $Region `
  --to-revisions "$Revision=100"
```

## Checklist trước production

- [ ] Health, model metadata và prediction smoke test đạt.
- [ ] Load test staging với concurrency dự kiến.
- [ ] Domain HTTPS hoặc Cloud Run URL ổn định.
- [ ] Authentication production đã được chốt.
- [ ] Secrets nằm trong Secret Manager.
- [ ] Log không chứa token hoặc toàn bộ payload.
- [ ] Monitoring, alert và budget alert đã bật.
- [ ] Android production signing và backup keystore hoàn tất.
- [ ] Quy trình rollback đã được thử nghiệm.

## Tài liệu Google Cloud

- [Deploy container images to Cloud Run](https://cloud.google.com/run/docs/deploying)
- [Deploy with Cloud Build](https://cloud.google.com/build/docs/deploying-builds/deploy-cloud-run)
- [Configure secrets](https://cloud.google.com/run/docs/configuring/services/secrets)
- [Rollbacks and traffic migration](https://cloud.google.com/run/docs/rollouts-rollbacks-traffic-migration)
