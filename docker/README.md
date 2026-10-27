# Hướng Dẫn Vận Hành Backend SportXP (Cloud & Local Docker)

Dự án SportXP hỗ trợ chuyển đổi linh hoạt giữa **Supabase Cloud** và **Local Docker Stack**.

---

## 1. Khởi chạy Local Docker Stack (PostgreSQL + PostgREST + Swagger UI)

### Yêu cầu:
* Cài đặt và bật **Docker Desktop**.

### Các bước chạy:
1. Mở terminal tại thư mục gốc của dự án:
   ```bash
   cd docker
   docker compose up -d
   ```
2. Các dịch vụ sẽ tự động khởi động:
   * **PostgreSQL:** `localhost:5432` (User: `postgres`, Password: `sportxp_password_local`, DB: `postgres`)
   * **REST API (PostgREST):** `http://localhost:3000` (Chuẩn Supabase REST API)
   * **Swagger UI (Xem & Test API):** `http://localhost:8080`
3. Dữ liệu ban đầu (`courts`, `profiles`, `match_results`, xếp hạng Elo) được tự động khởi tạo từ file:
   `docker/init-db/01_schema_and_seed.sql`

---

## 2. Cách chuyển đổi giữa Cloud Supabase và Local Docker trong App Flutter

Mở file `.env` tại thư mục gốc để chọn môi trường mong muốn:

### Dùng Cloud Supabase:
```env
SUPABASE_URL=https://yjcqaxszvmpnlmypxjqq.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### Dùng Local Docker:
```env
SUPABASE_URL=http://localhost:3000
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```
*(Lưu ý: Nếu chạy app trên Android Emulator, thay `localhost:3000` bằng `10.0.2.2:3000`)*.

---

## 3. Cấu trúc Schema DB hiện tại (Đã loại bỏ các bảng thừa)

* ✅ `courts`: Danh sách sân thi đấu và khoảng cách.
* ✅ `profiles`: Thông tin người chơi, phân cấp bậc Elo (Nhập môn -> Cao thủ), điểm uy tín, streak thắng.
* ✅ `friendships`: Danh sách bạn bè / đồng đội đánh đôi.
* ✅ `user_blocks`: Chặn đối thủ toxic / gian lận.
* ✅ `match_rooms`: Danh sách kèo đấu, số slot, sân đấu, giờ chơi.
* ✅ `room_members`: Thành viên trong phòng kèo.
* ✅ `match_results`: Lịch sử kết quả trận đấu, đối đầu và biến động Elo.
* ❌ **Đã loại bỏ hoàn toàn:** Các bảng liên quan đến Activity Feed/Post mạng xã hội để giữ DB tinh gọn, tập trung 100% cho bài toán ghép kèo & giải đấu.
