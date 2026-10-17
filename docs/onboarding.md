# Onboarding SportXP

## Luồng đã triển khai

Khách vẫn xem ứng dụng. Sau đăng nhập hoặc khôi phục phiên, OnboardingGate gọi
get_onboarding_state. Tài khoản có onboarding_step < 5 đi vào quiz; tài khoản
đã hoàn tất đi thẳng vào 4 tab. Nếu tải thất bại, hiển thị thử lại/đăng xuất và
không bỏ qua onboarding.

Mỗi câu có 3–4 thẻ chọn, hitbox tối thiểu 64px, một chạm lưu và tự chuyển câu.
Thanh tiến trình ghi Bước 1/5 đến 5/5. Có thể quay lại câu trước; chọn lại sẽ xóa
các đáp án phía sau để tính nhất quán. Lỗi lưu giữ nguyên câu và cho thử lại.
Tắt animation khi thiết bị bật reduced motion. Layout được kiểm tra 320px/chữ 200%.

Kết quả hiển thị tên, Elo khởi tạo, hạng, nhãn Unverified/Chưa xác minh và lời nhắc
5 trận đầu tiên. Nút BẮT ĐẦU LÊN SÂN tải lại hồ sơ server rồi mở app. Những lần
mở app sau không lặp lại quiz đã hoàn tất.

## Quy ước dữ liệu

profiles.onboarding_step là số câu đã trả lời: 0 chưa bắt đầu, 1–4 đang làm,
5 hoàn tất. private onboarding_responses lưu mảng lựa chọn 0-based, không lưu
điểm do client gửi. Step đơn lẻ không đủ khôi phục điểm; nếu dữ liệu cũ có step
1–4 nhưng không có đáp án, RPC đưa step về số đáp án thực sự có (thường là 0).

Hai RPC được bổ sung:

- get_onboarding_state(): JSON {onboarding_step, answers, display_name,
  elo_rating, tier_name}; tạo hồ sơ còn thiếu từ metadata tên của tài khoản.
- save_onboarding_answer(p_question_index int, p_choice_index int): xác thực
  auth.uid(), kiểm tra thứ tự/đáp án, khóa row, lưu tiến độ; câu cuối cập nhật Elo,
  tier và step=5 trong cùng transaction. Không nhận user_id hoặc Elo từ client.

Công thức đúng brief: 300 + tổng trọng số, clamp 300..850. Trọng số:
Q1 [0,50,120,200], Q2 [0,60,100,150], Q3 [0,100,150],
Q4 [0,50,100,130], Q5 [0,50,100,150].

| Elo | Hạng |
|---|---|
| 300–449 | Nhập môn |
| 450–599 | Phong trào cơ bản |
| 600–749 | Phong trào Trung bình |
| 750–999 | Phong trào Khá |
| 1000+ | Bán chuyên / Thi đấu |

Server tính cùng bảng điểm. Quiz không thể cấp hạng Thi đấu; điểm 1000+ phải đến
từ các trận thực tế. Replay câu cuối sau khi server đã lưu thành công không cấp
điểm lại và không reset Elo đã tăng qua thi đấu. RPC từ chối thay đáp án sau khi
hoàn tất. Trigger bảo vệ Elo/tier/step trước chỉnh sửa trực tiếp của API roles,
và đồng bộ tier mới khi RPC trận đấu cập nhật Elo.

Profile parser hỗ trợ elo_rating/tier_name null. Leaderboard toàn nền tảng lọc
onboarding_step=5 và elo_rating khác null. Đây chưa phải leaderboard khu vực.
Lời nhắc 5 trận là nội dung onboarding theo brief; tự xác minh sau 5 trận và BXH
khu vực cần triển khai riêng. match_results hiện không chứa user_id hay bảng liên
kết người tham gia, nên không suy đoán số trận đã xác minh từ tên đội.

## Bật trên Supabase

Chạy supabase/migrations/20261018_onboarding.sql bằng project owner trong SQL
Editor trước khi chạy bản app mới. Migration chưa được áp dụng lên backend live.
Nó thêm bảng/RPC/trigger, giữ RLS, không tự thay điểm/tier hoặc step của hồ sơ có
sẵn, và bỏ default Elo/tier cũ để tài khoản mới không mặc định nhận 1200 điểm.

Các RPC được tạo SECURITY DEFINER với search_path cố định và chỉ cấp EXECUTE cho
authenticated; không cấp đọc/ghi trực tiếp bảng đáp án. Nhớ giữ quyền UPDATE Elo
bị giới hạn. record_match_and_update_elo hiện hữu phải cập nhật bằng quyền server
(SECURITY DEFINER với kiểm tra p_user_id = auth.uid()); hàm SECURITY INVOKER sẽ bị
trigger chặn khi sửa Elo. Không dùng service-role key trong client.

Tài khoản lâu năm đã có Elo thật nhưng onboarding_step=0 cần được chủ dự án
đánh dấu hoàn tất có chọn lọc trước khi bật gate, nếu muốn giữ Elo hiện tại. Không
đánh dấu toàn bộ hồ sơ mặc định là hoàn tất. Migration không tự phân loại lịch sử.

## Kiểm chứng

flutter analyze và flutter test. Test widget bao phủ lưu/thử lại, tiếp tục phiên,
sửa câu cũ, kết quả 850, đăng nhập/khôi phục phiên, text scale 200%, reduced motion
và null profile. Preview có font tiếng Việt ở build/onboarding-previews/.

SQL có thể test cục bộ bằng PostgreSQL tương thích PGlite, không gọi backend thật:

```sh
npm install --prefix build/onboarding-sql-check --no-save --ignore-scripts @electric-sql/pglite
node supabase/tests/onboarding.test.mjs
```

Test SQL chạy migration hai lần, 18 ca tiến độ/phân quyền và toàn bộ 768 tổ hợp
đáp án. Runtime nằm trong build/ bị gitignore, không thêm dependency cho ứng dụng.
