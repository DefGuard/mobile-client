// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routes.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<RouteBase> get $appRoutes => [
  $appSplashRoute,
  $instancesListScreenRoute,
  $addInstanceQrScreenRoute,
  $remoteMfaQrScreenRoute,
  $instanceScreenRoute,
  $nameDeviceScreenRoute,
  $addInstanceFormScreenRoute,
  $addInstanceScreenRoute,
  $talkerScreenRoute,
  $openIdMfaScreenRoute,
  $openIdMfaWaitingScreenRoute,
  $mfaCodeScreenRoute,
];

RouteBase get $appSplashRoute => GoRouteData.$route(
  path: '/',
  hasOverriddenOnExit: false,
  factory: $AppSplashRoute._fromState,
);

mixin $AppSplashRoute on GoRouteData {
  static AppSplashRoute _fromState(GoRouterState state) =>
      const AppSplashRoute();

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

RouteBase get $instancesListScreenRoute => GoRouteData.$route(
  path: '/home',
  hasOverriddenOnExit: false,
  factory: $InstancesListScreenRoute._fromState,
);

mixin $InstancesListScreenRoute on GoRouteData {
  static InstancesListScreenRoute _fromState(GoRouterState state) =>
      const InstancesListScreenRoute();

  @override
  String get location => GoRouteData.$location('/home');

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

RouteBase get $addInstanceQrScreenRoute => GoRouteData.$route(
  path: '/add_instance/qr',
  hasOverriddenOnExit: false,
  factory: $AddInstanceQrScreenRoute._fromState,
);

mixin $AddInstanceQrScreenRoute on GoRouteData {
  static AddInstanceQrScreenRoute _fromState(GoRouterState state) =>
      const AddInstanceQrScreenRoute();

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

RouteBase get $remoteMfaQrScreenRoute => GoRouteData.$route(
  path: '/mfa/remote_qr',
  hasOverriddenOnExit: false,
  factory: $RemoteMfaQrScreenRoute._fromState,
);

mixin $RemoteMfaQrScreenRoute on GoRouteData {
  static RemoteMfaQrScreenRoute _fromState(GoRouterState state) =>
      RemoteMfaQrScreenRoute(state.extra as RemoteMfaQrScreenData);

  RemoteMfaQrScreenRoute get _self => this as RemoteMfaQrScreenRoute;

  @override
  String get location => GoRouteData.$location('/mfa/remote_qr');

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
  hasOverriddenOnExit: false,
  factory: $InstanceScreenRoute._fromState,
  routes: [
    GoRouteData.$route(
      path: 'biometry_setup',
      hasOverriddenOnExit: false,
      factory: $BiometrySetupScreenRoute._fromState,
    ),
    GoRouteData.$route(
      path: 'biometry_failed',
      hasOverriddenOnExit: false,
      factory: $BiometrySetupFailedScreenRoute._fromState,
    ),
    GoRouteData.$route(
      path: 'biometry_finish',
      hasOverriddenOnExit: false,
      factory: $BiometryFinishScreenRoute._fromState,
    ),
  ],
);

mixin $InstanceScreenRoute on GoRouteData {
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

mixin $BiometrySetupScreenRoute on GoRouteData {
  static BiometrySetupScreenRoute _fromState(GoRouterState state) =>
      BiometrySetupScreenRoute(id: state.pathParameters['id']!);

  BiometrySetupScreenRoute get _self => this as BiometrySetupScreenRoute;

  @override
  String get location => GoRouteData.$location(
    '/instance/${Uri.encodeComponent(_self.id)}/biometry_setup',
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

mixin $BiometrySetupFailedScreenRoute on GoRouteData {
  static BiometrySetupFailedScreenRoute _fromState(GoRouterState state) =>
      BiometrySetupFailedScreenRoute(id: state.pathParameters['id']!);

  BiometrySetupFailedScreenRoute get _self =>
      this as BiometrySetupFailedScreenRoute;

  @override
  String get location => GoRouteData.$location(
    '/instance/${Uri.encodeComponent(_self.id)}/biometry_failed',
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

mixin $BiometryFinishScreenRoute on GoRouteData {
  static BiometryFinishScreenRoute _fromState(GoRouterState state) =>
      BiometryFinishScreenRoute(id: state.pathParameters['id']!);

  BiometryFinishScreenRoute get _self => this as BiometryFinishScreenRoute;

  @override
  String get location => GoRouteData.$location(
    '/instance/${Uri.encodeComponent(_self.id)}/biometry_finish',
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

RouteBase get $nameDeviceScreenRoute => GoRouteData.$route(
  path: '/add_instance/name_device',
  hasOverriddenOnExit: false,
  factory: $NameDeviceScreenRoute._fromState,
);

mixin $NameDeviceScreenRoute on GoRouteData {
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
  hasOverriddenOnExit: false,
  factory: $AddInstanceFormScreenRoute._fromState,
);

mixin $AddInstanceFormScreenRoute on GoRouteData {
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
  hasOverriddenOnExit: false,
  factory: $AddInstanceScreenRoute._fromState,
);

mixin $AddInstanceScreenRoute on GoRouteData {
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
  hasOverriddenOnExit: false,
  factory: $TalkerScreenRoute._fromState,
);

mixin $TalkerScreenRoute on GoRouteData {
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
  hasOverriddenOnExit: false,
  factory: $OpenIdMfaScreenRoute._fromState,
);

mixin $OpenIdMfaScreenRoute on GoRouteData {
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
  hasOverriddenOnExit: false,
  factory: $OpenIdMfaWaitingScreenRoute._fromState,
);

mixin $OpenIdMfaWaitingScreenRoute on GoRouteData {
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
  hasOverriddenOnExit: false,
  factory: $MfaCodeScreenRoute._fromState,
);

mixin $MfaCodeScreenRoute on GoRouteData {
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
