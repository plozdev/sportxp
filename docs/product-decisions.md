# SportXP — Product decisions và baseline đề xuất

Cập nhật 19/10/2026. Tài liệu thiết kế, chưa xác nhận các tính năng dưới đây đã
được code/deploy. Xem [project context](full-context-project.md) để phân biệt
hướng đã thống nhất và các tham số còn cần chốt.

## 1. Social, QR và quyền riêng tư

Kết bạn hai chiều: gửi → chấp nhận; phân biệt đang chờ, đã gửi, bạn bè, từ chối,
hủy và chặn. Một cặp tài khoản chỉ có một quan hệ hợp lệ, kể cả gửi đồng thời.
Tự quét mã, cùng sân hoặc cùng phòng Public không tự trở thành bạn.

Hộ chiếu QR chứa URL hồ sơ với public_id ổn định/khó đoán. Không chứa khóa auth,
nhịp tim hay tọa độ cá nhân. Có xem mã, quét mã và chia sẻ link. Hồ sơ người khác
trả projection được phép xem, không trả toàn bộ bản ghi tài khoản.

Đăng nhập/onboarding phải giữ được đích hồ sơ/phòng từ deep link. Quét QR không
tự gửi lời mời. Hồ sơ ẩn danh để xuất ảnh không được đồng thời nhúng link/QR
làm lộ đúng danh tính mà người dùng đã chọn ẩn.

## 2. Phòng Public và Private

| Loại | Quyền khám phá và vào |
|---|---|
| Public | Hiện trên sảnh theo khu vực sân; tài khoản đăng nhập đủ điều kiện có thể đăng ký hoặc chờ |
| Private | Ẩn khỏi sảnh; ai có mã đúng có thể xem trước/đăng ký, không cần kết bạn hoặc host duyệt riêng |

Người đã được nhận vào phòng vẫn được giữ đăng ký và quyền xem thông tin cần
thiết cho buổi đó nếu sau này hủy kết bạn; không tự mất chỗ đã cam kết. Các lượt
vào mới của private phải kiểm tra mã và điều kiện phòng, không tra quan hệ bạn bè.
Hủy kết bạn không hủy lượt chờ theo mã. Block cần chặn đăng ký mới và lượt chờ,
nhưng không xóa lịch sử/khả năng đối soát một buổi đã tham gia.

Quyền phòng kiểm tra ở server/RLS cho cả SELECT và join. Lookup mã chỉ cấp
preview, không chiếm chỗ; mã không bỏ qua skill/lịch/capacity/block. Phạm vi phòng
độc lập với activity Friends/Only me. Xem [kế hoạch BE](backend-implementation-plan.md).

## 3. Tạo và quản lý lịch

Baseline: được tạo nhiều phòng khác khung giờ, không cho host có hai buổi trùng
lịch và chỉ một buổi đang diễn ra. Đây là chính sách giai đoạn đầu; đồng host
và chủ CLB vận hành đồng thời nhiều buổi cần quyền tổ chức riêng về sau.

Bắt buộc start/end time có timezone rõ ràng, lưu UTC, hiển thị giờ địa phương.
Ngăn người chơi xác nhận hai lịch trùng; định nghĩa khoảng [start,end) để hai
buổi nối tiếp tại cùng thời điểm không tự bị coi là trùng. Không suy từ chỉ ngày
hoặc chỉ giờ bắt đầu. Phải xử lý lại lịch sau khi host thay đổi.

Thông tin phòng: sân/địa chỉ, sân con hoặc số sân dự kiến, thời lượng, sức chứa,
trình min/max, phí dự kiến/người và khoản đã gồm, quyền Public/Private, ghi chú,
hạn hủy không phạt. Phí nhập tay chưa phải thanh toán; chọn sân chưa phải booking
được sân xác nhận. Không trộn trạng thái thu tiền với trạng thái có mặt.

Host có lựa chọn cũng chơi hoặc chỉ tổ chức. Chỉ người tham gia chơi mới chiếm
slot. Một buổi 8–12 người xoay vòng không bị khóa thành đúng 4 người vì đánh đôi.

Vòng đời phòng/buổi: nháp → mở tuyển → đủ người → đang diễn ra → đã kết thúc;
nhánh hủy có lý do. Đủ người là tình trạng sức chứa, không ngăn host xem/quản lý
phòng và không làm người đã đăng ký mất quyền xem.

## 4. Điểm danh và Trust Score giữ hẹn

Hướng sản phẩm: Trust Score chỉ đo việc giữ hẹn, không đo kỹ năng, thái độ do
host chấm tùy ý, thắng/thua, số lần phản đối tỉ số hoặc “tự chốt quá hạn”.
Host xác nhận **sự kiện điểm danh**, hệ thống suy ra chỉ số; host không tự nhập
một con số 60/90/100 cho người khác.

| Sự kiện | Xử lý baseline |
|---|---|
| Có mặt | Ghi một lần giữ hẹn cho buổi |
| Hủy trước hạn | Không phạt |
| Hủy sát giờ | Lưu riêng hủy muộn; mức ảnh hưởng chưa chốt |
| Vắng không báo đã được xác nhận | Tính vào vi phạm giữ hẹn theo chính sách |
| Host hủy | Không phạt thành viên vì buổi bị hủy |
| Điểm danh đang tranh chấp | Chưa điều chỉnh chỉ số |

Người chơi check-in; host đối chiếu và có thể bổ sung thủ công kèm log/lý do khi
thiết bị lỗi. Không check-in được không đồng nghĩa chắc chắn vắng. Host không
được ghi đè check-in hợp lệ thành vắng mà không đối soát. Người bị đánh dấu vắng
nhận thông báo, xem lý do và có đường yêu cầu sửa; im lặng không phải lời xác nhận.

QR/check-in phải gắn đúng buổi, thời điểm và người đã đăng ký; QR hồ sơ hoặc mã
sân tĩnh không đủ chứng minh có mặt. Các bằng chứng geofence/QR có thể hỗ trợ,
không tuyên bố chống gian lận tuyệt đối, nhất là GPS trong nhà.

Một người có tối đa một kết quả giữ hẹn/buổi, dù chơi nhiều trận. Có audit trước/
sau, actor, thời gian, lý do sửa. Tài khoản ít dữ liệu hiện “Chưa đủ dữ liệu”.
Hiển thị số liệu giải thích: đã tham gia X buổi, hủy muộn Y, vắng xác nhận Z.
Công thức %, trọng số, mức giảm/tăng, cửa sổ thống kê và mức tối thiểu dữ liệu
**chưa chốt**; không coi default trust_score=100 là bằng chứng uy tín.

Phản hồi fair-play nếu thêm về sau là hệ riêng; một đánh giá xấu không trực tiếp
trừ điểm giữ hẹn hoặc Elo. Chỉ người thực sự chơi cùng mới có quyền phản hồi.

## 5. Ghi kết quả nhiều trận

Mỗi match thuộc một session, có đội hình bằng user ID, thể thức và các set.
Đổi đội hình là trận khác. Trận có 1 hoặc nhiều set chỉ phát sinh một lượt tính
Elo theo thể thức đã chọn; không nhân điểm vì ghi từng set tách lẻ.

Baseline đề xuất: người trong trận nhập tỉ số, gửi revision; người gửi đồng ý
với revision đó. Đơn cần cả 2 người, đôi cần cả 4 người đồng ý. Host không tham
gia trận được theo dõi buổi nhưng không xác nhận thay hay quyết định đội thắng.

Trạng thái: draft → pending → confirmed; phản đối → disputed; hủy hợp lệ → void.
Sửa đội hình/tỉ số trước khi chốt tạo revision mới và vô hiệu xác nhận cũ.
Có thể xác nhận trong buổi, hoặc cuối buổi chọn các trận của mình để xác nhận
hàng loạt sau khi xem tỉ số. Không có nút host chấp nhận thay cả buổi.

Hết cửa sổ phản hồi (đề xuất 24h, chưa chốt) mà thiếu xác nhận: lưu log chưa xác
minh, chưa tính Elo. Không tự chốt 50% điểm do im lặng. Khách chưa có tài khoản
vẫn có thể được ghi trong log giao lưu nhưng trận thiếu định danh không nhận
Elo trong baseline đầu tiên.

Khi đủ xác nhận, server xử lý transaction/ledger/idempotency đúng một lần.
Kết thúc buổi không tính lại Elo đã tính cho trận. Trận confirmed không sửa trực
tiếp; sai sót đi qua quy trình correction có dấu vết, không sửa lịch sử âm thầm.
Thứ tự settlement/replay các trận trễ phải được thiết kế để không gây Elo tùy
thuộc thứ tự bấm nút hoặc tính trùng. Không viết lại công thức live khi chưa đọc
function body và có dữ liệu định danh các bên.

## 6. Cùng màn hình, khác quyền

Host và người chơi dùng cùng chi tiết buổi. Host có điều khiển lịch, danh sách,
điểm danh và bắt đầu/kết thúc. Mọi người đều chỉ ghi/xác nhận trận mình tham gia.
Dữ liệu sức khỏe và phản hồi riêng không vì là host mà được đọc tất cả.

Tổng kết phân biệt: N trận đã xác nhận, M trận chờ/đối soát. Thắng/thua/Elo chính
thức chỉ lấy các trận hợp lệ; log pending vẫn xem được trong phạm vi cho phép.
Đóng session không tự biến mọi trận pending thành confirmed.

## 7. Tìm kèo theo sân

Địa lý lấy từ vị trí sân, không lấy nhà host. Có chọn khu vực/sân thủ công nếu
không cấp GPS. Khoảng cách phải tính từ điểm tìm kiếm đến tọa độ sân, không dùng
cột khoảng cách tĩnh làm số liệu thật cho mọi người.

Lọc theo khu vực/bán kính, ngày/giờ, còn chỗ, trình và phí. Cho chọn sắp xếp theo
khoảng cách hoặc thời gian; không hứa ghép tối ưu khi mới là danh sách lọc.
Private không được lộ qua tìm kiếm, bản đồ hoặc truy vấn trực tiếp ngoài quyền.

## 8. Activity và feed

Có nhật ký cá nhân theo buổi và thao tác chọn chia sẻ. Mỗi người là chủ dữ liệu
cá nhân của mình; host không tự đăng thay toàn bộ thành viên. Bài có friends /
only_me; public chỉ thêm nếu có nhu cầu và kiểm soát đúng. Mặc định chia sẻ friends.
Ảnh/tên người được tag/health cần tôn trọng quyền từng người, không lan quyền của
chủ bài sang toàn bộ dữ liệu nguồn.

Home gồm bài của mình và bạn bè đang có quyền xem, mới nhất trước, phân trang.
Chưa có bạn nhưng có lịch sử: hiện bài/nhật ký của mình và gợi ý kết nối. Chưa có
lịch sử: CTA quét QR, tạo hoặc tìm buổi chơi. Không đưa toàn bộ match_results
người lạ vào để lấp feed. Gợi ý kết nối tách biệt với bài của bạn bè.

Hủy kết bạn/chặn/đổi visibility phải được áp dụng khi đọc ở server và làm mới
cache phù hợp. Không chỉ lọc trong app. Chia sẻ một activity không tạo match mới,
không tính lại Elo/giữ hẹn. Gom các bài cùng session thành nhóm là tối ưu về sau,
không được vì gom mà mở rộng quyền xem bài private.


## 8. Quyết định sản phẩm đợt tái cấu trúc (27/10/2026)

### 8.1 Loại bỏ Social Feed công khai
- **Lý do:** Người chơi thể thao phong trào cần giải pháp tìm kèo, tìm đối thủ ngang trình và sân chơi tranh cúp hơn là mạng xã hội đọc tin tức. Feed rỗng gây mất tập trung và làm loãng giá trị cốt lõi.
- **Thực thi:** Gỡ bỏ hoàn toàn Activity Feed khỏi Bottom Navigation. Mọi dữ liệu buổi chơi chuyển thành Lịch sử trận đấu thuần túy.

### 8.2 Tinh giản kết nối bạn bè qua QR Code
- **Cơ chế:** Vì không có chức năng tìm kiếm người lạ toàn hệ thống, việc kết bạn chỉ diễn ra khi hai người chơi gặp nhau ngoài đời hoặc qua mã giới thiệu.
- **Thực thi:** Loại bỏ nút gạt "Hồ sơ chỉ dành cho bạn bè". Thẻ bạn bè tập trung vào 2 tính năng: hiển thị mã QR cá nhân và camera quét mã QR của đồng đội.

### 8.3 Bổ sung Module Giải Đấu (Tournaments) & Giải quyết bài toán Elo Chống Gian Lận
- **Vấn đề cốt lõi (từ elo_problems):** Hệ thống Elo Peer-to-Peer tự do dễ bị gian lận qua 3 lỗ hổng:
  1. Bơm điểm chéo (Rating farming giữa các tài khoản quen).
  2. Dàn xếp tỉ số & Tranh chấp triền miên (Dispute hell khi không có trọng tài).
  3. Ngủ đông bảo toàn thứ hạng (Inactivity).
- **Quyết định giải pháp:**
  - **Tách 2 tầng Elo:** Trận đấu tự do hàng ngày có hệ số biến động Elo nhỏ (K thấp, áp trần H2H). Trận đấu trong **Giải đấu có Trọng tài/Chủ sân (Host)** có trọng số xác thực chính thức (Official Weight) cao nhất vì có bên thứ 3 làm nhân chứng độc lập (Ground Truth).
  - **Schema hỗ trợ cả User & Host:** Bảng 	ournaments lưu trữ host_id, court_id, thể thức, cơ cấu thưởng và giới hạn Rank. Giai đoạn 1 tập trung giao diện VĐV đăng ký tham gia; giai đoạn 2 mở rộng giao diện Host tạo giải và nhập tỉ số vòng bảng/knockout.