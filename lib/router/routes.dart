import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_client/open/screens/add_instance/add_instance_screen.dart';
import 'package:mobile_client/open/screens/home/home_screen.dart';
import 'package:mobile_client/open/screens/instance/instance_screen.dart';

part 'routes.g.dart';

@TypedGoRoute<HomeScreenRoute>(
  path: '/',
)
@immutable
class HomeScreenRoute extends GoRouteData with _$HomeScreenRoute {
  const HomeScreenRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const HomeScreen();
  }
}

@TypedGoRoute<AddInstanceScreenRoute>(path: '/add_instance')
@immutable
class AddInstanceScreenRoute extends GoRouteData with _$AddInstanceScreenRoute {
  const AddInstanceScreenRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const AddInstanceScreen();
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