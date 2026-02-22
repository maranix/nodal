import 'package:flutter/widgets.dart';
import 'package:nodal/src/core/router/router.dart';

void main() async {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return WidgetsApp.router(routerConfig: router, color: Color(0xFFFFFFFF));
  }
}
