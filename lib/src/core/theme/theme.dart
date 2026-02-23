import 'package:flutter/widgets.dart';
import 'package:nodal/src/core/theme/colors.dart';

class AppThemeProvider extends StatelessWidget {
  const AppThemeProvider({
    super.key,
    required this.data,
    required this.child,
  });

  final AppThemeData data;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: data,
      builder: (context, _) => AppTheme(
        data: data,
        child: child,
      ),
    );
  }
}

class AppTheme extends InheritedWidget {
  const AppTheme({super.key, required super.child, required this.data});

  final AppThemeData data;

  static AppThemeData? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppTheme>()?.data;

  static AppThemeData of(BuildContext context) {
    final result = maybeOf(context);
    assert(
      result != null,
      "Unable to find AppTheme in BuildContext, make sure this widget is a descendent of AppTheme.",
    );

    return result!;
  }

  @override
  bool updateShouldNotify(AppTheme oldWidget) => true;
}

final class AppThemeData extends ChangeNotifier {
  bool _isDark = false;
  bool get isDark => _isDark;

  late Color _primaryColor;
  late Color _textColor;

  AppThemeData() {
    _updateInternalColors();
  }

  Color get primaryColor => _primaryColor;
  Color get textColor => _textColor;
  Color get primaryButtonColor => Colors.lightCyan;

  void toggleTheme() {
    _isDark = !_isDark;
    _updateInternalColors();
    notifyListeners();
  }

  void _updateInternalColors() {
    _primaryColor = _isDark ? Colors.black : Colors.white;

    _textColor = _calculateTextColor(_primaryColor);
  }

  Color _calculateTextColor(Color background) {
    final luminance = background.computeLuminance();
    return switch (luminance) {
      > 0.5 => Colors.black,
      _ => Colors.white,
    };
  }
}
