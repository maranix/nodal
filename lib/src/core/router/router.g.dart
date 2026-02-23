// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'router.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<RouteBase> get $appRoutes => [$rootScreenRoute];

RouteBase get $rootScreenRoute => GoRouteData.$route(
  path: '/',
  factory: $RootScreenRoute._fromState,
  routes: [
    GoRouteData.$route(path: 'profiles', factory: $ProfilesRoute._fromState),
  ],
);

mixin $RootScreenRoute on GoRouteData {
  static RootScreenRoute _fromState(GoRouterState state) => RootScreenRoute();

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

mixin $ProfilesRoute on GoRouteData {
  static ProfilesRoute _fromState(GoRouterState state) => ProfilesRoute(
    step: _$convertMapValue(
      'step',
      state.uri.queryParameters,
      _$ProfilesRouteStepEnumMap._$fromName,
    ),
  );

  ProfilesRoute get _self => this as ProfilesRoute;

  @override
  String get location => GoRouteData.$location(
    '/profiles',
    queryParams: {
      if (_self.step != null) 'step': _$ProfilesRouteStepEnumMap[_self.step!],
    },
  );

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

const _$ProfilesRouteStepEnumMap = {
  ProfilesRouteStep.manage: 'manage',
  ProfilesRouteStep.select: 'select',
  ProfilesRouteStep.create: 'create',
};

T? _$convertMapValue<T>(
  String key,
  Map<String, String> map,
  T? Function(String) converter,
) {
  final value = map[key];
  return value == null ? null : converter(value);
}

extension<T extends Enum> on Map<T, String> {
  T? _$fromName(String? value) =>
      entries.where((element) => element.value == value).firstOrNull?.key;
}
