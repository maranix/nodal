part of 'theme.dart';

/// Defines the text styles used throughout the application.
///
/// Text scaling is automatically handled by Flutter's [Text] widget via
/// [MediaQuery.textScalerOf]. Styles here define base logical font sizes;
/// they are not pre-scaled.
///
/// Construct with a text [Color] that matches the active color scheme:
/// ```dart
/// final textTheme = AppTextTheme(color: colorScheme.text);
/// ```
final class AppTextTheme {
  const AppTextTheme({required Color color}) : _color = color;

  final Color _color;

  TextStyle get displayLarge => TextStyle(
    fontSize: 57,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.25,
    height: 1.12,
    color: _color,
  );

  TextStyle get displayMedium => TextStyle(
    fontSize: 45,
    fontWeight: FontWeight.w400,
    height: 1.16,
    color: _color,
  );

  TextStyle get displaySmall => TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w400,
    height: 1.22,
    color: _color,
  );

  TextStyle get titleLarge => TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.27,
    color: _color,
  );

  TextStyle get titleMedium => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.15,
    height: 1.50,
    color: _color,
  );

  TextStyle get titleSmall => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.43,
    color: _color,
  );

  TextStyle get bodyLarge => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    height: 1.50,
    color: _color,
  );

  TextStyle get bodyMedium => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    height: 1.43,
    color: _color,
  );

  TextStyle get bodySmall => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.33,
    color: _color,
  );

  TextStyle get labelLarge => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.43,
    color: _color,
  );

  TextStyle get labelMedium => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.33,
    color: _color,
  );

  TextStyle get labelSmall => TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.45,
    color: _color,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppTextTheme &&
          runtimeType == other.runtimeType &&
          _color == other._color;

  @override
  int get hashCode => _color.hashCode;
}
