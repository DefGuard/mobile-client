import 'package:collection/collection.dart';
import 'package:mobile/logging.dart';
import '../data/db/database.dart';
import '../data/proxy/enrollment.dart';
import 'package:drift/drift.dart' as drift;

class UpdateInstanceResult {
  bool instanceChanged;
  int locationsAdded;
  List<int> locationsUpdated;
  List<int> locationsRemoved;

  UpdateInstanceResult({
    required this.instanceChanged,
    required this.locationsAdded,
    required this.locationsUpdated,
    required this.locationsRemoved,
  });

  bool get didChange {
    return locationsRemoved.isNotEmpty ||
        locationsUpdated.isNotEmpty ||
        instanceChanged ||
        locationsAdded > 0;
  }
}

Future<UpdateInstanceResult?> updateInstance({
  required AppDatabase db,
  required DefguardInstance instance,
  required List<DeviceConfig> configs,
  InstanceInfo? info,
  String? token,
}) async {
  talker.debug("${instance.logName} updated started");

  final result = UpdateInstanceResult(
    instanceChanged: false,
    locationsAdded: 0,
    locationsRemoved: [],
    locationsUpdated: [],
  );

  try {
    final locations = await db.managers.locations
        .filter((row) => row.instance.id.equals(instance.id))
        .get();
    await db.transaction(() async {
      // check if instance should update
      if (info != null && !info.matchesDefguardInstance(instance)) {
        final companion = info.toCompanion(instance: instance);
        await db.managers.defguardInstances
            .filter((row) => row.uuid.equals(instance.uuid))
            .update((_) => companion);
        result.instanceChanged = true;
      }

      // update token if provided
      if (token != null) {
        await db.managers.defguardInstances
            .filter((row) => row.id.equals(instance.id))
            .update(
              (_) => DefguardInstancesCompanion(poolingToken: drift.Value(token)),
            );
        talker.debug("${instance.logName} token updated");
      }

      // remove locations not included in update (ware deleted or device have no longer granted access)
      final existingConfigs = configs.map((c) => c.networkId);
      final List<int> toDelete = locations
          .where((location) => !existingConfigs.contains(location.networkId))
          .map((location) => location.id)
          .toList();
      if (toDelete.isNotEmpty) {
        await db.managers.locations
            .filter((row) => row.id.isIn(toDelete))
            .delete();
        result.locationsRemoved = toDelete;
        talker.debug("$toDelete Locations will be removed");
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
          talker.debug("Location ${config.networkName} will be added");
          result.locationsAdded++;
          continue;
        }
        // update bcs it changed
        if (!config.matchesLocation(location)) {
          final companion = config.toCompanion(
            instanceId: instance.id,
            id: location.id,
            trafficMethod: location.trafficMethod,
            mfaMethod: location.mfaMethod,
          );
          talker.debug(companion.toString());
          result.locationsUpdated.add(companion.id.value);
          await db.managers.locations
              .filter((loc) => loc.id.equals(location.id))
              .update((_) => companion);
          talker.debug("Location ${location.logName} will be changed");
        } else {
          talker.debug("Location ${location.logName} was unchanged");
        }
      }
    });
    talker.debug("Instance ${instance.logName} update transaction finished");
    return result;
  } catch (e) {
    talker.error("Instance ${instance.logName} update transaction failed!", e);
  }
  return null;
}

String getInstanceUpdateMessage(
  String instanceName,
  UpdateInstanceResult updateResult,
) {
  final buffer = StringBuffer();
  if(updateResult.instanceChanged) {
    buffer.write("Instance information updated. ");
  }
  if (updateResult.locationsRemoved.isNotEmpty) {
    buffer.write("${updateResult.locationsRemoved.length} locations removed. ");
  }
  if (updateResult.locationsAdded > 0) {
    buffer.write("${updateResult.locationsAdded} locations added. ");
  }
  if (updateResult.locationsUpdated.isNotEmpty) {
    buffer.write("${updateResult.locationsUpdated.length} locations updated.");
  }

  return buffer.toString().trim();
}
