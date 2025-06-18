// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routes.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<RouteBase> get $appRoutes => [
  $homeScreenRoute,
  $addInstanceScreenRoute,
  $instanceScreenRoute,
];

RouteBase get $homeScreenRoute =>
    GoRouteData.$route(path: '/', factory: _$HomeScreenRoute._fromState);

mixin _$HomeScreenRoute on GoRouteData {
  static HomeScreenRoute _fromState(GoRouterState state) =>
      const HomeScreenRoute();

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

RouteBase get $addInstanceScreenRoute => GoRouteData.$route(
  path: '/add_instance',

  factory: _$AddInstanceScreenRoute._fromState,
);

mixin _$AddInstanceScreenRoute on GoRouteData {
  static AddInstanceScreenRoute _fromState(GoRouterState state) =>
      const AddInstanceScreenRoute();

  @override
  String get location => GoRouteData.$location('/add_instance');

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

RouteBase get $instanceScreenRoute => GoRouteData.$route(
  path: '/instance/:id',

  factory: _$InstanceScreenRoute._fromState,
);

mixin _$InstanceScreenRoute on GoRouteData {
  static InstanceScreenRoute _fromState(GoRouterState state) =>
      InstanceScreenRoute(id: state.pathParameters['id']!);

  InstanceScreenRoute get _self => this as InstanceScreenRoute;

  @override
  String get location =>
      GoRouteData.$location('/instance/${Uri.encodeComponent(_self.id)}');

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
