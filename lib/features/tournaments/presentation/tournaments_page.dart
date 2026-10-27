import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/bento_card.dart';
import '../data/tournament_repository.dart';
import '../domain/tournament.dart';

class TournamentsPage extends StatefulWidget {
  const TournamentsPage({super.key, this.client});
  final SupabaseClient? client;

  @override
  State<TournamentsPage> createState() => _TournamentsPageState();
}

class _TournamentsPageState extends State<TournamentsPage> {
  late final TournamentRepository _repository;
  String _selectedFilter = 'all'; // 'all', 'registering', 'ongoing', 'completed'
  List<Tournament> _tournaments = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _repository = SupabaseTournamentRepository(
      widget.client ?? Supabase.instance.client,
    );
    _loadTournaments();
  }

  Future<void> _loadTournaments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _repository.listTournaments(filter: _selectedFilter);
      if (mounted) {
        setState(() {
          _tournaments = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Không thể tải danh sách giải đấu.';
          _isLoading = false;
        });
      }
    }
  }

  void _showRegisterSheet(Tournament tournament) {
    final messenger = ScaffoldMessenger.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _RegisterTournamentSheet(
        tournament: tournament,
        onConfirmed: () async {
          Navigator.pop(sheetContext);
          try {
            await _repository.registerTournament(tournament.id);
            messenger.showSnackBar(
              SnackBar(
                backgroundColor: AppColors.primary,
                content: Text('Đã gửi đăng ký tham gia "${tournament.title}".'),
              ),
            );
            if (mounted) _loadTournaments();
          } catch (e) {
            messenger.showSnackBar(
              SnackBar(
                backgroundColor: AppColors.loss,
                content: Text(e is AuthException ? e.message : 'Đăng ký không thành công.'),
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageContent(
      children: [
        // 1. HERO BANNER: Tập trung vào Vận động viên & Điểm Elo chuẩn
        BentoCard(
          highlighted: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.emoji_events_rounded,
                      size: 26,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ĐẤU TRƯỜNG TRANH CÚP',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.9,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Giải Đấu Phong Trào',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Thi đấu tranh cúp và huy chương. Kết quả có trọng tài xác nhận và được cộng điểm Elo chính thức với trọng số cao nhất.',
                style: TextStyle(fontSize: 13, color: AppColors.muted, height: 1.4),
              ),
            ],
          ),
        ),

        // 2. BỘ LỌC TRẠNG THÁI (Filter Pills)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('all', 'Tất cả giải'),
              const SizedBox(width: 8),
              _buildFilterChip('registering', 'Đang mở đăng ký'),
              const SizedBox(width: 8),
              _buildFilterChip('ongoing', 'Đang diễn ra'),
            ],
          ),
        ),

        // 3. DANH SÁCH GIẢI ĐẤU
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary),
              ),
            ),
          )
        else if (_errorMessage != null)
          BentoCard(
            child: Column(
              children: [
                const Icon(Icons.error_outline, color: AppColors.loss, size: 36),
                const SizedBox(height: 8),
                Text(_errorMessage!, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                OutlinedButton(onPressed: _loadTournaments, child: const Text('Thử lại')),
              ],
            ),
          )
        else if (_tournaments.isEmpty)
          const BentoCard(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Icon(Icons.event_busy_rounded, size: 40, color: AppColors.muted),
                  SizedBox(height: 8),
                  Text('Hiện chưa có giải đấu nào trong mục này.', style: TextStyle(color: AppColors.muted)),
                ],
              ),
            ),
          )
        else
          for (final tour in _tournaments)
            _TournamentCard(
              tournament: tour,
              onRegister: () => _showRegisterSheet(tour),
            ),
      ],
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final selected = _selectedFilter == value;
    return ChoiceChip(
      selected: selected,
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 12.5,
        fontWeight: selected ? FontWeight.bold : FontWeight.w500,
        color: selected ? AppColors.surface : AppColors.text,
      ),
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surface,
      side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onSelected: (_) {
        setState(() => _selectedFilter = value);
        _loadTournaments();
      },
    );
  }
}

class _TournamentCard extends StatelessWidget {
  const _TournamentCard({
    required this.tournament,
    required this.onRegister,
  });

  final Tournament tournament;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    final isRegistering = tournament.status == 'registering';
    final isFull = tournament.isFull;

    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiêu đề & Status Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  tournament.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: isRegistering
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : AppColors.streak.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isRegistering ? 'ĐANG NHẬN ĐĂNG KÝ' : 'ĐANG THI ĐẤU',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isRegistering ? AppColors.primary : AppColors.streak,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Địa điểm & Khung giờ
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(Icons.location_on_outlined, size: 14, color: AppColors.muted),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  tournament.venueName,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.text),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.calendar_month_outlined, size: 14, color: AppColors.muted),
              const SizedBox(width: 5),
              Text(
                'Khởi tranh: ${_formatDate(tournament.startDate)}',
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),

          // Thông số giải (Format, Rank yêu cầu, Giải thưởng, Slot)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SpecBadge(icon: Icons.sports_tennis, text: tournament.formatLabel),
              _SpecBadge(icon: Icons.military_tech_outlined, text: 'Hạng: ${tournament.rankRequirement}'),
              if (tournament.prizePool > 0)
                _SpecBadge(
                  icon: Icons.monetization_on_outlined,
                  text: 'Thưởng: ${_formatCurrency(tournament.prizePool)}',
                  highlight: true,
                ),
              _SpecBadge(
                icon: Icons.group_outlined,
                text: 'Chỗ: ${tournament.currentSlots}/${tournament.maxSlots}',
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Nút hành động đăng ký
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: isRegistering && !isFull ? onRegister : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                isFull
                    ? 'ĐÃ ĐỦ CHỖ ĐĂNG KÝ'
                    : isRegistering
                    ? 'ĐĂNG KÝ THAM GIA'
                    : 'XEM BẢNG ĐẤU & KẾT QUẢ',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  String _formatCurrency(double amount) {
    return '${(amount / 1000000).toStringAsFixed(1).replaceAll('.0', '')}tr';
  }
}

class _SpecBadge extends StatelessWidget {
  const _SpecBadge({
    required this.icon,
    required this.text,
    this.highlight = false,
  });

  final IconData icon;
  final String text;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: highlight ? AppColors.streak.withValues(alpha: 0.12) : AppColors.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: highlight ? AppColors.streak.withValues(alpha: 0.3) : AppColors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: highlight ? AppColors.streak : AppColors.muted,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: highlight ? AppColors.streak : AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}

class _RegisterTournamentSheet extends StatelessWidget {
  const _RegisterTournamentSheet({
    required this.tournament,
    required this.onConfirmed,
  });

  final Tournament tournament;
  final VoidCallback onConfirmed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Xác nhận đăng ký giải',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            tournament.title,
            style: const TextStyle(fontSize: 14, color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          _detailRow('Sân đấu', tournament.venueName),
          _detailRow('Thể thức', tournament.formatLabel),
          _detailRow('Yêu cầu rank', tournament.rankRequirement),
          _detailRow('Lệ phí', tournament.entryFee == 0 ? 'Miễn phí' : '${tournament.entryFee.toInt()} VNĐ'),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onConfirmed,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('GỬI ĐĂNG KÝ VẬN ĐỘNG VIÊN', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.muted)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
