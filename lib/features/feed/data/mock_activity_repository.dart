import 'dart:convert';

import '../../rooms/data/managed_room_repository.dart';
import '../domain/activity.dart';

class _Post {
  _Post(this.id, this.roomId, this.authorId, this.kind);
  final String id, roomId, authorId;
  final ActivityKind kind;
  String caption = '';
  ActivityAudience audience = ActivityAudience.onlyMe;
  DateTime? publishedAt;
  String? publishedResults;
  int version = 1;
  bool deleted = false;
  final Set<String> likes = {};
  String sportType = 'badminton';
  int? durationMinutes;
  int? calories;
  int? avgHeartRate;
  int? maxHeartRate;
  double? distanceKm;
  String? pace;
  String? deviceSource;
  List<String> matchScores = const [];
  int commentCount = 0;
}

/// Owns post content, not match results. Summary is derived on every read so a
/// late confirmation updates all related posts without overwriting captions.
class MockActivityRepository implements ActivityRepository {
  factory MockActivityRepository(ActivityLogSource source) =>
      _instances[source] ??= MockActivityRepository._(source);
  MockActivityRepository._(this.source);
  // Every route must share posts with Home, not create its own detached store.
  static final _instances = Expando<MockActivityRepository>();
  final ActivityLogSource source;
  int _generation = -1;
  final Map<String, _Post> _posts = {};
  final Map<String, String> _receipts = {};
  void _sync() {
    if (_generation != source.generation) {
      _posts.clear();
      _receipts.clear();
      _generation = source.generation;
      _seedInitialActivities();
    }
    // Also ensure any new completed rooms dynamically get posts
    for (final log in source.activityLogs()) {
      for (final p in log.players) {
        _ensure(log, p, ActivityKind.personal);
      }
      _ensure(log, log.hostId, ActivityKind.hostSummary);
    }
  }

  void _seedInitialActivities() {
    final logs = {for (final log in source.activityLogs()) log.roomId: log};

    // 1. Linh smash (Court 0 Đào Duy Anh, 2 hours ago)
    _seedPost(
      roomId: 'room-linh-smash',
      authorId: 'linh',
      kind: ActivityKind.personal,
      caption: 'Hôm nay cuối cùng cũng đỡ được smash của Minh 😅',
      audience: ActivityAudience.friends,
      likes: {source.ownerId, 'minh', 'an', 'bao'},
      hoursAgo: 2,
      logs: logs,
      sportType: 'badminton',
      durationMinutes: 105,
      calories: 580,
      avgHeartRate: 148,
      maxHeartRate: 178,
      deviceSource: 'Apple Watch Ultra 2',
      matchScores: ['21-19', '21-18', '19-21', '22-20'],
      commentCount: 4,
    );

    // 2. Minh running (Conditioning 5.2km, 4 hours ago)
    _seedPost(
      roomId: 'room-minh-running',
      authorId: 'minh',
      kind: ActivityKind.personal,
      caption: '5km chạy thả lỏng phục hồi sau buổi cầu hôm qua. Chân cẳng đã nhẹ hơn nhiều 🏃💨',
      audience: ActivityAudience.friends,
      likes: {source.ownerId, 'linh', 'bao'},
      hoursAgo: 4,
      logs: logs,
      sportType: 'running',
      distanceKm: 5.2,
      pace: '5:26',
      durationMinutes: 28,
      calories: 365,
      avgHeartRate: 152,
      maxHeartRate: 168,
      deviceSource: 'Garmin Forerunner 965',
      commentCount: 3,
    );

    // 3. User comeback (Court 1 Bình Thạnh, 5 hours ago)
    _seedPost(
      roomId: 'room-user-comeback',
      authorId: source.ownerId,
      kind: ActivityKind.personal,
      caption: 'Set cuối kịch tính thở không ra hơi nhưng vẫn lội ngược dòng 24-22 🔥',
      audience: ActivityAudience.friends,
      likes: {'linh', 'minh', 'an'},
      hoursAgo: 5,
      logs: logs,
      sportType: 'badminton',
      durationMinutes: 90,
      calories: 520,
      avgHeartRate: 155,
      maxHeartRate: 182,
      deviceSource: 'Apple Watch Series 9',
      matchScores: ['19-21', '21-18', '24-22'],
      commentCount: 5,
    );

    // 4. Bảo conditioning workout (45 mins footwork, 10 hours ago)
    _seedPost(
      roomId: 'room-bao-workout',
      authorId: 'bao',
      kind: ActivityKind.personal,
      caption: '45 phút ép di chuyển 6 góc sân + nhảy dây 1000 cái. Mồ hôi ướt đẫm áo 💦',
      audience: ActivityAudience.friends,
      likes: {'minh', 'linh', source.ownerId},
      hoursAgo: 10,
      logs: logs,
      sportType: 'workout',
      durationMinutes: 45,
      calories: 410,
      avgHeartRate: 140,
      maxHeartRate: 165,
      deviceSource: 'WHOOP 4.0',
      commentCount: 2,
    );

    // 5. Minh smash defeat (Court 2 Thủ Đức, 18 hours ago)
    _seedPost(
      roomId: 'room-minh-smash',
      authorId: 'minh',
      kind: ActivityKind.personal,
      caption: 'Bảo hôm nay smash cháy quá, đập quả nào cắm quả đó 🏸 Chịu thua tâm phục khẩu phục!',
      audience: ActivityAudience.friends,
      likes: {'bao', 'linh', 'an', source.ownerId},
      hoursAgo: 18,
      logs: logs,
      sportType: 'badminton',
      durationMinutes: 80,
      calories: 490,
      avgHeartRate: 146,
      maxHeartRate: 174,
      deviceSource: 'Garmin Forerunner 965',
      matchScores: ['21-18', '16-21', '19-21', '21-19'],
      commentCount: 3,
    );

    // 6. Host Linh recap (Court 0 Đào Duy Anh, 24 hours ago)
    _seedPost(
      roomId: 'room-host-linh-recap',
      authorId: 'linh',
      kind: ActivityKind.hostSummary,
      caption: 'Tổng kết buổi sinh hoạt CLB Thứ Bảy: 5 tay vợt, 5 set đấu căng thẳng từ 8h sáng tới trưa. Cảm ơn cả nhà đã tới đúng giờ!',
      audience: ActivityAudience.friends,
      likes: {'minh', 'bao', 'an', source.ownerId},
      hoursAgo: 24,
      logs: logs,
      sportType: 'badminton',
      durationMinutes: 180,
      calories: 820,
      avgHeartRate: 135,
      maxHeartRate: 169,
      deviceSource: 'SportXP Club Tracker',
      matchScores: ['21-15', '21-17', '18-21', '21-19', '21-16'],
      commentCount: 7,
    );

    // 7. An test vợt (Court 1 Bình Thạnh, 48 hours ago, 1 pending match)
    _seedPost(
      roomId: 'room-an-pending',
      authorId: 'an',
      kind: ActivityKind.personal,
      caption: 'Buổi đầu tiên thử nghiệm vợt mới, cảm giác cầu thoát tay hơn hẳn. Minh nhớ vào duyệt kết quả set 2 nha!',
      audience: ActivityAudience.friends,
      likes: {source.ownerId, 'linh'},
      hoursAgo: 48,
      logs: logs,
      sportType: 'badminton',
      durationMinutes: 65,
      calories: 380,
      avgHeartRate: 138,
      maxHeartRate: 162,
      deviceSource: 'Galaxy Watch 6',
      matchScores: ['21-16', '18-21', '21-19'],
      commentCount: 2,
    );

    // 8. User private practice (Court 2 Thủ Đức, 72 hours ago, Only me)
    _seedPost(
      roomId: 'room-user-private',
      authorId: source.ownerId,
      kind: ActivityKind.personal,
      caption: 'Tự ghi chép buổi tập bổ trợ di chuyển chân và đập cầu góc xa. Còn hụt hơi cuối set.',
      audience: ActivityAudience.onlyMe,
      likes: {},
      hoursAgo: 72,
      logs: logs,
      sportType: 'badminton',
      durationMinutes: 60,
      calories: 350,
      avgHeartRate: 130,
      maxHeartRate: 155,
      deviceSource: 'Apple Watch Series 9',
      matchScores: ['15-21', '18-21'],
      commentCount: 0,
    );

    // 9. Bảo pro check (Court 0 Đào Duy Anh, 96 hours ago)
    _seedPost(
      roomId: 'room-bao-pro',
      authorId: 'bao',
      kind: ActivityKind.personal,
      caption: 'Giao lưu kiểm tra phong độ trước thềm giải đấu tháng tới. Các bạn trẻ dạo này cổ tay dẻo quá 🚀',
      audience: ActivityAudience.friends,
      likes: {'linh', 'minh', 'an', source.ownerId},
      hoursAgo: 96,
      logs: logs,
      sportType: 'badminton',
      durationMinutes: 95,
      calories: 610,
      avgHeartRate: 156,
      maxHeartRate: 184,
      deviceSource: 'Apple Watch Ultra 2',
      matchScores: ['21-18', '21-16', '21-14'],
      commentCount: 6,
    );
  }

  void _seedPost({
    required String roomId,
    required String authorId,
    required ActivityKind kind,
    required String caption,
    required ActivityAudience audience,
    required Set<String> likes,
    required int hoursAgo,
    required Map<String, ActivityLog> logs,
    String sportType = 'badminton',
    int? durationMinutes,
    int? calories,
    int? avgHeartRate,
    int? maxHeartRate,
    double? distanceKm,
    String? pace,
    String? deviceSource,
    List<String> matchScores = const [],
    int commentCount = 0,
  }) {
    final log = logs[roomId];
    if (log == null) return;
    final id = '$roomId:$authorId:${kind.name}';
    final post = _Post(id, roomId, authorId, kind)
      ..caption = caption
      ..audience = audience
      ..publishedAt = log.endedAt
      ..likes.addAll(likes)
      ..sportType = sportType
      ..durationMinutes = durationMinutes
      ..calories = calories
      ..avgHeartRate = avgHeartRate
      ..maxHeartRate = maxHeartRate
      ..distanceKm = distanceKm
      ..pace = pace
      ..deviceSource = deviceSource
      ..matchScores = matchScores
      ..commentCount = commentCount;
    post.publishedResults = _signature(post, log);
    _posts[id] = post;
  }

  void _ensure(ActivityLog log, String authorId, ActivityKind kind) {
    final id = '${log.roomId}:$authorId:${kind.name}';
    // Tombstones intentionally prevent a deleted post being recreated by sync.
    _posts.putIfAbsent(id, () => _Post(id, log.roomId, authorId, kind));
  }

  ActivityLog? _log(_Post p) {
    for (final log in source.activityLogs()) {
      if (log.roomId == p.roomId) return log;
    }
    return null;
  }

  bool _visible(_Post p) =>
      !p.deleted &&
      _log(p) != null &&
      (p.authorId == source.actorId ||
          (p.publishedAt != null &&
              p.audience == ActivityAudience.friends &&
              !source.isBlocked(p.authorId, source.actorId) &&
              source.areFriends(p.authorId, source.actorId)));
  List<ActivityMatchLog> _matches(_Post p, ActivityLog log) => log.matches
      .where(
        (m) => p.kind == ActivityKind.hostSummary || m.involves(p.authorId),
      )
      .toList();
  String _signature(_Post p, ActivityLog log) => jsonEncode([
    for (final m in _matches(p, log))
      [m.id, m.version, m.status, m.score, m.winner],
  ]);
  ActivityView _view(_Post p) {
    final log = _log(p)!;
    final matches = _matches(p, log);
    final confirmed = matches.where((m) => m.status == 'CONFIRMED').toList();
    final personal = p.kind == ActivityKind.personal;
    final wins = confirmed
        .where(
          (m) => m.winner == 'A'
              ? m.teamA.contains(p.authorId)
              : m.teamB.contains(p.authorId),
        )
        .length;
    final participant = log.participant(source.actorId);
    // Private session metadata is not automatically shared with author's friends.
    final redact = log.isPrivate && !participant;
    final likedNames = p.likes
        .where(
          (id) =>
              id == p.authorId ||
              (!source.isBlocked(p.authorId, id) &&
                  source.areFriends(p.authorId, id)),
        )
        .map((id) => source.actorNames[id] ?? id)
        .toList();

    return ActivityView(
      id: p.id,
      roomId: p.roomId,
      authorId: p.authorId,
      authorName: source.actorNames[p.authorId] ?? 'Người chơi',
      caption: p.caption,
      title: redact ? 'Buổi chơi riêng tư' : log.title,
      courtName: redact ? 'Địa điểm riêng tư' : log.courtName,
      kind: p.kind,
      audience: p.audience,
      publishedAt: p.publishedAt,
      playedAt: log.endedAt,
      version: p.version,
      resultsUpdated:
          p.publishedResults != null &&
          p.publishedResults != _signature(p, log),
      isOwner: p.authorId == source.actorId,
      canOpenLog: participant,
      liked: p.likes.contains(source.actorId),
      likeCount: likedNames.length,
      likedByNames: likedNames,
      totals: ActivityTotals(
        confirmed: confirmed.length,
        pending: matches.where((m) => m.status == 'PENDING').length,
        disputed: matches.where((m) => m.status == 'DISPUTED').length,
        voided: matches.where((m) => m.status == 'VOID').length,
        wins: personal ? wins : null,
        losses: personal ? confirmed.length - wins : null,
      ),
      sportType: p.sportType,
      durationMinutes: p.durationMinutes ?? (p.sportType == 'badminton' ? 75 : null),
      calories: p.calories ?? (p.sportType == 'badminton' ? 450 : null),
      avgHeartRate: p.avgHeartRate ?? (p.sportType == 'badminton' ? 142 : null),
      maxHeartRate: p.maxHeartRate ?? (p.sportType == 'badminton' ? 172 : null),
      distanceKm: p.distanceKm,
      pace: p.pace,
      deviceSource: p.deviceSource ?? 'Apple Watch · HealthKit',
      matchScores: p.matchScores.isNotEmpty
          ? p.matchScores
          : confirmed
              .map((m) => m.score)
              .where((s) => s.isNotEmpty)
              .toList(),
      commentCount: p.commentCount,
    );
  }

  @override
  Future<List<ActivityView>> list({bool mine = false, int offset = 0}) async {
    _sync();
    final posts =
        _posts.values
            .where(
              (p) =>
                  p.publishedAt != null &&
                  _visible(p) &&
                  (!mine || p.authorId == source.actorId),
            )
            .toList()
          ..sort((a, b) {
            final order = b.publishedAt!.compareTo(a.publishedAt!);
            return order == 0 ? a.id.compareTo(b.id) : order;
          });
    return posts.skip(offset).take(20).map(_view).toList();
  }

  @override
  Future<List<ActivityView>> drafts() async {
    _sync();
    return _posts.values
        .where(
          (p) =>
              p.authorId == source.actorId &&
              p.publishedAt == null &&
              _visible(p),
        )
        .map(_view)
        .toList();
  }

  @override
  Future<ActivityView?> get(String id) async {
    _sync();
    final post = _posts[id];
    return post != null && _visible(post) ? _view(post) : null;
  }

  void _require(bool value, String message) {
    if (!value) throw RoomRuleException(message);
  }

  @override
  Future<void> execute(ActivityCommand c) async {
    _sync();
    final key = '${source.actorId}:${c.requestId}';
    final signature = jsonEncode([
      c.action,
      c.activityId,
      c.expectedVersion,
      c.caption,
      c.audience?.name,
      c.liked,
    ]);
    if (_receipts.containsKey(key)) {
      _require(
        _receipts[key] == signature,
        'Yêu cầu đã được dùng với nội dung khác.',
      );
      return;
    }
    final p = _posts[c.activityId];
    _require(p != null && _visible(p), 'Bài đăng không khả dụng.');
    final post = p!;
    if (c.action == 'react') {
      _require(
        post.publishedAt != null && c.liked != null,
        'Chỉ reaction bài đã đăng.',
      );
      if (c.liked!) {
        post.likes.add(source.actorId);
      } else {
        post.likes.remove(source.actorId);
      }
    } else {
      _require(post.authorId == source.actorId, 'Chỉ tác giả được sửa bài.');
      _require(
        c.expectedVersion == post.version,
        'Nội dung đã đổi. Tải lại trước khi sửa.',
      );
      if (c.action == 'delete') {
        post.deleted = true;
      } else {
        _require(
          ['save', 'publish'].contains(c.action),
          'Thao tác chưa hỗ trợ.',
        );
        _require(
          c.caption != null &&
              c.caption!.trim().length <= 2000 &&
              c.audience != null,
          'Caption tối đa 2000 ký tự và cần chọn quyền xem.',
        );
        if (c.action == 'publish') {
          _require(post.publishedAt == null, 'Bài đã được đăng.');
        }
        post.caption = c.caption!.trim();
        post.audience = c.audience!;
        if (c.action == 'publish') {
          post.publishedAt = DateTime.now();
          post.publishedResults = _signature(post, _log(post)!);
        }
      }
      post.version++;
    }
    _receipts[key] = signature;
  }
}
