import 'package:collection/collection.dart';
import 'package:mobile/logging.dart';
import '../data/db/database.dart';
import '../data/proxy/enrollment.dart';
import 'package:drift/drift.dart' as drift;

class UpdateInstanceResult {
  final bool instanceChanged;
  final List<int> changedLocations;

  const UpdateInstanceResult({
    required this.instanceChanged,
    required this.changedLocations,
  });
}

Future<void> updateInstance({
  required AppDatabase db,
  required DefguardInstance instance,
  required List<DeviceConfig> configs,
  InstanceInfo? info,
}) async {
  final locations = await db.managers.locations
      .filter((row) => row.instance.id.equals(instance.id))
      .get();

  try {
    await db.transaction(() async {
      // check if instance should update
      if (info != null && info.matchesDefguardInstance(instance)) {
        final companion = info.toCompanion(instance: instance);
        await db.managers.defguardInstances.update((_) => companion);
      }

      // update locations
      for (final config in configs) {

        final Location? location = locations.firstWhereOrNull(
          (l) => l.networkId == config.networkId,
        );
        // should add new
        if (location == null) {
          final companion = config.toCompanion(instanceId: instance.id);
          await db.managers.locations.create((_) => companion);
          continue;
        }
        // update bcs it changed
        if (!config.matchesLocation(location)) {
          final companion = config.toCompanion(instanceId: instance.id);
        }
      }

      // remove locations not included in update (ware deleted or device have no longer granted access)
      final existingConfigs = configs.map((c) => c.networkId);
      await db.managers.locations
          .filter((row) => row.networkId.isIn(existingConfigs).not())
          .delete();
    });
  } catch (e) {
    talker.error(
      "Failed to update DB state during configurations update on ${instance.logName} .",
      e,
    );
  }
}
