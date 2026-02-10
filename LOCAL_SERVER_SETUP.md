# Hướng dẫn chạy Local Server (JSON Server)

Dự án sử dụng **JSON Server** để giả lập API backend một cách nhanh chóng.

## 1. Cài đặt Node.js
Đảm bảo bạn đã cài Node.js trên máy. Kiểm tra bằng lệnh:
```bash
node -v
npm -v
```

## 2. Cài đặt JSON Server
Chạy lệnh sau để cài đặt (toàn cục hoặc trong project):

```bash
npm install -g json-server
```

## 3. Khởi chạy Server
Từ thư mục gốc của dự án (`quan_ly_chi_tieu`), chạy lệnh:

```bash
json-server --watch local_server/db.json --host 0.0.0.0 --port 3000
```
*(Lưu ý: `--host 0.0.0.0` giúp server lắng nghe từ mọi IP, cần thiết để truy cập từ điện thoại hoặc máy tính khác trong mạng LAN)*.

## 4. API Endpoints
Server sẽ chạy tại `http://localhost:3000`. Các endpoint khả dụng:

- **GET** `/expenses`      → Lấy danh sách chi tiêu
- **POST** `/expenses`     → Thêm chi tiêu mới
- **PUT** `/expenses/:id`  → Sửa chi tiêu
- **DELETE** `/expenses/:id` → Xóa chi tiêu

## 5. Lưu ý quan trọng khi Debug trên Mobile
- **iOS Simulator**: Dùng `http://localhost:3000` (đã config sẵn trong `ApiConfig`)
- **Android Emulator**: Dùng `http://10.0.2.2:3000` (đã config sẵn)
- **Thiết bị thật**: Cần thay đổi `_lanIp` trong `lib/core/constants/api_config.dart` thành IP máy tính của bạn (ví dụ: `192.168.1.5`).
