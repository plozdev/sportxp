# SportXP — quy chuẩn giao diện

SportXP là tên ứng dụng; SMASH RANK trong brief được hiểu là định hướng trải nghiệm
xếp hạng, chưa dùng như một thương hiệu riêng trong UI.

## Tokens

| Vai trò | Giá trị |
|---|---|
| OLED background | #07080A |
| Card | #111317 |
| Border 1px | #1B1F26 |
| Text | #FFFFFF |
| Metadata | #7E8695 |
| Court Green | #00D665 |
| Loss / cảnh báo | #E03131 |
| Streak | #F5A623 |

Dùng Court Green cho CTA chính, tăng Elo, slot và dấu tab hiện tại. Mục tiêu diện
tích xanh dưới 3% mỗi viewport; cần đo trên ảnh render trước nghiệm thu UI.
Nền tối chiếm ưu thế >85%; không bóng đổ trang trí. Đỏ/xanh luôn đi kèm nhãn
hoặc dấu +/- để không phụ thuộc riêng vào màu. Không dùng màu tier trên cả thẻ.

## Chữ và bố cục

- Giai đoạn scaffold dùng font hệ thống offline. Chưa bundle Inter/Space Grotesk.
  Khi có font có license, khai báo assets trong pubspec: Space Grotesk cho title,
  Inter cho body; kiểm tra đầy đủ dấu tiếng Việt và độ đậm.
- Metric 28 logical px, weight 800 (~21pt), tabularFigures; metadata 12px.
  Số real-time dùng AppTokens.metric hoặc copyWith để giữ tabular figures.
- Khoảng cách theo nhịp 8/16/24px. Card radius 20px, viền 1px.
- Touch target tối thiểu 48×48px. Nội dung max-width 720px; SafeArea và phần
  đệm đáy tránh FAB. Form cuộn theo bàn phím, không khóa text scaling.
- 4 tab: Trang chủ, Kèo đấu, Giải đấu, Hồ sơ. FAB tạo kèo trên hai tab đầu.
- Bento card mỗi khối một mục đích. Mức ưu tiên: chỗ trống → sân/giờ → hành động;
  thẻ kết quả: tỉ số → Elo → người chơi → sức khỏe.
- Ảnh passport 9:16 nền đen, viền xanh tiết chế; health và danh tính có opt-in.

## Tiêu chí nghiệm thu trước phát hành

Kiểm tra thiết bị hẹp 320/360px, text scale 200%, talkback/voiceover,
loading/empty/error/offline, độ tương phản, focus bàn phím và reduced motion.
Chụp viewport để đo tỷ lệ màu xanh; chưa coi tỷ lệ màu là được đảm bảo chỉ từ token.
Health chưa kết nối hiển thị rõ, không giả lập số liệu thành dữ liệu thật.
Chỉ số demo phải có nhãn; xác nhận thành công chỉ xuất hiện sau response thành công.
