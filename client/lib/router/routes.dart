import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/enterprise/screens/mfa/openid_mfa_screen.dart';
import 'package:mobile/enterprise/screens/mfa/openid_mfa_waiting_screen.dart';
import 'package:mobile/open/screens/add_instance/add_instance_screen.dart';
import 'package:mobile/open/screens/add_instance/screens/add_instance_form.dart';
import 'package:mobile/open/screens/add_instance/screens/biometry/next_biometry_finish_screen.dart';
import 'package:mobile/open/screens/add_instance/screens/biometry/next_biometry_setup_failed_screen.dart';
import 'package:mobile/open/screens/add_instance/screens/biometry/next_biometry_setup_screen.dart';
import 'package:mobile/open/screens/add_instance/screens/name_device_screen.dart';
import 'package:mobile/open/screens/instances_list/next_instances_list_screen.dart';
import 'package:mobile/open/screens/mfa/mfa_code_screen.dart';
import 'package:mobile/open/screens/scan_qr_screen.dart';
import 'package:mobile/open/screens/splash.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../logging.dart';
import '../open/screens/instance/next_instance_screen.dart';

part 'routes.g.dart';

@TypedGoRoute<AppSplashRoute>(path: '/')
@immutable
class AppSplashRoute extends GoRouteData with $AppSplashRoute {
  const AppSplashRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const AppSplash();
  }
}

@TypedGoRoute<InstancesListScreenRoute>(path: '/home')
@immutable
class InstancesListScreenRoute extends GoRouteData
    with $InstancesListScreenRoute {
  const InstancesListScreenRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const NextInstancesListScreen();
  }
}

@TypedGoRoute<QRScreenRoute>(path: "/qr")
@immutable
class QRScreenRoute extends GoRouteData with $QRScreenRoute {
  const QRScreenRoute(this.$extra);

  final QrScreenData $extra;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return ScanQrScreen(screenData: $extra);
  }
}

@TypedGoRoute<InstanceScreenRoute>(
  path: "/instance/:id",
  routes: [
    TypedGoRoute<BiometrySetupScreenRoute>(path: "biometry_setup"),
    TypedGoRoute<BiometrySetupFailedScreenRoute>(path: "biometry_failed"),
    TypedGoRoute<BiometryFinishScreenRoute>(path: "biometry_finish"),
  ],
)
@immutable
class InstanceScreenRoute extends GoRouteData with $InstanceScreenRoute {
  final String id;

  const InstanceScreenRoute({required this.id});

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return NextInstanceScreen(id: id);
  }
}

@TypedGoRoute<NameDeviceScreenRoute>(path: "/add_instance/name_device")
@immutable
class NameDeviceScreenRoute extends GoRouteData with $NameDeviceScreenRoute {
  const NameDeviceScreenRoute(this.$extra);

  final NameDeviceScreenData $extra;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return NameDeviceScreen(screenData: $extra);
  }
}

@TypedGoRoute<AddInstanceFormScreenRoute>(path: "/add_instance/form")
@immutable
class AddInstanceFormScreenRoute extends GoRouteData
    with $AddInstanceFormScreenRoute {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return AddInstanceFormScreen();
  }
}

@TypedGoRoute<AddInstanceScreenRoute>(path: '/add_instance/init')
@immutable
class AddInstanceScreenRoute extends GoRouteData with $AddInstanceScreenRoute {
  const AddInstanceScreenRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const AddInstanceScreen();
  }
}

@TypedGoRoute<TalkerScreenRoute>(path: "/talker")
@immutable
class TalkerScreenRoute extends GoRouteData with $TalkerScreenRoute {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return TalkerScreen(talker: talker);
  }
}

@TypedGoRoute<OpenIdMfaScreenRoute>(path: "/mfa/openid")
@immutable
class OpenIdMfaScreenRoute extends GoRouteData with $OpenIdMfaScreenRoute {
  const OpenIdMfaScreenRoute(this.$extra);

  final OpenIdMfaScreenData $extra;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return OpenIdMfaScreen(screenData: $extra);
  }
}

@TypedGoRoute<OpenIdMfaWaitingScreenRoute>(path: "/mfa/openid/waiting")
@immutable
class OpenIdMfaWaitingScreenRoute extends GoRouteData
    with $OpenIdMfaWaitingScreenRoute {
  const OpenIdMfaWaitingScreenRoute(this.$extra);

  final OpenIdMfaWaitingScreenData $extra;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return OpenIdMfaWaitingScreen(screenData: $extra);
  }
}

@TypedGoRoute<MfaCodeScreenRoute>(path: "/mfa/code")
@immutable
class MfaCodeScreenRoute extends GoRouteData with $MfaCodeScreenRoute {
  const MfaCodeScreenRoute(this.$extra);

  final MfaCodeScreenData $extra;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return MfaCodeScreen(screenData: $extra);
  }
}

@immutable
class BiometrySetupScreenRoute extends GoRouteData
    with $BiometrySetupScreenRoute {
  final String id;

  const BiometrySetupScreenRoute({required this.id});

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return NextBiometrySetupScreen(instanceId: int.parse(id));
  }
}

@immutable
class BiometrySetupFailedScreenRoute extends GoRouteData
    with $BiometrySetupFailedScreenRoute {
  final String id;

  const BiometrySetupFailedScreenRoute({required this.id});

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return NextBiometrySetupFailedScreen(instanceId: id);
  }
}

@immutable
class BiometryFinishScreenRoute extends GoRouteData
    with $BiometryFinishScreenRoute {
  final String id;

  const BiometryFinishScreenRoute({required this.id});

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return NextBiometryFinishScreen(instanceId: id);
  }
}
