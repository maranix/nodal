import 'package:flutter/widgets.dart';

part 'colors.dart';
part 'text_theme.dart';
part 'color_scheme.dart';

/// Granular aspects of [AppThemeData] used by [AppTheme] to
/// minimize unnecessary rebuilds via [InheritedModel].
///
/// When a widget depends on a specific aspect (e.g. [AppThemeAspect.background]),
/// it will only rebuild when *that* property changes — not when unrelated
/// properties are updated.
enum AppThemeAspect {
  brightness,
  background,
  surface,
  text,
  textSecondary,
  primary,
  primaryButton,
  border,
  error,
  textTheme,
}

/// Controls which theme [AppThemeProvider] resolves.
///
/// - [system] — follows the OS brightness preference.
/// - [light] — forces [AppThemeData.light()] regardless of OS.
/// - [dark] — forces [AppThemeData.dark()] regardless of OS.
/// - [toggle] — toggles between [light] & [dark] dependening on active [ThemeMode].
enum ThemeMode { system, light, dark, toggle }

/// Immutable snapshot of all resolved theme properties.
///
/// Composed from an [AppColorScheme] and a matching [AppTextTheme].
/// Create via the named constructors or by supplying a custom scheme:
///
/// ```dart
/// // OS-driven
/// final data = AppThemeData.fromBrightness(.dark);
///
/// // Custom scheme
/// final data = AppThemeData.fromColorScheme(MyBrandScheme());
/// ```
final class AppThemeData {
  const AppThemeData._({
    required this.colorScheme,
    required this.textTheme,
  });

  /// Build theme data from an arbitrary [AppColorScheme].
  factory AppThemeData.fromColorScheme(AppColorScheme colorScheme) {
    return AppThemeData._(
      colorScheme: colorScheme,
      textTheme: AppTextTheme(color: colorScheme.text),
    );
  }

  /// Resolve the appropriate theme for the given platform [brightness].
  factory AppThemeData.fromBrightness(Brightness brightness) {
    return switch (brightness) {
      .light => AppThemeData.light(),
      .dark => AppThemeData.dark(),
    };
  }

  /// Pre-configured light theme.
  factory AppThemeData.light() =>
      AppThemeData.fromColorScheme(const LightColorScheme());

  /// Pre-configured dark theme.
  factory AppThemeData.dark() =>
      AppThemeData.fromColorScheme(const DarkColorScheme());

  /// The color scheme powering this theme.
  final AppColorScheme colorScheme;

  /// The text style set matching [colorScheme].
  final AppTextTheme textTheme;

  Brightness get brightness => colorScheme.brightness;
  Color get background => colorScheme.background;
  Color get surface => colorScheme.surface;
  Color get text => colorScheme.text;
  Color get textSecondary => colorScheme.textSecondary;
  Color get primary => colorScheme.primary;
  Color get primaryButton => colorScheme.primaryButton;
  Color get border => colorScheme.border;
  Color get error => colorScheme.error;

  /// Linearly interpolates between two [AppThemeData] instances.
  ///
  /// Colors are lerped individually. [brightness] resolves
  /// to [b]'s brightness when `t >= 0.5`, [a]'s otherwise.
  static AppThemeData lerp(AppThemeData a, AppThemeData b, double t) {
    if (identical(a, b) || t == 0.0) return a;
    if (t == 1.0) return b;

    return _LerpedThemeData(
      brightness: t < 0.5 ? a.brightness : b.brightness,
      background: Color.lerp(a.background, b.background, t)!,
      surface: Color.lerp(a.surface, b.surface, t)!,
      text: Color.lerp(a.text, b.text, t)!,
      textSecondary: Color.lerp(a.textSecondary, b.textSecondary, t)!,
      primary: Color.lerp(a.primary, b.primary, t)!,
      primaryButton: Color.lerp(a.primaryButton, b.primaryButton, t)!,
      border: Color.lerp(a.border, b.border, t)!,
      error: Color.lerp(a.error, b.error, t)!,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppThemeData &&
          runtimeType == other.runtimeType &&
          colorScheme.runtimeType == other.colorScheme.runtimeType &&
          brightness == other.brightness;

  @override
  int get hashCode => Object.hash(colorScheme.runtimeType, brightness);
}

/// An [InheritedModel] that distributes [AppThemeData] down the widget tree,
/// rebuilding dependents only when the [AppThemeAspect]s they subscribed to
/// have actually changed.
///
/// Prefer the static aspect-specific helpers over [of] when a widget only
/// needs a single property — this gives the best rebuild efficiency:
///
/// ```dart
/// final bg = AppTheme.backgroundOf(context);
/// ```
class AppTheme extends InheritedModel<AppThemeAspect> {
  const AppTheme({super.key, required super.child, required this.data});

  final AppThemeData data;

  /// Returns the full [AppThemeData], subscribing to **all** aspects.
  ///
  /// Use the per-aspect helpers below when only a single property is needed.
  static AppThemeData of(BuildContext context) {
    final result = maybeOf(context);
    assert(
      result != null,
      'No AppTheme found in context. '
      'Ensure an AppThemeProvider is an ancestor of this widget.',
    );
    return result!;
  }

  /// Like [of], but returns `null` instead of asserting.
  static AppThemeData? maybeOf(BuildContext context) =>
      InheritedModel.inheritFrom<AppTheme>(context)?.data;

  static Brightness brightnessOf(BuildContext context) =>
      _aspectOf(context, .brightness).brightness;

  static Color backgroundOf(BuildContext context) =>
      _aspectOf(context, .background).background;

  static Color surfaceOf(BuildContext context) =>
      _aspectOf(context, .surface).surface;

  static Color textColorOf(BuildContext context) =>
      _aspectOf(context, .text).text;

  static Color textSecondaryOf(BuildContext context) =>
      _aspectOf(context, .textSecondary).textSecondary;

  static Color primaryOf(BuildContext context) =>
      _aspectOf(context, .primary).primary;

  static Color primaryButtonOf(BuildContext context) =>
      _aspectOf(context, .primaryButton).primaryButton;

  static Color borderColorOf(BuildContext context) =>
      _aspectOf(context, .border).border;

  static Color errorOf(BuildContext context) =>
      _aspectOf(context, .error).error;

  static AppTextTheme textThemeOf(BuildContext context) =>
      _aspectOf(context, .textTheme).textTheme;

  static AppThemeData _aspectOf(BuildContext context, AppThemeAspect aspect) {
    final result = InheritedModel.inheritFrom<AppTheme>(
      context,
      aspect: aspect,
    );

    assert(
      result != null,
      'No AppTheme found in context. '
      'Ensure an AppThemeProvider is an ancestor of this widget.',
    );

    return result!.data;
  }

  @override
  bool updateShouldNotify(AppTheme oldWidget) => data != oldWidget.data;

  @override
  bool updateShouldNotifyDependent(
    AppTheme oldWidget,
    Set<AppThemeAspect> dependencies,
  ) {
    final oldData = oldWidget.data;

    for (final aspect in dependencies) {
      final changed = switch (aspect) {
        .brightness => data.brightness != oldData.brightness,
        .background => data.background != oldData.background,
        .surface => data.surface != oldData.surface,
        .text => data.text != oldData.text,
        .textSecondary => data.textSecondary != oldData.textSecondary,
        .primary => data.primary != oldData.primary,
        .primaryButton => data.primaryButton != oldData.primaryButton,
        .border => data.border != oldData.border,
        .error => data.error != oldData.error,
        .textTheme => data.textTheme != oldData.textTheme,
      };

      if (changed) return true;
    }

    return false;
  }
}

/// Observes platform brightness changes and provides the correct
/// [AppThemeData] to the subtree via [AppTheme].
///
/// Place at the root of your widget tree, above [WidgetsApp]:
///
/// ```dart
/// runApp(const AppThemeProvider(child: MainApp()));
/// ```
///
/// The provider automatically switches between light and dark themes
/// based on the OS preference. Use [AppThemeProvider.of] to
/// programmatically change the active theme with an animated transition:
///
/// ```dart
/// AppThemeProvider.of(context).setMode(.dark);
/// AppThemeProvider.of(context).setColorScheme(MyBrandScheme());
/// ```
class AppThemeProvider extends StatefulWidget {
  const AppThemeProvider({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
  });

  /// The widget below this provider in the tree.
  final Widget child;

  /// Duration of the animated transition when the theme changes.
  final Duration duration;

  /// Animation curve for the theme transition.
  final Curve curve;

  /// Returns the nearest [AppThemeProviderState] for programmatic control.
  ///
  /// ```dart
  /// AppThemeProvider.of(context).setMode(.dark);
  /// ```
  static AppThemeProviderState of(BuildContext context) {
    final state = context.findAncestorStateOfType<AppThemeProviderState>();
    assert(
      state != null,
      'No AppThemeProvider found in context. '
      'Ensure an AppThemeProvider is an ancestor of this widget.',
    );
    return state!;
  }

  @override
  State<AppThemeProvider> createState() => AppThemeProviderState();
}

class AppThemeProviderState extends State<AppThemeProvider>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  late AnimationController _controller;
  late AppThemeData _fromData;
  late AppThemeData _toData;
  AppThemeData _currentData = .light();

  ThemeMode _mode = .system;
  AppColorScheme? _schemeOverride;

  Brightness get _platformBrightness =>
      WidgetsBinding.instance.platformDispatcher.platformBrightness;

  /// The current [ThemeMode].
  ThemeMode get mode => _mode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _controller =
        AnimationController(
          vsync: this,
          duration: widget.duration,
        )..addListener(() {
          setState(() {
            _currentData = AppThemeData.lerp(
              _fromData,
              _toData,
              widget.curve.transform(_controller.value),
            );
          });
        });

    final resolved = _resolveThemeData();
    _fromData = resolved;
    _toData = resolved;
    _currentData = resolved;
  }

  @override
  void dispose() {
    _controller.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    if (_mode == .system && _schemeOverride == null) {
      _animateTo(_resolveThemeData());
    }
  }

  /// Sets the [ThemeMode] and animates to the new theme.
  ///
  /// Passing [ThemeMode.system] reverts to following the OS preference.
  /// Passing [ThemeMode.toggle] flips the current brightness (light→dark
  /// or dark→light) and stores the resulting concrete mode.
  /// Clears any color scheme override set via [setColorScheme].
  void setMode(ThemeMode mode) {
    if (_mode == mode) return;

    if (mode == .toggle) {
      _mode = switch (_currentData.brightness) {
        .light => .dark,
        .dark => .light,
      };
    } else {
      _mode = mode;
    }
    _schemeOverride = null;
    _animateTo(_resolveThemeData());
  }

  /// Sets a custom [AppColorScheme] and animates to it.
  ///
  /// Pass `null` to clear the override and revert to [mode]-based resolution.
  void setColorScheme(AppColorScheme? scheme) {
    _schemeOverride = scheme;
    _animateTo(_resolveThemeData());
  }

  AppThemeData _resolveThemeData() {
    if (_schemeOverride != null) {
      return AppThemeData.fromColorScheme(_schemeOverride!);
    }

    return switch (_mode) {
      .system => AppThemeData.fromBrightness(_platformBrightness),
      .light => AppThemeData.light(),
      .dark => AppThemeData.dark(),
      // toggle is resolved in setMode; this branch is unreachable.
      .toggle => _currentData,
    };
  }

  void _animateTo(AppThemeData target) {
    if (target == _toData && !_controller.isAnimating) return;

    _fromData = _currentData;
    _toData = target;
    _controller
      ..reset()
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    return AppTheme(data: _currentData, child: widget.child);
  }
}

/// Internal [AppThemeData] subclass produced by [AppThemeData.lerp].
///
/// Stores individually lerped colors rather than delegating to a
/// color scheme, since intermediate values don't correspond to any
/// concrete [AppColorScheme].
final class _LerpedThemeData extends AppThemeData {
  _LerpedThemeData({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color text,
    required Color textSecondary,
    required Color primary,
    required Color primaryButton,
    required Color border,
    required Color error,
  }) : _brightness = brightness,
       _background = background,
       _surface = surface,
       _text = text,
       _textSecondary = textSecondary,
       _primary = primary,
       _primaryButton = primaryButton,
       _border = border,
       _error = error,
       super._(
         colorScheme: brightness == Brightness.light
             ? const LightColorScheme()
             : const DarkColorScheme(),
         textTheme: AppTextTheme(color: text),
       );

  final Brightness _brightness;
  final Color _background;
  final Color _surface;
  final Color _text;
  final Color _textSecondary;
  final Color _primary;
  final Color _primaryButton;
  final Color _border;
  final Color _error;

  @override
  Brightness get brightness => _brightness;
  @override
  Color get background => _background;
  @override
  Color get surface => _surface;
  @override
  Color get text => _text;
  @override
  Color get textSecondary => _textSecondary;
  @override
  Color get primary => _primary;
  @override
  Color get primaryButton => _primaryButton;
  @override
  Color get border => _border;
  @override
  Color get error => _error;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _LerpedThemeData &&
          _brightness == other._brightness &&
          _background == other._background &&
          _surface == other._surface &&
          _text == other._text &&
          _textSecondary == other._textSecondary &&
          _primary == other._primary &&
          _primaryButton == other._primaryButton &&
          _border == other._border &&
          _error == other._error;

  @override
  int get hashCode => Object.hash(
    _brightness,
    _background,
    _surface,
    _text,
    _textSecondary,
    _primary,
    _primaryButton,
    _border,
    _error,
  );
}
