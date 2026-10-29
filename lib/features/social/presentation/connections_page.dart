import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/bento_card.dart';
import '../data/social_repository.dart';
import '../domain/social_profile.dart';

class ConnectionsPage extends StatefulWidget {
  const ConnectionsPage({
    super.key,
    required this.repository,
    required this.onOpen,
  });

  final SocialRepository repository;
  final Future<void> Function(String) onOpen;

  @override
  State<ConnectionsPage> createState() => _ConnectionsPageState();
}

class _ConnectionsPageState extends State<ConnectionsPage> {
  String _kind = 'incoming'; // Mặc định mở tab Lời mời đến trước để user duyệt nhanh
  List<SocialProfile> _items = [];
  int _incomingCount = 0;
  bool _busy = true, _more = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkIncomingBadge();
    _load(reset: true);
  }

  // Tải trước số lượng lời mời kết bạn để hiển thị Badge đỏ
  Future<void> _checkIncomingBadge() async {
    try {
      final incoming = await widget.repository.connections('incoming');
      if (mounted) {
        setState(() => _incomingCount = incoming.length);
      }
    } catch (_) {}
  }

  Future<void> _load({bool reset = false}) async {
    final kind = _kind;
    setState(() {
      _busy = true;
      _error = null;
      if (reset) {
        _items = [];
        _more = true;
      }
    });

    try {
      final rows = await widget.repository.connections(
        kind,
        offset: _items.length,
      );
      if (mounted && kind == _kind) {
        setState(() {
          _items.addAll(rows);
          _more = rows.length == 50;
        });
        if (kind == 'incoming') {
          setState(() => _incomingCount = rows.length);
        }
      }
    } catch (_) {
      if (mounted && kind == _kind) {
        setState(() => _error = 'Chưa tải được kết nối. Vui lòng thử lại.');
      }
    } finally {
      if (mounted && kind == _kind) setState(() => _busy = false);
    }
  }

  Future<void> _handleAction(String publicId, String action, String name) async {
    try {
      await widget.repository.action(publicId, action);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primary,
            content: Text(
              action == 'accept'
                  ? 'Đã đồng ý kết bạn với $name.'
                  : action == 'reject'
                  ? 'Đã từ chối lời mời từ $name.'
                  : 'Đã hủy kết bạn với $name.',
            ),
          ),
        );
        _checkIncomingBadge();
        _load(reset: true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.loss,
            content: Text('Thao tác không thành công. Vui lòng thử lại.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'BẠN BÈ & LỜI MỜI',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: PageContent(
        children: [
          // Filter Tabs với Badge thông báo lời mời đến
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildTabChip(
                  key: 'incoming',
                  label: 'Lời mời đến',
                  badgeCount: _incomingCount,
                ),
                const SizedBox(width: 8),
                _buildTabChip(key: 'friends', label: 'Bạn bè'),
                const SizedBox(width: 8),
                _buildTabChip(key: 'outgoing', label: 'Đã gửi'),
                const SizedBox(width: 8),
                _buildTabChip(key: 'blocked', label: 'Đã chặn'),
              ],
            ),
          ),

          // Loading indicator
          if (_busy && _items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                ),
              ),
            )
          // Empty State
          else if (!_busy && _items.isEmpty && _error == null)
            BentoCard(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                child: Column(
                  children: [
                    Icon(
                      _kind == 'incoming'
                          ? Icons.mark_email_read_outlined
                          : _kind == 'friends'
                          ? Icons.people_outline
                          : Icons.person_search_outlined,
                      size: 40,
                      color: AppColors.muted,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _kind == 'incoming'
                          ? 'Không có lời mời kết bạn nào'
                          : _kind == 'friends'
                          ? 'Chưa có bạn bè trong danh sách'
                          : 'Không có dữ liệu',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _kind == 'incoming'
                          ? 'Khi người chơi khác quét mã QR của bạn, lời mời sẽ hiển thị tại đây.'
                          : 'Hãy quét mã QR của đối thủ hoặc đồng đội tại sân để kết bạn.',
                      style: const TextStyle(fontSize: 12, color: AppColors.muted),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          // List connections
          else
            for (final p in _items)
              BentoCard(
                child: Row(
                  children: [
                    // Avatar tròn với chữ cái đầu
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.mint,
                      child: Text(
                        p.name.isNotEmpty ? p.name.substring(0, 1).toUpperCase() : '?',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          await widget.onOpen(p.publicId);
                          if (mounted) _load(reset: true);
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.name,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              p.statsVisible
                                  ? '${p.elo ?? '—'} ELO • ${p.tier ?? 'Nhập môn'}'
                                  : 'Hồ sơ giới hạn xem',
                              style: const TextStyle(fontSize: 11.5, color: AppColors.muted),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Actions tương ứng theo từng tab
                    if (_kind == 'incoming') ...[
                      IconButton(
                        onPressed: () => _handleAction(p.publicId, 'reject', p.name),
                        icon: const Icon(Icons.close_rounded, color: AppColors.loss, size: 20),
                        tooltip: 'Từ chối',
                      ),
                      IconButton(
                        onPressed: () => _handleAction(p.publicId, 'accept', p.name),
                        icon: const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 24),
                        tooltip: 'Đồng ý',
                      ),
                    ] else if (_kind == 'friends') ...[
                      IconButton(
                        onPressed: () async {
                          await widget.onOpen(p.publicId);
                          if (mounted) _load(reset: true);
                        },
                        icon: const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
                        tooltip: 'Xem hồ sơ',
                      ),
                    ] else if (_kind == 'outgoing') ...[
                      TextButton(
                        onPressed: () => _handleAction(p.publicId, 'cancel', p.name),
                        child: const Text('Hủy lời mời', style: TextStyle(fontSize: 11, color: AppColors.loss)),
                      ),
                    ] else if (_kind == 'blocked') ...[
                      TextButton(
                        onPressed: () => _handleAction(p.publicId, 'unblock', p.name),
                        child: const Text('Bỏ chặn', style: TextStyle(fontSize: 11)),
                      ),
                    ],
                  ],
                ),
              ),

          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(_error!, style: const TextStyle(color: AppColors.loss, fontSize: 12)),
            ),

          if (!_busy && _more && _items.isNotEmpty)
            Center(
              child: TextButton(
                onPressed: () => _load(reset: false),
                child: const Text('Xem thêm'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTabChip({
    required String key,
    required String label,
    int badgeCount = 0,
  }) {
    final selected = _kind == key;
    return ChoiceChip(
      selected: selected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (badgeCount > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                color: selected ? AppColors.surface : AppColors.loss,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$badgeCount',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: selected ? AppColors.loss : AppColors.surface,
                ),
              ),
            ),
          ],
        ],
      ),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: selected ? FontWeight.bold : FontWeight.w500,
        color: selected ? AppColors.surface : AppColors.text,
      ),
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surface,
      side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onSelected: _busy
          ? null
          : (_) {
              setState(() => _kind = key);
              _load(reset: true);
            },
    );
  }
}
