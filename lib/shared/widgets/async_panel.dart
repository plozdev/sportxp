import 'package:flutter/material.dart';
import 'bento_card.dart';

class AsyncPanel<T> extends StatelessWidget {
  const AsyncPanel({
    super.key,
    required this.future,
    required this.onRetry,
    required this.builder,
  });
  final Future<T> future;
  final VoidCallback onRetry;
  final Widget Function(T) builder;
  @override
  Widget build(BuildContext context) => FutureBuilder<T>(
    future: future,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(),
          ),
        );
      }
      if (snapshot.hasError) {
        return PageContent(
          children: [
            BentoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Không thể tải dữ liệu. Kiểm tra kết nối và thử lại.',
                  ),
                  TextButton(onPressed: onRetry, child: const Text('Thử lại')),
                ],
              ),
            ),
          ],
        );
      }
      return builder(snapshot.data as T);
    },
  );
}
