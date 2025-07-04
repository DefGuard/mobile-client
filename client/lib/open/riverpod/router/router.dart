import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/data/db/database.dart';
import 'package:mobile/router/routes.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../../../logging.dart';

part 'router.g.dart';

@riverpod
Stream<int> instancesCount(Ref ref) async* {
  final db = ref.watch(databaseProvider);
  final countExp = db.defguardInstances.id.count(distinct: false);
  final query = db.selectOnly(db.defguardInstances)..addColumns([countExp]);
  yield* query.watchSingle().map((row) => row.read(countExp) ?? 0);
}

@riverpod
class InstancesCountTrigger extends _$InstancesCountTrigger {
  @override
  bool build() {
    ref.listen<AsyncValue<int>>(instancesCountProvider, (perv, next) {
      if(perv?.value != next.value) {
        state = !state;
      }
    });
    return false;
  }
}

@riverpod
GoRouter router(Ref ref) {
  ref.watch(instancesCountTriggerProvider);

  final instancesCount = ref.watch(instancesCountProvider);

  return GoRouter(
    initialLocation: HomeScreenRoute().location,
    routes: $appRoutes,
    observers: [TalkerRouteObserver(talker)],
    redirect: (context, state) {
      final count = instancesCount.asData?.value;
      if (state.uri.toString() == HomeScreenRoute().location) {
        if(count != null && count == 0) {
          return AddInstanceScreenRoute().location;
        }
      }
      return null;
    },
  );
}
