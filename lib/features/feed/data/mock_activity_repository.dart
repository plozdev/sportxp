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
}

/// Owns post content, not match results. Summary is derived on every read so a
/// late confirmation updates all related posts without overwriting captions.
class MockActivityRepository implements ActivityRepository {
  MockActivityRepository(this.source) : _generation = source.generation;
  final ActivityLogSource source;
  int _generation;
  final Map<String, _Post> _posts = {};
  final Map<String, String> _receipts = {};
  void _sync() {
    if (_generation != source.generation) {
      _posts.clear();
      _receipts.clear();
      _generation = source.generation;
    }
    for (final log in source.activityLogs()) {
      if (log.players.contains(source.actorId)) {
        _ensure(log, ActivityKind.personal);
      }
      if (log.hostId == source.actorId) _ensure(log, ActivityKind.hostSummary);
    }
  }

  void _ensure(ActivityLog log, ActivityKind kind) {
    final id = '${log.roomId}:${source.actorId}:${kind.name}';
    // Tombstones intentionally prevent a deleted post being recreated by sync.
    _posts.putIfAbsent(id, () => _Post(id, log.roomId, source.actorId, kind));
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
      likeCount: p.likes
          .where(
            (id) =>
                id == p.authorId ||
                (!source.isBlocked(p.authorId, id) &&
                    source.areFriends(p.authorId, id)),
          )
          .length,
      totals: ActivityTotals(
        confirmed: confirmed.length,
        pending: matches.where((m) => m.status == 'PENDING').length,
        disputed: matches.where((m) => m.status == 'DISPUTED').length,
        voided: matches.where((m) => m.status == 'VOID').length,
        wins: personal ? wins : null,
        losses: personal ? confirmed.length - wins : null,
      ),
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
