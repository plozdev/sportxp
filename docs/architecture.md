# Kiến trúc SportXP

> Tài liệu này mô tả scaffold ban đầu. Định hướng dài hạn và trạng thái hiện tại
> nằm ở [project context](full-context-project.md),
> [product decisions](product-decisions.md) và
> [implementation roadmap](implementation-roadmap.md).

## Quy tắc phụ thuộc

Tổ chức feature-first: presentation → application → domain; data triển khai
interface trong domain. Domain không import Flutter. `app/` khởi tạo dependency
và chịu trách nhiệm dispose. `shared/` không phụ thuộc vào feature.
Chỉ tạo layer khi có mã thực tế, không tạo thư mục rỗng hoặc generic base repository.

Hiện dùng ChangeNotifier/ListenableBuilder của Flutter. MatchRepository có thể
được thay bằng adapter API tại composition root mà không sửa UI.
MatchController gom loading/error và ngăn gửi thao tác trùng khi đang bận.
Repository demo dùng danh sách immutable khi trả về, join idempotent,
không cho quá số người và không nhận kèo đã bắt đầu.

## Backend cần triển khai

Kế hoạch cập nhật business Public/Private, schema mã phòng và thay thế RPC/RLS
friends-only: [backend implementation plan](backend-implementation-plan.md).
Phase 2–4 hiện là mock; phần dưới là định hướng, chưa xác nhận đã deploy.

- Identity: user id lấy từ session đã xác thực, không tin id do client tự gửi.
- Rooms: tạo, truy vấn theo sân/khoảng cách, tham gia/rời; transaction cho số chỗ,
  idempotency key cho mutation và realtime subscription khi có nhiều thiết bị.
- Matches: lưu người chơi, tỉ số từng set, phiên bản kết quả và xác nhận các bên.
- Verification: pending → verified/rejected/disputed do server quyết định.
  Bằng chứng hiện diện cần hạn dùng, chống replay; xác nhận chéo cần đúng người
  tham gia. Thiết lập chính sách geofence HOẶC xác nhận chéo trên server.
- Rankings: chỉ xử lý trận đủ điều kiện, cập nhật Elo trong transaction, ledger
  bất biến và khóa chống cộng điểm hai lần. Tier hiện tại là ngưỡng tạm đề xuất.
- Health: adapter native, phân biệt chưa cấp quyền/từ chối/không hỗ trợ/không có
  dữ liệu. Không biến dữ liệu thiếu thành 0. Không gửi thông tin sức khỏe lên
  server nếu chưa có đồng ý; cho phép thu hồi quyền và xóa dữ liệu.
- Passport: renderer 1080×1920, chỉ lấy kết quả đã xác nhận; preview trước share,
  cho chọn ẩn tên và số liệu sức khỏe; không nhúng tọa độ người chơi vào ảnh.

## Ranh giới dữ liệu

Public room chỉ có tên sân công cộng và khoảng cách tương đối, không có tọa độ
nhà riêng/người tạo. Tọa độ check-in chỉ truyền qua kênh bảo mật đến dịch vụ
xác thực, không log hoặc đưa vào feed. Thời gian API dùng UTC và hiển thị local.

## Các bước mở rộng

1. Auth và API repository, lưu phiên, phân trang, retry và test hợp đồng.
2. Venue discovery, bản đồ, check-in và xác nhận tỉ số.
3. Elo ledger, lịch sử, biểu đồ, uy tín và matchmaking theo mức kỹ năng.
4. Native health adapters và passport renderer/share.
5. Social feed và tournaments với bảng đấu.

Các bước này là lộ trình, không được biểu diễn là tính năng đã chạy.


## 6. Cập nhật Business Flow & UI Architecture (27/10/2026)

- **Cấu trúc Điều hướng 4 Tabs:**
  1. **Tab 1: Tìm kèo (ManagedRoomsPage / MatchmakingPage):** Trở thành Landing Tab chính. Đưa người dùng trực tiếp vào việc tìm sân/ghép trận gần nhất theo khu vực và Elo.
  2. **Tab 2: Bảng xếp hạng (LeaderboardPage):** Xếp hạng Elo theo hệ thống Skill Taxonomy v2 (Nhập môn -> Cao thủ), streak thắng và điểm tín nhiệm.
  3. **Tab 3: Giải đấu (TournamentsPage):** Đấu trường tranh cúp phong trào do các Chủ sân (Venue Host) và Trọng tài độc lập vận hành. Điểm Elo từ giải đấu là Elo chuẩn (Official Elo) có trọng số xác thực cao nhất, giải quyết triệt để vấn đề gian lận (Rating farming, Match fixing) từ tài liệu elo_problems.
  4. **Tab 4: Hồ sơ VĐV (ProfilePage):** Lưu trữ thông tin cá nhân, Badminton Passport, lịch sử buổi đấu (Match Sessions) và mã QR kết nối bạn bè/đồng đội.

- **Dọn dẹp bề mặt mạng xã hội (Anti-Slop & Streamlining):**
  - **Bỏ hoàn toàn Home Social Feed / Bài đăng:** Tập trung 100% tài nguyên cho việc ghép kèo thể thao và giải đấu.
  - **Nhật ký thi đấu:** Truy vấn trực tiếp từ bảng gốc match_sessions / match_results, loại bỏ các trạng thái "Chờ chia sẻ" hay "Đã đăng bài".
  - **Quan hệ bạn bè:** Quản lý đồng đội/bạn đánh đôi thông qua quét mã QR trực tiếp tại sân, loại bỏ công tắc "Hồ sơ chỉ dành cho bạn bè".

- **Hạ tầng Môi trường kép (Dual Database Stack):**
  - Hỗ trợ chuyển đổi liền mạch giữa **Supabase Cloud** và **Local Docker Stack** (docker/docker-compose.yml: PostgreSQL 15, PostgREST API, Swagger UI) qua biến môi trường trong .env.