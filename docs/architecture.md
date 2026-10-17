# Kiến trúc SportXP

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
