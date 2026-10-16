import 'package:flutter/material.dart';

/// Brand theme — mirrors the iOS app's pink/serif identity. Adapts to light/dark.
class NYTheme {
  static const Color pink = Color(0xFFF2669A);
  static const Color pinkDark = Color(0xFFD9477F);

  static const TextStyle screenTitle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
  );

  static ThemeData light() => _base(Brightness.light);
  static ThemeData dark() => _base(Brightness.dark);

  static ThemeData _base(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: pink,
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: const AppBarTheme(centerTitle: true),
    );
  }
}
