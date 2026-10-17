import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import 'sport_xp_shell.dart';

class SportXpApp extends StatelessWidget {
  const SportXpApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'SportXP',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.dark,
    home: const SportXpShell(),
  );
}
