import 'package:flutter/widgets.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:nodal/src/core/router/router.dart';
import 'package:nodal/src/core/theme/theme.dart';

void main() async {
  usePathUrlStrategy();
  runApp(const AppThemeProvider(child: MainApp()));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppTheme.primaryOf(context);

    return WidgetsApp.router(
      routerConfig: router,
      color: primaryColor,
    );
  }
}
