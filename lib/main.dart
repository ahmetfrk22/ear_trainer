import 'package:flutter/material.dart';
import 'features/home/home_screen.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/app_gradient_background.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Müzik Kulağı',
      debugShowCheckedModeBanner: false,
      color: const Color(0xFF008080),
      theme: AppTheme.light(),
      darkTheme: AppTheme.light(),
      themeMode: ThemeMode.dark,
      home: const HomeScreen(),
      builder: (context, child) {
        return AppGradientBackground(child: child ?? const SizedBox.shrink());
      },
    );
  }
}