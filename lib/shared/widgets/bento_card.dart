import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class BentoCard extends StatelessWidget {
  const BentoCard({super.key, required this.child, this.highlighted = false});
  final Widget child;
  final bool highlighted;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppTokens.radius),
      side: const BorderSide(color: AppColors.border),
    ),
    clipBehavior: Clip.antiAlias,
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: highlighted
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: [0, 0.65],
                colors: [AppColors.mint, AppColors.surface],
              )
            : null,
      ),
      child: SizedBox(
        width: double.infinity,
        child: Padding(padding: const EdgeInsets.all(20), child: child),
      ),
    ),
  );
}

class PageContent extends StatelessWidget {
  const PageContent({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: AppTokens.contentWidth),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: children.length,
        separatorBuilder: (_, _) => const SizedBox(height: 16),
        itemBuilder: (_, index) => children[index],
      ),
    ),
  );
}
