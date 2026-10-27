class SportNotice {
  const SportNotice({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    this.readAt,
    this.roomId,
    this.kind,
  });

  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime? readAt;
  final String? roomId;
  final String? kind;

  bool get isRead => readAt != null;

  factory SportNotice.fromJson(Map<String, dynamic> json) {
    final kindStr = json['kind'] as String? ?? 'GENERAL';
    String genTitle = 'Thông báo hệ thống';
    String genContent = 'Bạn có cập nhật mới từ SportXP.';

    switch (kindStr) {
      case 'PROMOTED':
        genTitle = 'Lên danh sách thi đấu chính thức';
        genContent = 'Bạn đã được chuyển từ danh sách chờ vào phòng chơi thành công!';
        break;
      case 'MEMBER_LEFT':
        genTitle = 'Thành viên rời phòng';
        genContent = 'Một thành viên vừa rời phòng đấu của bạn. Slot đã được mở lại.';
        break;
      case 'ROOM_UPDATED':
        genTitle = 'Điều kiện phòng thay đổi';
        genContent = 'Chủ phòng vừa cập nhật giờ hoặc sân đấu. Vui lòng xác nhận lại.';
        break;
      case 'ROOM_CANCELED':
        genTitle = 'Kèo đấu đã bị hủy';
        genContent = 'Chủ phòng đã hủy buổi chơi này.';
        break;
      case 'FRIEND_REQUEST':
        genTitle = 'Lời mời kết bạn mới';
        genContent = json['content'] as String? ?? 'Có người chơi vừa gửi lời mời kết bạn.';
        break;
      default:
        genTitle = json['title'] as String? ?? 'Thông báo';
        genContent = json['content'] as String? ?? 'Bạn có tin nhắn mới.';
    }

    return SportNotice(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: genTitle,
      content: genContent,
      roomId: json['room_id'] as String?,
      kind: kindStr,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '')?.toLocal() ?? DateTime.now(),
      readAt: DateTime.tryParse(json['read_at'] as String? ?? '')?.toLocal(),
    );
  }
}
