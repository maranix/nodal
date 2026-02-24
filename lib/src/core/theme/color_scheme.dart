part of 'theme.dart';

/// Contract for a complete set of semantic application colors.
///
/// Implement this to define a new color scheme (e.g., light, dark, high-contrast).
/// Each scheme is composed into [AppThemeData] and resolved at runtime based on
/// platform brightness.
///
/// ```dart
/// final class MyCustomColorScheme implements AppColorScheme {
///   const MyCustomColorScheme();
///
///   @override
///   Brightness get brightness => Brightness.light;
///   @override
///   Color get background => Color(0xFFF5F5DC);
///   // ...
/// }
/// ```
sealed class AppColorScheme {
  const AppColorScheme();

  /// The brightness variant this scheme represents.
  Brightness get brightness;

  /// Primary background color for scaffolds and root surfaces.
  Color get background;

  /// Elevated surface color for cards, dialogs, bottom sheets.
  Color get surface;

  /// Primary text color — high emphasis.
  Color get text;

  /// Secondary text color — medium emphasis (captions, hints).
  Color get textSecondary;

  /// Brand primary color — interactive elements, app bars, links.
  Color get primary;

  /// Primary button fill color.
  Color get primaryButton;

  /// Subtle border/divider color.
  Color get border;

  /// Error/destructive action color.
  Color get error;
}

/// Light color scheme.
final class LightColorScheme extends AppColorScheme {
  const LightColorScheme();

  @override
  Brightness get brightness => Brightness.light;

  @override
  Color get background => Colors.white;

  @override
  Color get surface => const Color(0xFFF5F5F5);

  @override
  Color get text => const Color(0xFF1A1A1A);

  @override
  Color get textSecondary => const Color(0xFF6B6B6B);

  @override
  Color get primary => const Color(0xFF007AFF);

  @override
  Color get primaryButton => Colors.lightCyan;

  @override
  Color get border => const Color(0xFFE0E0E0);

  @override
  Color get error => const Color(0xFFFF3B30);
}

/// Dark color scheme.
final class DarkColorScheme extends AppColorScheme {
  const DarkColorScheme();

  @override
  Brightness get brightness => Brightness.dark;

  @override
  Color get background => const Color(0xFF121212);

  @override
  Color get surface => const Color(0xFF1E1E1E);

  @override
  Color get text => const Color(0xFFF0F0F0);

  @override
  Color get textSecondary => const Color(0xFF9E9E9E);

  @override
  Color get primary => const Color(0xFF64B5F6);

  @override
  Color get primaryButton => const Color(0xFF00838F);

  @override
  Color get border => const Color(0xFF333333);

  @override
  Color get error => const Color(0xFFCF6679);
}
