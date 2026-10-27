# SPORTXP — Project context

Cập nhật: 18/10/2026. Đây là điểm vào tài liệu định hướng sản phẩm dài hạn.
Repo Flutter hiện tại và web demo riêng không được mặc định là cùng codebase,
cùng backend hoặc cùng mức hoàn thiện. Không viết lại MVP hiện có chỉ để khớp roadmap.

## 1. Định vị

SportXP kết nối người chơi cầu lông phong trào, tổ chức buổi chơi, ghi nhận kết
quả và chia sẻ hoạt động. Khẩu hiệu: **Mọi set cầu đều được định danh và ghi nhận.**

Ba đại lượng tách biệt: **Elo = năng lực tương đối**, **giữ hẹn = độ tin cậy tham
gia**, **social = quan hệ/quyền chia sẻ**. Không dùng đánh giá host để chấm trình;
không dùng thắng/thua hoặc tranh chấp tỉ số để tự động trừ điểm giữ hẹn.

## 2. Tài liệu nguồn và trạng thái quyết định

| Tài liệu | Vai trò |
|---|---|
| [Product decisions](product-decisions.md) | Luật sản phẩm, quyền thao tác, trạng thái và trường hợp biên |
| [Implementation roadmap](implementation-roadmap.md) | 4 phase, phụ thuộc, dữ liệu dự kiến và tiêu chí nghiệm thu |
| [Demo review](demo-review-2026-10-18.md) | Bằng chứng quan sát web demo, đánh giá MVP và giới hạn kiểm tra |
| [How Elo works](how-elo-works.md) | Nghiên cứu trình Việt Nam, taxonomy v2 và phần Elo còn là đề xuất |
| [Onboarding](onboarding.md) | Quiz, progress, RPC và giới hạn điểm khởi tạo |
| [Design system](design-system.md) | Chuẩn giao diện của sản phẩm cầu lông |

**Hướng đã thống nhất:** phát triển dài hạn theo 4 phase; hồ sơ social/QR; kết bạn
hai chiều; Public xuất hiện trong tìm kèo theo khu vực sân, Private vào bằng mã
không cần kết bạn; một buổi có nhiều trận; Trust Score tập trung vào giữ hẹn.
Business private cũ đã được thay thế ngày 19/10/2026. Xem
[kế hoạch BE](backend-implementation-plan.md) và [room access](room-access-business.md).

**Baseline đề xuất để triển khai:** nhiều phòng khác lịch và tối đa một buổi host
đang diễn ra; xác nhận từng trận bởi người tham gia; tổng kết cả buổi; không tự
chốt kết quả do im lặng; host điểm danh và hệ thống xử lý sự kiện giữ hẹn.

**Chưa chốt chi tiết:** cửa sổ phản hồi (đề xuất 24h), hạn hủy không phạt, cách
hiển thị/tính Trust Score, điều kiện đủ xác minh rank và ngoại lệ lịch/đồng host.
Không biến các tham số đề xuất thành yêu cầu đã được xác nhận hoặc tính năng đã có.

## 3. Domain model mục tiêu

- **Room / phòng hẹn:** nơi tuyển người, mô tả lịch/sân/phí/trình/quyền vào.
- **Play session / buổi chơi:** lần chơi thực tế, người có mặt, giờ thực tế,
  các sân con và nhiều trận. Phòng bị hủy không mặc nhiên tạo activity hoàn tất.
- **Match / trận:** hai bên có đội hình xác định, kết quả, revision và xác nhận.
- **Set / ván:** thành phần của trận; một trận có thể gồm một hoặc nhiều set,
  nhưng chỉ tính Elo một lần cho trận theo thể thức đã chọn.
- **Personal activity / nhật ký cá nhân:** tổng kết phần tham gia của một người
  trong buổi, liên kết dữ liệu chung, chứa cảm nhận/chỉ số cá nhân của chính họ.
- **Activity post / bài chia sẻ:** bản công bố do chính người đó chọn phạm vi xem.
  Lưu nhật ký không đồng nghĩa đã đăng feed; host không đăng thay mọi thành viên.

Luồng chính: kết nối → hẹn chơi → tìm/đăng ký → điểm danh → ghi/xác nhận từng trận
→ ghi Elo đúng một lần → kết thúc buổi → tổng kết cá nhân → tự chọn chia sẻ.

## 4. Bốn phase dài hạn

| Phase | Kết quả cần đạt |
|---|---|
| 1 — Hồ sơ social | Hồ sơ người khác, QR/link, kết bạn hai chiều, chặn, quyền đọc |
| 2 — Tổ chức buổi chơi | Phòng Public/Private, lịch, đăng ký, host, điểm danh, nhiều trận, xác nhận, Elo ledger, giữ hẹn |
| 3 — Khám phá kèo | Tìm theo tọa độ sân, khu vực/ngày/giờ/trình/phí, quyền Private và phân trang |
| 4 — Activity/feed | Nhật ký theo buổi, đăng có lựa chọn, feed mình+bạn bè, quyền riêng tư và trạng thái trống |

Trước phase 1 có đợt rà schema/RLS/migration và mapping code đang có; đây là
điều kiện kỹ thuật, không phải phase sản phẩm thứ năm. Chia phase theo giá trị và
điều kiện nghiệm thu, không cam kết cứng mốc 4–6 tháng khi chưa ước lượng.

## 5. Kiến trúc và stack

Nền hiện tại: Flutter feature-first, Supabase Auth/PostgreSQL/RPC. PostgreSQL là
nguồn dữ liệu chuẩn cho quyền truy cập, trạng thái trận, xác nhận và ledger.
Các module mục tiêu: identity/social, scheduling, sessions/matches, rankings,
attendance/trust, activity/feed. Không dồn mọi nghiệp vụ vào navigation shell.

Dùng transaction, constraints, idempotency, audit log và RLS trước khi tối ưu
cache. PostGIS phù hợp cho tìm sân theo tọa độ khi triển khai phase 3. Realtime,
push và Storage chỉ thêm khi có luồng cụ thể và phân quyền tương ứng.

Spring Boot/Cloud Run/Redis trong bản định hướng cũ là lựa chọn mở rộng tương
lai, **không phải quyết định phải chuyển hệ thống ngay**. Chỉ tách dịch vụ khi
có nhu cầu vận hành/quy mô đo được; giữ hợp đồng và migration có phiên bản.

## 6. UI và các định danh

Sản phẩm này dành cho cầu lông, mobile-first, nền #07080A và Court Green #00D665.
Giữ chữ số tabular, hitbox lớn và Bento card. Web demo được cung cấp đang có nội
dung Pickleball và nền sáng; chỉ tham khảo các tương tác phù hợp.

Điều hướng dài hạn cần phân biệt **Trang chủ/activity** với **Kèo đấu/tìm phòng**.
Hồ sơ chứa hộ chiếu QR; quản lý phòng và buổi đang diễn ra có điểm vào rõ ràng.
Bảng xếp hạng tiếp tục tồn tại; không mặc định sao chép thanh 5 nút của demo.

QR hồ sơ mở hồ sơ. QR/mã phòng chỉ dẫn tới phòng. QR sân định danh địa điểm.
Check-in buổi chơi là bằng chứng tham gia có ngữ cảnh, không suy ra chỉ từ việc
quét QR hồ sơ hoặc biết mã sân tĩnh.

## 7. Baseline đã kiểm tra và điều chưa có

Audit Data API ngày 18/10/2026 đọc được 4 bảng chính: courts, profiles,
match_rooms, match_results. Chưa thấy các bảng social/activity/room invitations
ở các tên đã kiểm tra; chưa có public_id, author_id/user_id trên kết quả và
visibility trên phòng/kết quả. Không coi đây là kiểm kê toàn bộ SQL catalog/RLS.

Repo có client auth, dữ liệu phòng/feed cơ bản, onboarding, hồ sơ và bảng hạng.
Social, activity theo bạn bè, attendance trust và kết quả nhiều người xác nhận
chưa được chứng minh là đã triển khai end-to-end. Lịch sử trận hiện lọc theo tên
là giải pháp tạm, không được dùng làm nguồn định danh cho hệ thống dài hạn.

Migration tier v2 đã được chuẩn bị nhưng lần tra hàm live gần nhất vẫn cho
850 → Phong trào Khá, 1000 → Bán chuyên / Thi đấu. Cần đối chiếu deployment trước
khi áp dụng. Bảng trình v2 có 20 mức và cap onboarding 850 = TB+ tạm tính.
Không reset Elo khi chỉ thay tên/dải hạng.

## 8. Mở rộng sau core loop

HealthKit/Health Connect với đồng ý riêng; bản đồ nâng cao; CLB và giải đấu;
đồng host; quản lý thu chi/thanh toán; xếp hạng khu vực; kiểm chứng rank sâu hơn;
chống thông đồng dựa trên mạng lưới đối thủ. Đây là hướng dài hạn, không phải
điều kiện phải làm hết trước khi thử nghiệm các phase đầu.


## 5. Cập nhật Hiện trạng Thực tế (27/10/2026)

- **Trục chức năng cốt lõi (4 Tabs hoàn chỉnh):**
  1. Tìm kèo: Đặt làm màn hình mặc định khi mở app, gom nút tạo kèo nhanh.
  2. Xếp hạng: Bảng xếp hạng Elo thời gian thực.
  3. Giải đấu (Mới): Hiển thị các giải đấu cúp phong trào, lọc theo trạng thái/khu vực và đăng ký VĐV.
  4. Hồ sơ: Thông tin VĐV, thẻ Passport và kết nối bạn bè bằng QR Code.

- **Hệ thống Backend & Database Mới Nhất:**
  - Database đã đồng bộ 100% giữa **Supabase Cloud** và **Docker Local DB** (docker/init-db/01_schema_and_seed.sql).
  - Gồm 10 bảng nghiệp vụ: courts, profiles, 	ournaments, 	ournament_participants, match_rooms, oom_members, match_results, riendships, user_blocks, onboarding_responses.
  - Toàn bộ các bảng và API thừa liên quan đến Social Feed/Post (ctivities) đã bị loại bỏ hoàn toàn.