// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routes.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<RouteBase> get $appRoutes => [
  $testStorageScreenRoute,
  $processQrScreenRoute,
  $homeScreenRoute,
  $qRScreenRoute,
  $instanceScreenRoute,
  $nameDeviceScreenRoute,
  $addInstanceFormScreenRoute,
  $addInstanceScreenRoute,
  $talkerScreenRoute,
  $openIdMfaScreenRoute,
  $openIdMfaWaitingScreenRoute,
  $mfaCodeScreenRoute,
  $biometrySetupScreenRoute,
  $biometrySetupFailedScreenRoute,
  $biometryFinishScreenRoute,
];

RouteBase get $testStorageScreenRoute => GoRouteData.$route(
  path: '/test_bio',

  factory: _$TestStorageScreenRoute._fromState,
);

mixin _$TestStorageScreenRoute on GoRouteData {
  static TestStorageScreenRoute _fromState(GoRouterState state) =>
      const TestStorageScreenRoute();

  @override
  String get location => GoRouteData.$location('/test_bio');

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

RouteBase get $processQrScreenRoute => GoRouteData.$route(
  path: '/process_qr',

  factory: _$ProcessQrScreenRoute._fromState,
);

mixin _$ProcessQrScreenRoute on GoRouteData {
  static ProcessQrScreenRoute _fromState(GoRouterState state) =>
      ProcessQrScreenRoute(state.extra as ProcessQrScreenData);

  ProcessQrScreenRoute get _self => this as ProcessQrScreenRoute;

  @override
  String get location => GoRouteData.$location('/process_qr');

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

RouteBase get $qRScreenRoute =>
    GoRouteData.$route(path: '/qr', factory: _$QRScreenRoute._fromState);

mixin _$QRScreenRoute on GoRouteData {
  static QRScreenRoute _fromState(GoRouterState state) =>
      QRScreenRoute(state.extra as QrScreenData);

  QRScreenRoute get _self => this as QRScreenRoute;

  @override
  String get location => GoRouteData.$location('/qr');

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

RouteBase get $openIdMfaScreenRoute => GoRouteData.$route(
  path: '/mfa/openid',

  factory: _$OpenIdMfaScreenRoute._fromState,
);

mixin _$OpenIdMfaScreenRoute on GoRouteData {
  static OpenIdMfaScreenRoute _fromState(GoRouterState state) =>
      OpenIdMfaScreenRoute(state.extra as OpenIdMfaScreenData);

  OpenIdMfaScreenRoute get _self => this as OpenIdMfaScreenRoute;

  @override
  String get location => GoRouteData.$location('/mfa/openid');

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

RouteBase get $openIdMfaWaitingScreenRoute => GoRouteData.$route(
  path: '/mfa/openid/waiting',

  factory: _$OpenIdMfaWaitingScreenRoute._fromState,
);

mixin _$OpenIdMfaWaitingScreenRoute on GoRouteData {
  static OpenIdMfaWaitingScreenRoute _fromState(GoRouterState state) =>
      OpenIdMfaWaitingScreenRoute(state.extra as OpenIdMfaWaitingScreenData);

  OpenIdMfaWaitingScreenRoute get _self => this as OpenIdMfaWaitingScreenRoute;

  @override
  String get location => GoRouteData.$location('/mfa/openid/waiting');

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

RouteBase get $mfaCodeScreenRoute => GoRouteData.$route(
  path: '/mfa/code',

  factory: _$MfaCodeScreenRoute._fromState,
);

mixin _$MfaCodeScreenRoute on GoRouteData {
  static MfaCodeScreenRoute _fromState(GoRouterState state) =>
      MfaCodeScreenRoute(state.extra as MfaCodeScreenData);

  MfaCodeScreenRoute get _self => this as MfaCodeScreenRoute;

  @override
  String get location => GoRouteData.$location('/mfa/code');

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

RouteBase get $biometrySetupScreenRoute => GoRouteData.$route(
  path: '/biometry_setup/:id',

  factory: _$BiometrySetupScreenRoute._fromState,
);

mixin _$BiometrySetupScreenRoute on GoRouteData {
  static BiometrySetupScreenRoute _fromState(GoRouterState state) =>
      BiometrySetupScreenRoute(id: state.pathParameters['id']!);

  BiometrySetupScreenRoute get _self => this as BiometrySetupScreenRoute;

  @override
  String get location =>
      GoRouteData.$location('/biometry_setup/${Uri.encodeComponent(_self.id)}');

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

RouteBase get $biometrySetupFailedScreenRoute => GoRouteData.$route(
  path: '/biometry_failed',

  factory: _$BiometrySetupFailedScreenRoute._fromState,
);

mixin _$BiometrySetupFailedScreenRoute on GoRouteData {
  static BiometrySetupFailedScreenRoute _fromState(GoRouterState state) =>
      const BiometrySetupFailedScreenRoute();

  @override
  String get location => GoRouteData.$location('/biometry_failed');

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

RouteBase get $biometryFinishScreenRoute => GoRouteData.$route(
  path: '/biometry_finish',

  factory: _$BiometryFinishScreenRoute._fromState,
);

mixin _$BiometryFinishScreenRoute on GoRouteData {
  static BiometryFinishScreenRoute _fromState(GoRouterState state) =>
      const BiometryFinishScreenRoute();

  @override
  String get location => GoRouteData.$location('/biometry_finish');

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
