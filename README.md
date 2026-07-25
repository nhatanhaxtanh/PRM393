# PRM393 - PE Grading System

Ứng dụng Flutter hỗ trợ giáo viên chấm bài kiểm tra thực hành (Practical Exam) cho sinh viên, với giao diện hiện đại và hỗ trợ nhiều định dạng file.

---

## Tính năng

- **Xác thực người dùng** — Đăng nhập / Đăng ký tài khoản giáo viên
- **Dashboard tổng quan** — Hiển thị thống kê bài chấm, số sinh viên, điểm trung bình
- **Chấm bài** — Tải lên file bài làm (PDF, DOCX, TXT) và chấm điểm
- **Lịch sử** — Xem lại các bài đã chấm
- **Hồ sơ cá nhân** — Quản lý thông tin tài khoản

---

## Tech Stack

| Thành phần | Công nghệ |
|---|---|
| Framework | Flutter ^3.12.0 |
| Ngôn ngữ | Dart |
| UI | Material Design 3 |
| Icon | Cupertino Icons ^1.0.8 |
| Linting | flutter_lints ^6.0.0 |

---

## Cấu trúc dự án

```
PRM393/
└── frontend/
    └── lib/
        ├── main.dart                   # Entry point
        ├── screens/
        │   ├── auth/
        │   │   ├── login_screen.dart
        │   │   └── register_screen.dart
        │   ├── dashboard/
        │   │   ├── dashboard_screen.dart
        │   │   └── home_tab.dart
        │   └── profile/
        │       └── profile_screen.dart
        ├── widgets/
        │   ├── auth_text_field.dart
        │   ├── gradient_button.dart
        │   ├── sidebar.dart
        │   └── topbar.dart
        └── theme/
            └── app_colors.dart
```

---

## Cài đặt & Chạy

### Yêu cầu

- [Flutter SDK](https://docs.flutter.dev/get-started/install) >= 3.12.0
- Dart >= 3.0.0
- Android Studio / VS Code với Flutter extension

### Các bước

```bash
# 1. Clone repository
git clone https://github.com/nhatanhaxtanh/PRM393.git
cd PRM393/frontend

# 2. Cài dependencies
flutter pub get

# 3. Chạy ứng dụng
flutter run
```

### Build release

```bash
# Android APK
flutter build apk --release

# iOS
flutter build ios --release

# Web
flutter build web
```

---

## Nền tảng hỗ trợ

| Nền tảng | Trạng thái |
|---|---|
| Android | Hỗ trợ |
| iOS | Hỗ trợ |
| macOS | Hỗ trợ |
| Windows | Hỗ trợ |
| Linux | Hỗ trợ |

---

## Màu sắc & Giao diện

| Tên | Mã màu |
|---|---|
| Primary Purple | `#7C3AED` |
| Secondary Pink | `#EC4899` |
| Background | `#F8F7FF` |
| Sidebar | `#1E1B4B` |

---

## Trạng thái phát triển

Hiện tại ứng dụng là **frontend scaffold** với dữ liệu mock. Các bước tiếp theo:

- [ ] Tích hợp backend API (authentication, grading service)
- [ ] Thêm state management (Provider / Riverpod)
- [ ] Implement chức năng upload và chấm bài thực tế
- [ ] Thêm unit test và widget test
- [ ] Tích hợp AI chấm bài tự động

---

## Tác giả

**nhatanhaxtanh** — lenhatanh2411@gmail.com

TEST CodeRabbit 