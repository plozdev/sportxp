import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../social/domain/profile_link.dart';
import '../../domain/player_profile.dart';

class PassportSheet extends StatelessWidget {
  const PassportSheet({super.key, required this.profile});
  final PlayerProfile profile;

  @override
  Widget build(BuildContext context) {
    final id = profile.publicId;
    final link = id == null ? null : ProfileLink.build(id);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'MÃ HỘ CHIẾU CỦA TÔI',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    tooltip: 'Đóng',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                profile.displayName,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                '${profile.eloRating ?? '—'} ELO · ${profile.tierName}',
                style: const TextStyle(color: AppColors.muted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              if (link != null) ...[
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: QrImageView(
                    data: link,
                    size: 220,
                    backgroundColor: Colors.white,
                    semanticsLabel: 'Mã QR mở hồ sơ ${profile.displayName}',
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Quét để xem hồ sơ và gửi lời mời.\nChỉ kết bạn khi cả hai đồng ý.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: SelectableText(link, textAlign: TextAlign.center),
                ),
                const SizedBox(height: 16),
                Builder(
                  builder: (buttonContext) => SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.share),
                      label: const Text('CHIA SẺ LINK HỒ SƠ'),
                      onPressed: () async {
                        try {
                          final box =
                              buttonContext.findRenderObject() as RenderBox?;
                          await SharePlus.instance.share(
                            ShareParams(
                              text: link,
                              sharePositionOrigin: box == null
                                  ? null
                                  : box.localToGlobal(Offset.zero) & box.size,
                            ),
                          );
                        } catch (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Chưa thể chia sẻ. Bạn có thể sao chép link.',
                                ),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    icon: const Icon(Icons.copy),
                    label: const Text('SAO CHÉP LINK'),
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: link));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đã sao chép link hồ sơ.'),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ] else
                const Text(
                  'Chưa có mã hồ sơ. Cần áp dụng migration social trên Supabase rồi tải lại.',
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
