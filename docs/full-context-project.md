#### 1. Định vị & Tầm nhìn Sản phẩm

* **Tên dự án:** SPORTXP


* **Định nghĩa:** Nền tảng Kết nối, Xếp hạng Kỹ năng (Skill-based Matchmaking) và Hồ sơ Thể thao Số hóa (Digital Sports Passport) dành cho bộ môn Cầu lông phong trào.


* **Khẩu hiệu thiết kế:** *"Mọi set cầu đều được định danh và ghi nhận."*

* **Giá trị cốt lõi:**
1. Chấm dứt tình trạng lệch trình độ khi ghép giao lưu thông qua hệ thống tính điểm động (Elo/Glicko-2).


2. Giải quyết bài toán "thiếu chân giờ chót" (Cứu net) với bộ lọc khoảng cách địa lý và điểm uy tín (`Trust Score`).


3. Game hóa quá trình rèn luyện thể thao qua Bảng xếp hạng theo từng sân (Hyper-local Court Leaderboard) và tích hợp dữ liệu sức khỏe (HealthKit / Health Connect).





#### 2. Kiến trúc Hệ thống & Tech Stack (Full Scale)

* **Client (Mobile-First):** Đa nền tảng (Cross-platform Mobile hoặc PWA đóng gói), giao diện OLED Dark Mode (`#07080A`), màu nhấn Court Green (`#00D665`).


* **Backend API:** Java Spring Boot (RESTful API, Spring Security + JWT/OAuth2), đóng gói Docker chạy trên Google Cloud Run.
* **Database & Caching:**
* **PostgreSQL + PostGIS:** Lưu trữ thực thể người dùng, lịch sử trận đấu, tính toán khoảng cách tọa độ sân cầu.
* **Redis:** Lưu trữ Leaderboard theo thời gian thực (`Sorted Sets`) và hàng đợi ghép kèo.


* **Tích hợp bên thứ ba:** Google Login / Apple Sign-In, Firebase Cloud Messaging (Push Notification khi có người vào kèo), Apple HealthKit & Google Health Connect.



#### 3. Lộ trình Phát triển 4 - 6 Tháng (Product Roadmap)

* **Giai đoạn 1 (Tháng 1 - 2): Core Loop & Social Feed (Nền móng)**
* Hoàn thiện luồng Tạo kèo / Vào kèo (`Matchmaking`), Ghi nhận tỉ số (`Match Logging`), thuật toán tính điểm Elo/Glicko-2 cơ bản cho đánh Đơn và Đôi, và cấp phát "Hộ chiếu cầu lông" (`Profile`).




* **Giai đoạn 2 (Tháng 3 - 4): Gamification, Anti-Smurf & Health Sync (Giữ chân)**
* Triển khai Bảng xếp hạng theo từng sân đấu theo mùa/tuần (Duolingo-style League), hệ thống Điểm Uy Tín (`Trust Score`) tự động phạt khi bùng kèo/tranh chấp, xác thực vị trí GPS tại sân (Geofencing), và đồng bộ nhịp tim/calo từ đồng hồ thông minh.




* **Giai đoạn 3 (Tháng 5 - 6): Mini-Tournaments & Community Scaling (Mở rộng)**
* Mở khóa tính năng Tạo giải đấu thu nhỏ (Mini-tournament/Round Robin) cho các CLB sinh viên, tự động phân hạt giống dựa trên điểm Elo sẵn có, xuất thẻ ảnh thành tích (Shareable Bento Card) lên mạng xã hội.


---