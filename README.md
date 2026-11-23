# Mind Deck

Ứng dụng flashcard học theo lặp lại ngắt quãng (Flutter, BLoC). Chi tiết kiến trúc ở `.claude/rules/`.

## Chạy theo môi trường (flavor)

Có 3 môi trường, cài cạnh nhau được trên cùng một máy vì id khác nhau:

| Flavor | Id Android | Tên app | Firebase |
|---|---|---|---|
| `dev` | `com.caohau.minddeck.dev` | Mind Deck Dev | `mind-deck-dev` |
| `staging` | `com.caohau.minddeck.staging` | Mind Deck Staging | `mind-deck-staging` |
| `prod` | `com.caohau.minddeck` | Mind Deck | `mind-deck-prod` |

```
fvm flutter run --flavor dev
fvm flutter run --flavor staging
fvm flutter run --flavor prod
fvm flutter build apk --flavor prod
```

`flutter run` **không có** `--flavor` sẽ báo lỗi. Trong VS Code: mở Run and Debug (Ctrl+Shift+D), chọn Dev / Staging / Prod rồi bấm F5.

## Phần khác nhau giữa các môi trường nằm ở đâu

| Giá trị | Nơi đặt |
|---|---|
| Hậu tố id (`.dev`, `.staging`) | `android/app/build.gradle.kts` |
| Cấu hình Firebase | `android/app/src/<flavor>/google-services.json` (không commit) |
| Tên app, App ID AdMob | `android/app/src/<flavor>/res/values/strings.xml` |
| Địa chỉ backend, dùng quảng cáo thật | `lib/configs/app_config.dart` |

Mã đơn vị quảng cáo thật chỉ được dùng ở `prod` bản release (`lib/constants/ad_units.dart`); các trường hợp khác luôn dùng mã test của Google.

## Lấy `google-services.json` trên máy mới

Các file này không nằm trong git. Với mỗi flavor: Firebase Console, chọn project của flavor, Project settings, Your apps, chọn app Android, tải `google-services.json` và đặt vào `android/app/src/<flavor>/`.

Muốn đăng nhập Google chạy trên máy đó thì thêm SHA-1 và SHA-256 của máy vào app tương ứng rồi tải lại file:

```
cd android
.\gradlew signingReport
```

## Kiểm tra

```
fvm flutter analyze
fvm flutter test
```

`test/widget_test.dart` là bản mẫu cũ và đang lỗi, bỏ qua.
