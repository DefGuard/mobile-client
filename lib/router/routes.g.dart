// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routes.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<RouteBase> get $appRoutes => [
  $homeScreenRoute,
  $instanceScreenRoute,
  $nameDeviceScreenRoute,
  $scanInstanceQrRoute,
  $addInstanceFormScreenRoute,
  $addInstanceScreenRoute,
  $registerFromQrScreenRoute,
  $talkerScreenRoute,
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

RouteBase get $nameDeviceScreenRoute => GoRouteData.$route(
  path: '/add_instance/name_device',

  factory: _$NameDeviceScreenRoute._fromState,
);

mixin _$NameDeviceScreenRoute on GoRouteData {
  static NameDeviceScreenRoute _fromState(GoRouterState state) =>
      NameDeviceScreenRoute(state.extra as NameDeviceScreenData);

  NameDeviceScreenRoute get _self => this as NameDeviceScreenRoute;

  @override
  String get location => GoRouteData.$location('/add_instance/name_device');

  @override
  void go(BuildContext context) => context.go(location, extra: _self.$extra);

  @override
  Future<T?> push<T>(BuildContext context) =>
      context.push<T>(location, extra: _self.$extra);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location, extra: _self.$extra);

  @override
  void replace(BuildContext context) =>
      context.replace(location, extra: _self.$extra);
}

RouteBase get $scanInstanceQrRoute => GoRouteData.$route(
  path: '/add_instance/qr',

  factory: _$ScanInstanceQrRoute._fromState,
);

mixin _$ScanInstanceQrRoute on GoRouteData {
  static ScanInstanceQrRoute _fromState(GoRouterState state) =>
      ScanInstanceQrRoute();

  @override
  String get location => GoRouteData.$location('/add_instance/qr');

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

RouteBase get $addInstanceFormScreenRoute => GoRouteData.$route(
  path: '/add_instance/form',

  factory: _$AddInstanceFormScreenRoute._fromState,
);

mixin _$AddInstanceFormScreenRoute on GoRouteData {
  static AddInstanceFormScreenRoute _fromState(GoRouterState state) =>
      AddInstanceFormScreenRoute();

  @override
  String get location => GoRouteData.$location('/add_instance/form');

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
  path: '/add_instance/init',

  factory: _$AddInstanceScreenRoute._fromState,
);

mixin _$AddInstanceScreenRoute on GoRouteData {
  static AddInstanceScreenRoute _fromState(GoRouterState state) =>
      const AddInstanceScreenRoute();

  @override
  String get location => GoRouteData.$location('/add_instance/init');

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

RouteBase get $registerFromQrScreenRoute => GoRouteData.$route(
  path: '/add_instance/from_qr_open',

  factory: _$RegisterFromQrScreenRoute._fromState,
);

mixin _$RegisterFromQrScreenRoute on GoRouteData {
  static RegisterFromQrScreenRoute _fromState(GoRouterState state) =>
      RegisterFromQrScreenRoute(state.extra as QrInstanceRegistration);

  RegisterFromQrScreenRoute get _self => this as RegisterFromQrScreenRoute;

  @override
  String get location => GoRouteData.$location('/add_instance/from_qr_open');

  @override
  void go(BuildContext context) => context.go(location, extra: _self.$extra);

  @override
  Future<T?> push<T>(BuildContext context) =>
      context.push<T>(location, extra: _self.$extra);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location, extra: _self.$extra);

  @override
  void replace(BuildContext context) =>
      context.replace(location, extra: _self.$extra);
}

RouteBase get $talkerScreenRoute => GoRouteData.$route(
  path: '/talker',

  factory: _$TalkerScreenRoute._fromState,
);

mixin _$TalkerScreenRoute on GoRouteData {
  static TalkerScreenRoute _fromState(GoRouterState state) =>
      TalkerScreenRoute();

  @override
  String get location => GoRouteData.$location('/talker');

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
