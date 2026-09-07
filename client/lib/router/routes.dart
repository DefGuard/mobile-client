import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/open/screens/add_instance/add_instance_screen.dart';
import 'package:mobile/open/screens/add_instance/screens/add_instance_form.dart';
import 'package:mobile/open/screens/add_instance/screens/add_instance_qr_screen.dart';
import 'package:mobile/open/screens/add_instance/screens/biometry/biometry_finish_screen.dart';
import 'package:mobile/open/screens/add_instance/screens/biometry/biometry_setup_failed_screen.dart';
import 'package:mobile/open/screens/add_instance/screens/biometry/biometry_setup_screen.dart';
import 'package:mobile/open/screens/add_instance/screens/name_device_screen.dart';
import 'package:mobile/open/screens/instances_list/instances_list_screen.dart';
import 'package:mobile/open/screens/mfa/remote_mfa_qr_screen.dart';
import 'package:mobile/open/screens/splash.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../logging.dart';
import 'package:mobile/open/screens/instance/instance_screen.dart';

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
    return const InstancesListScreen();
  }
}

@TypedGoRoute<AddInstanceQrScreenRoute>(path: "/add_instance/qr")
@immutable
class AddInstanceQrScreenRoute extends GoRouteData
    with $AddInstanceQrScreenRoute {
  const AddInstanceQrScreenRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const AddInstanceQrScreen();
  }
}

@TypedGoRoute<RemoteMfaQrScreenRoute>(path: "/mfa/remote_qr")
@immutable
class RemoteMfaQrScreenRoute extends GoRouteData with $RemoteMfaQrScreenRoute {
  const RemoteMfaQrScreenRoute(this.$extra);

  final RemoteMfaQrScreenData $extra;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return RemoteMfaQrScreen(screenData: $extra);
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
    return InstanceScreen(key: ValueKey(id), id: id);
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

@immutable
class BiometrySetupScreenRoute extends GoRouteData
    with $BiometrySetupScreenRoute {
  final String id;

  const BiometrySetupScreenRoute({required this.id});

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return BiometrySetupScreen(instanceId: int.parse(id));
  }
}

@immutable
class BiometrySetupFailedScreenRoute extends GoRouteData
    with $BiometrySetupFailedScreenRoute {
  final String id;

  const BiometrySetupFailedScreenRoute({required this.id});

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return BiometrySetupFailedScreen(instanceId: id);
  }
}

@immutable
class BiometryFinishScreenRoute extends GoRouteData
    with $BiometryFinishScreenRoute {
  final String id;

  const BiometryFinishScreenRoute({required this.id});

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return BiometryFinishScreen(instanceId: id);
  }
}
