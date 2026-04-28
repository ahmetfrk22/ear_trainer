import 'package:flutter/material.dart';

extension ColorOpacitySafe on Color {
  /// Flutter'ın deprecated `withOpacity` yerine, alpha'yı 0..255 aralığında
  /// tam sayı olarak güncelleyerek precision loss'u önler.
  Color withOpacitySafe(double opacity) {
    final clamped = opacity.clamp(0.0, 1.0);
    final nextAlpha =
        ((a * 255.0) * clamped).round().clamp(0, 255).toDouble();
    return withValues(alpha: nextAlpha);
  }
}

