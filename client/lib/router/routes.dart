import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/data/proxy/qr_register.dart';
import 'package:mobile/open/screens/add_instance/add_instance_screen.dart';
import 'package:mobile/open/screens/add_instance/screens/add_instance_form.dart';
import 'package:mobile/open/screens/add_instance/screens/name_device_screen.dart';
import 'package:mobile/open/screens/add_instance/screens/register_from_qr_screen.dart';
import 'package:mobile/open/screens/add_instance/screens/scan_qr_screen.dart';
import 'package:mobile/open/screens/home/home_screen.dart';
import 'package:mobile/open/screens/instance/instance_screen.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../logging.dart';

part 'routes.g.dart';

@TypedGoRoute<HomeScreenRoute>(path: '/')
@immutable
class HomeScreenRoute extends GoRouteData with _$HomeScreenRoute {
  const HomeScreenRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const HomeScreen();
  }
}

@TypedGoRoute<InstanceScreenRoute>(path: "/instance/:id")
@immutable
class InstanceScreenRoute extends GoRouteData with _$InstanceScreenRoute {
  final String id;

  const InstanceScreenRoute({required this.id});

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return InstanceScreen(id: id);
  }
}

@TypedGoRoute<NameDeviceScreenRoute>(path: "/add_instance/name_device")
@immutable
class NameDeviceScreenRoute extends GoRouteData with _$NameDeviceScreenRoute {
  NameDeviceScreenRoute(this.$extra);

  final NameDeviceScreenData $extra;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return NameDeviceScreen(screenData: $extra);
  }
}

@TypedGoRoute<ScanInstanceQrRoute>(path: "/add_instance/qr")
@immutable
class ScanInstanceQrRoute extends GoRouteData with _$ScanInstanceQrRoute {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return ScanInstanceQrScreen();
  }
}

@TypedGoRoute<AddInstanceFormScreenRoute>(path: "/add_instance/form")
@immutable
class AddInstanceFormScreenRoute extends GoRouteData
    with _$AddInstanceFormScreenRoute {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return AddInstanceFormScreen();
  }
}

@TypedGoRoute<AddInstanceScreenRoute>(path: '/add_instance/init')
@immutable
class AddInstanceScreenRoute extends GoRouteData with _$AddInstanceScreenRoute {
  const AddInstanceScreenRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const AddInstanceScreen();
  }
}

@TypedGoRoute<RegisterFromQrScreenRoute>(path: "/add_instance/from_qr_open")
@immutable
class RegisterFromQrScreenRoute extends GoRouteData
    with _$RegisterFromQrScreenRoute {
  RegisterFromQrScreenRoute(this.$extra);

  final QrInstanceRegistration $extra;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return RegisterFromQrScreen(instanceRegistration: $extra);
  }
}

@TypedGoRoute<TalkerScreenRoute>(path: "/talker")
@immutable
class TalkerScreenRoute extends GoRouteData with _$TalkerScreenRoute {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return TalkerScreen(talker: talker);
  }
}
