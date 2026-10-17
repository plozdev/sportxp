import 'package:flutter/material.dart';
import '../../../shared/widgets/bento_card.dart';

class TournamentsPage extends StatelessWidget {
  const TournamentsPage({super.key});
  @override
  Widget build(BuildContext context) => const PageContent(
    children: [
      BentoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.emoji_events_outlined, size: 32),
            SizedBox(height: 16),
            Text('Giải đấu phong trào'),
            SizedBox(height: 8),
            Text(
              'Sắp ra mắt. Tạo giải, theo dõi bảng đấu và ghi nhận thành tích tại đây.',
            ),
          ],
        ),
      ),
    ],
  );
}
