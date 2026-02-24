import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:nodal/src/core/router/route_enums.dart';
import 'package:nodal/src/core/router/route_transition.dart';
import 'package:nodal/src/core/theme/theme.dart';
import 'package:nodal/src/core/widgets/widgets.dart';

part 'router.g.dart';

final router = GoRouter(routes: $appRoutes, initialLocation: RoutePath.root);

@TypedGoRoute<RootScreenRoute>(
  path: RoutePath.root,
  routes: [TypedGoRoute<ProfilesRoute>(path: RoutePath.profiles)],
)
@immutable
final class RootScreenRoute extends GoRouteData with $RootScreenRoute {
  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    final bgColor = AppTheme.backgroundOf(context);
    final textColor = AppTheme.textColorOf(context);

    return CustomTransitionPage(
      key: state.pageKey,
      transitionsBuilder: (context, animation, animation2, child) =>
          PageRouteTransition.slide(
            context: context,
            animation: animation,
            animation2: animation2,
            child: child,
          ),
      child: ColoredBox(
        color: bgColor,
        child: Center(
          child: Column(
            spacing: 24.0,
            mainAxisAlignment: .center,
            children: [
              Text('Home', style: TextStyle(color: textColor, fontSize: 16)),
              RawButton(
                onTap: () => ProfilesRoute(step: .select).go(context),
                label: 'Profile Selection Page',
              ),
              RawButton(
                onTap: () => ProfilesRoute(step: .create).go(context),
                label: 'Profile Creation Page',
              ),
              RawButton(
                onTap: () => AppThemeProvider.of(context).setMode(.toggle),
                label: 'Theme Switch',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

@immutable
final class ProfilesRoute extends GoRouteData with $ProfilesRoute {
  const ProfilesRoute({this.step});

  final ProfilesRouteStep? step;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    final bgColor = AppTheme.backgroundOf(context);
    final textColor = AppTheme.textColorOf(context);

    return CustomTransitionPage(
      key: state.pageKey,
      transitionDuration: .new(milliseconds: 500),
      transitionsBuilder: (context, animation, animation2, child) =>
          PageRouteTransition.slide(
            context: context,
            animation: animation,
            animation2: animation2,
            child: child,
            slideTransition: switch (step) {
              .select => .rightToLeft,
              _ => .leftToRight,
            },
          ),
      child: switch (step) {
        .select => ColoredBox(
          color: bgColor,
          child: Center(
            child: Column(
              spacing: 24.0,
              mainAxisAlignment: .center,
              children: [
                Text(
                  'Select Profile',
                  style: TextStyle(color: textColor, fontSize: 16),
                ),
                RawButton(
                  onTap: () => RootScreenRoute().go(context),
                  label: 'Home',
                ),
              ],
            ),
          ),
        ),
        .create => ColoredBox(
          color: bgColor,
          child: Center(
            child: Column(
              spacing: 24.0,
              mainAxisAlignment: .center,
              children: [
                Text(
                  'Create Profile',
                  style: TextStyle(color: textColor, fontSize: 16),
                ),
                RawButton(
                  onTap: () => RootScreenRoute().go(context),
                  label: 'Home',
                ),
              ],
            ),
          ),
        ),
        _ => ColoredBox(
          color: bgColor,
          child: Center(
            child: Column(
              spacing: 24.0,
              mainAxisAlignment: .center,
              children: [
                Text(
                  'Manage Profile',
                  style: TextStyle(color: textColor, fontSize: 16),
                ),
                RawButton(
                  onTap: () => RootScreenRoute().go(context),
                  label: 'Home',
                ),
              ],
            ),
          ),
        ),
      },
    );
  }
}

abstract final class RoutePath {
  static const root = '/';
  static const dashboard = 'dashboard';
  static const profiles = 'profiles';
}
