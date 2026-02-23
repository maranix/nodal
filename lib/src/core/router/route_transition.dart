import 'package:flutter/widgets.dart'
    show
        Animatable,
        AnimatedWidget,
        Animation,
        BuildContext,
        CurveTween,
        Curves,
        Offset,
        SlideTransition,
        Tween,
        Widget;

enum SlideTransitionType { leftToRight, rightToLeft }

abstract final class PageRouteTransition {
  static AnimatedWidget slide({
    required BuildContext context,
    required Animation<double> animation,
    required Animation<double> animation2,
    required Widget child,
    SlideTransitionType slideTransition = .rightToLeft,
    Animatable<double>? parentAnimation,
  }) {
    Offset beginOffset = switch (slideTransition) {
      .leftToRight => const Offset(-1.0, 0),
      .rightToLeft => const Offset(1.0, 0),
    };

    final chainedAnimation =
        parentAnimation ?? CurveTween(curve: Curves.easeInOutCubic);

    return SlideTransition(
      position: animation.drive(
        Tween<Offset>(begin: beginOffset, end: .zero).chain(chainedAnimation),
      ),
      child: child,
    );
  }
}
