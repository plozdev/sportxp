# Kế hoạch BE sau MVP — cập nhật 19/10/2026

Trạng thái: kế hoạch triển khai, chưa áp dụng DB. Auth/onboarding/social Phase 1
giữ backend thật; Phase 2–4 đang thử nghiệm bằng mock. Không dùng migration 2A
friends-only như đặc tả cuối. Business nguồn: [room access](room-access-business.md).

## 1. Delta DB cho Public / Private bằng mã

Không cần loại phòng thứ ba hoặc sửa bảng friendships để cho người lạ vào phòng.
Giữ enum visibility PUBLIC/PRIVATE. Không tự kết bạn khi vào chung phòng.

| Thành phần | Thay đổi cần implement |
|---|---|
| match_rooms | Giữ court_id/visibility, thời gian, revision, capacity và trạng thái; không trả mã trong projection public |
| room_join_codes (bảng mới) | room_id FK unique, mã tra cứu unique đã chuẩn hóa hoặc digest, code_version, created_at; chỉ backend/luồng host có quyền lấy mã chia sẻ |
| room_members | Thêm admission_method HOST/PUBLIC/ROOM_CODE/LEGACY_ACCEPTED, admitted_code_version nullable và admitted_at; không lưu mã thô trong membership |
| courts | Thêm area_code/area_id đã chuẩn hóa và index để lọc khu vực theo sân, không lấy vị trí nhà người tạo |
| room_commands / audit | Giữ receipt actor+request; thêm version contract, ghi admission/revision nhưng che room_code/token trong payload, fingerprint và log truy cập |

Chốt cách lưu secret khi implement: ưu tiên digest để lookup; nếu cần host lấy
lại chính mã cũ thì lưu bản mã hóa riêng để server trả qua RPC được phân quyền.
Không đưa secret vào bảng match_rooms đang có SELECT grant rộng. Mã do server
tạo bằng nguồn ngẫu nhiên phù hợp, UNIQUE và retry collision trong transaction;
mã preview từ Flutter không được tự quyết định mã chính thức của phòng.
MVP chưa có đổi mã/hết hạn do host thao tác; code_version chuẩn bị cho khả năng
thu hồi sau này, không thêm UI nghiệp vụ mới trong đợt này.

## 2. RPC và ranh giới quyền

### Tạo / sửa phòng

Create trả id + mã chính thức cho host sau commit. Khi request retry, trả cùng
phòng/mã, không phát mã mới. Sửa sân/giờ/phí hoặc visibility tăng terms revision
theo chính sách hiện có, không tự đổi mã. PUBLIC → PRIVATE không hủy chỗ đã nhận;
lượt chờ cũ được kết thúc không phạt và phải đăng ký lại theo điều kiện mới.

### Lookup mã và preview

Thêm lookup_room_by_code cho người đăng nhập; chuẩn hóa dấu #, hoa/thường,
khoảng trắng. Không chấp nhận room UUID hoặc tiền tố UUID làm mã thay thế.
Lookup đúng trả preview cần thiết để quyết định tham gia, không tạo membership,
không giữ slot và không làm phòng xuất hiện trên sảnh công khai.

Đề xuất trả preview_token ngắn hạn, có chữ ký server, ràng buộc user/room/
code_version/expiry và scope đọc. Repository giữ token để tải lại trang chi tiết;
get_room RPC xác minh token hoặc membership. Không dùng _codeAccess của Flutter
làm quyền thật. Có thể dùng bảng preview_grants thay token nếu phù hợp runtime,
nhưng phải chọn một cách khi implement, không duy trì hai nguồn quyền song song.

### Join / waitlist / reconfirm

PUBLIC: không cần bạn bè hoặc mã. PRIVATE: lượt đăng ký mới phải gửi mã đúng,
server kiểm lại ngay trong transaction; preview token không đủ để chiếm chỗ.
Giữ kiểm tra actor auth.uid, block, onboarding/trình, trạng thái, hạn đăng ký,
expected_revision, calendar và capacity. Mã không thay thế các điều kiện này.
Mã sai/không có quyền trả lỗi chung, không tiết lộ phòng theo UUID.

Waitlist private ghi admission ROOM_CODE + code_version sau khi kiểm mã. FIFO
promotion dùng admission đã được ghi ở server, không phụ thuộc friendship và
vẫn kiểm lại block/lịch/trình/revision/quyền còn hiệu lực. Reconfirm của người
đang giữ chỗ dùng membership và revision hiện tại, không bắt nhập lại mã. Người
đã hủy muốn đăng ký mới phải kiểm mã lại; ever_registered không là vé rejoin.

### Discovery, danh sách riêng và RLS

- Sảnh public chỉ trả PUBLIC, trạng thái/thời gian phù hợp, lọc khu vực sân và
  các điều kiện khác trước phân trang. FULL vẫn có thể hiển thị để đăng ký chờ.
- Tab Private chỉ trả phòng host tạo hoặc membership đang có hiệu lực; không
  liệt kê phòng của bạn bè và không liệt kê chỉ vì từng lookup mã.
- RLS đọc trực tiếp private chỉ cho host/thành viên theo quyền lịch sử đã chốt.
  Người có preview hợp lệ đọc qua RPC hạn chế; không nới toàn bộ table SELECT.
- Không trả mã cho API list/feed/leaderboard; host lấy mã qua API có quyền riêng.
- Bỏ tác động của unfriend lên đăng ký/chờ phòng. Block vẫn chặn lượt mới và
  revoke waitlist; giữ lịch sử/thông tin đối soát cho chỗ đã được nhận.
- Giữ friendship/block làm điều kiện xem activity; vào phòng bằng mã không mở
  hồ sơ riêng tư hoặc feed Friends và không tự trở thành bạn.

## 3. SQL cũ cần thay thế trong forward migration

Audit local 20261019000100_rooms_phase2a.sql xác định các điểm sau:

- room_can_read_v2: bỏ nhánh friendship mở private; giữ host/membership.
- room_eligible_v2: tách điều kiện trình/block khỏi chứng cứ admission; không
  dùng accepted friendship làm quyền vào private.
- room_command_v2: kiểm mã cho lượt mới, ghi admission, redact secret khỏi
  room_commands.payload và audit; không tin code client tạo.
- promote_room_waitlist_v2: kiểm admission đã lưu, không tra friendship.
- revoke_room_waitlist_friendship: bỏ trigger này; không ảnh hưởng các trigger
  social khác. Giữ trigger block và tách hàm revoke khỏi logic unfriend.
- get_room_v2/list_rooms_v2/room projections: thêm preview flow, bỏ private của
  bạn bè khỏi list, bổ sung area filter và whitelist output không có mã.
- public grants/policies trên match_rooms: kiểm lại cả policy permissive cũ,
  column grants và RPC SECURITY DEFINER để tránh đường đọc ngoài projection.

Giữ migration lịch sử nguyên body; tạo migration forward riêng sau khi audit
live. Chọn tên/version RPC mới và cutover client đồng bộ, không thêm overload
mơ hồ. Nếu v2 chưa deploy vẫn chạy chuỗi migration đã review ở staging, chưa
cho người dùng truy cập trạng thái friends-only trung gian.

## 4. Backfill và rollout

1. Audit live bằng quyền owner: migration đã áp dụng, grants, policies,
   functions/triggers và các phòng đang hoạt động; không suy luận từ anon API.
2. Thêm schema/grants mới ở staging, cấp mã duy nhất cho phòng managed hiện có,
   chỉ cho host nhận mã; không broadcast mã đến tất cả bạn bè.
3. Thành viên đang REGISTERED/RECONFIRM giữ chỗ và lịch sử, ghi LEGACY_ACCEPTED
   nếu thiếu bằng chứng admission; không gán giả rằng họ từng nhập mã.
4. Waitlist private cũ chỉ dựa friendship: lưu audit, hủy consent do POLICY_CHANGED
   không phạt, thông báo cần nhập mã đăng ký lại. Không tự hồi sinh khi kết bạn.
5. Dữ liệu MVP v1 giữ legacy/read-only theo chính sách cũ, không tự invent buổi,
   attendance hoặc chứng cứ room code. Backfill area sân cần rà dữ liệu thiếu.
6. Test đa tài khoản và đa connection, deploy RPC/RLS và client cùng đợt; chỉ
   bật nguồn dữ liệu thật sau khi nghiệm thu. Rollback phải giữ private kín,
   không quay lại cho toàn bộ bạn bè đọc phòng để chữa lỗi client.

## 5. Nghiệm thu bắt buộc

Bạn bè không có mã không đọc private mới; người lạ có mã lookup/join được;
preview không chiếm slot; code sai/rỗng/UUID prefix không vượt quyền; private
không lộ qua search/paging/direct SELECT. Draft không được lộ qua mã.
Auth/block/skill/calendar/last-slot/idempotency/revision vẫn đúng; reconfirm không
cần nhập mã lại; canceled rejoin cần mã; unfriend không revoke waitlist mới;
block có revoke và unblocking không tự đăng ký lại. Feed giữ quyền Friends độc lập.

Test mã trùng và tạo đồng thời, dò mã/rate limiting ở server (không chỉ UI), expiry
preview, quyền host lấy mã, log không chứa secret, và migration bảo toàn membership.
Public filter theo courts.area trước pagination; không yêu cầu thuật toán GPS,
geofencing, distance ranking hoặc Elo cho increment này.

Các module 2B/2C/4 tiếp tục theo projection mock đã chốt; cấp quyền thành viên
buổi từ membership thật, không suy từ friendship. Không nhập dữ liệu fixture lên
production. Kế hoạch này chưa phải xác nhận BE đã được implement/deploy.

## Bổ sung sau review tích hợp UI 19/10

Nhật ký cá nhân phải truy vấn session/matches theo ID người chơi, độc lập bài
đăng và đầy đủ phân trang. Xóa activity không được làm mất session khỏi nhật ký;
tổng buổi/trận lifetime không được tính từ 20 post đầu. Rank movement, weekly
goals, placement count và badges cần dữ liệu có nguồn xác nhận; không hardcode
thành tích trong adapter Supabase. Chi tiết: three-agent-integration-review.md.


## 6. Cập nhật đồng bộ nghiệp vụ Mobile - BE (27/10/2026): Bỏ Home Activity & Định hướng Giải Đấu

Sau đợt tái cấu trúc Mobile Shell (chuyển sang 4 Tabs: Tìm kèo -> Xếp hạng -> Giải đấu -> Hồ sơ), BE cần cập nhật các nguyên tắc thiết kế sau để tránh lệch pha (mismatch):

1. **Loại bỏ phụ thuộc vào Activity Feed:**
   - Không còn khái niệm "bài đăng mạng xã hội / status / feed post" công khai.
   - Các bảng/RPC liên quan đến ctivities không còn là bề mặt hiển thị chính trên Client.
   - **Nhật ký thi đấu (Match Diary / Sessions)** trong Hồ sơ cá nhân: Bắt buộc truy vấn trực tiếp từ bảng dữ liệu gốc match_sessions và match_results theo player_id, độc lập 100% với việc có post bài hay không.

2. **Quan hệ người chơi (Friendships / Connections):**
   - Không phục vụ cho mục đích "theo dõi bài đăng mạng xã hội (follow feed)".
   - Mục đích duy nhất: Lưu trữ danh sách **Bạn bè / Đồng đội thân thiết (Teammates)** để hỗ trợ mời nhanh vào phòng đánh đôi và quản lý quyền riêng tư hồ sơ.

3. **Định hướng Schema & Nghiệp vụ Giải Đấu (Tournaments) & Role Chủ Sân (Host/Referee):**
   - *Bối cảnh chống gian lận Elo (từ tài liệu elo_problems):* Tránh tam giác gian lận (Bơm điểm chéo H2H farming, Báo cáo sai kết quả / Dispute hell, Ngủ đông bảo toàn rank).
   - *Phân cấp độ tin cậy Elo:*
     - **Kèo tự do (Peer-to-Peer):** Xác thực đồng thuận 2 chiều (2-party consensus), áp trần tần suất đối đầu (H2H Capping), hệ số K biến động Elo thấp.
     - **Giải đấu do Chủ Sân Host (Official Tournaments):** Chủ sân / Trọng tài đóng vai trò độc lập (Ground Truth). Kết quả do Host phê duyệt được gán trọng số Elo chính thức (Official Weight) cao nhất và cập nhật trực tiếp lên Bảng vàng BXH.
   - *Chuẩn bị Backend cho Phase Tournaments:*
     - Khảo sát mở rộng Role enue_owner / 	ournament_host trong bảng phân quyền.
     - Thiết kế bảng 	ournaments, 	ournament_registrations, 	ournament_fixtures gắn liền với courts (sân đấu) và eferee_id (trọng tài xác nhận kết quả).