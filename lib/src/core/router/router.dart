import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:nodal/src/core/widgets/widgets.dart';

part 'router.g.dart';

final router = GoRouter(routes: $appRoutes, initialLocation: '/');

@TypedGoRoute<HomeScreenRoute>(
  path: '/',
  routes: [TypedGoRoute<ProfileSelectionRoute>(path: 'profiles/select')],
)
@immutable
final class HomeScreenRoute extends GoRouteData with $HomeScreenRoute {
  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    final bgColor = Color(0xFFFFFFFF).withValues(colorSpace: .displayP3);
    final luminance = bgColor.computeLuminance();

    final textColor = switch (luminance) {
      >= 0.5 => Color(0xFF000000).withValues(colorSpace: .displayP3),
      _ => bgColor,
    };

    return CustomTransitionPage(
      key: state.pageKey,
      transitionDuration: .new(milliseconds: 500),
      transitionsBuilder: (context, animation, animation2, child) {
        return SlideTransition(
          position: animation.drive(
            Tween<Offset>(
              begin: const Offset(1.0, 0),
              end: .zero,
            ).chain(CurveTween(curve: Curves.easeInOutCubic)),
          ),
          child: child,
        );
      },
      child: ColoredBox(
        color: bgColor,
        child: Center(
          child: Column(
            spacing: 24.0,
            mainAxisAlignment: .center,
            children: [
              Text('Home', style: TextStyle(color: textColor, fontSize: 16)),
              RawButton(
                onTap: () => ProfileSelectionRoute().go(context),
                label: 'ProfileSelection',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

@immutable
final class ProfileSelectionRoute extends GoRouteData
    with $ProfileSelectionRoute {
  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    final bgColor = Color(0xFFFFFFFF).withValues(colorSpace: .displayP3);
    final luminance = bgColor.computeLuminance();

    final textColor = switch (luminance) {
      >= 0.5 => Color(0xFF000000).withValues(colorSpace: .displayP3),
      _ => bgColor,
    };

    return CustomTransitionPage(
      key: state.pageKey,
      transitionDuration: .new(milliseconds: 500),
      transitionsBuilder: (context, animation, animation2, child) {
        return SlideTransition(
          position: animation.drive(
            Tween<Offset>(
              begin: const Offset(1.0, 0),
              end: .zero,
            ).chain(CurveTween(curve: Curves.easeInOutCubic)),
          ),
          child: child,
        );
      },
      child: ColoredBox(
        color: bgColor,
        child: Center(
          child: Column(
            spacing: 24.0,
            mainAxisAlignment: .center,
            children: [
              Text(
                'ProfileSelection',
                style: TextStyle(color: textColor, fontSize: 16),
              ),
              RawButton(onTap: () => context.pop(), label: 'Home'),
            ],
          ),
        ),
      ),
    );
  }
}
