// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'router.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<RouteBase> get $appRoutes => [$homeScreenRoute];

RouteBase get $homeScreenRoute => GoRouteData.$route(
  path: '/',
  factory: $HomeScreenRoute._fromState,
  routes: [
    GoRouteData.$route(
      path: 'profiles/select',
      factory: $ProfileSelectionRoute._fromState,
    ),
  ],
);

mixin $HomeScreenRoute on GoRouteData {
  static HomeScreenRoute _fromState(GoRouterState state) => HomeScreenRoute();

  @override
  String get location => GoRouteData.$location('/');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $ProfileSelectionRoute on GoRouteData {
  static ProfileSelectionRoute _fromState(GoRouterState state) =>
      ProfileSelectionRoute();

  @override
  String get location => GoRouteData.$location('/profiles/select');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}
