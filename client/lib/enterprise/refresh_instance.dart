import 'package:mobile/data/db/database.dart';
import 'package:mobile/open/api.dart';
import 'package:mobile/utils/instance_secrets.dart';
import 'package:mobile/utils/update_instance.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../logging.dart';

part 'refresh_instance.g.dart';

enum InstanceRefreshOutcome { refreshed, licenseError, missingToken, failed }

Future<void> disableEnterprise(
  AppDatabase db,
  DefguardInstance instance,
) async {
  talker.warning(
    "Instance ${instance.logName} not refreshed: enterprise license unavailable (402)",
  );
  await db.managers.defguardInstances.replace(
    instance.copyWith(
      clientTrafficPolicy: .none,
      enterpriseEnabled: false,
    ),
  );
}

Future<InstanceRefreshOutcome> refreshInstance(
  AppDatabase db,
  DefguardInstance instance, {
  ProxyApi? api,
}) async {
  try {
    final token = await instance.pollingToken();
    if (token == null) {
      reportMissingSecret(instance.logName, "Proxy token");
      return .missingToken;
    }
    final (responseData, responseStatus, _) = await (api ?? proxyApi)
        .pollConfiguration(instance.proxyUrl, token);
    if (responseStatus == 402) {
      await disableEnterprise(db, instance);
      return .licenseError;
    }
    if (responseData == null) {
      talker.error(
        "Instance ${instance.logName} not refreshed: update data retrieval failed, status: ${responseStatus ?? "unknown"}",
      );
      return .failed;
    }
    final updateResult = await updateInstance(
      db: db,
      instance: instance,
      configs: responseData.configs,
      info: responseData.instance,
      token: responseData.token,
    );
    if (updateResult == null) return .failed;
    if (updateResult.didChange) {
      talker.info(
        "Instance ${instance.logName} updated: ${getInstanceUpdateMessage(instance.name, updateResult)}",
      );
    }
    return .refreshed;
  } catch (e, st) {
    talker.error("Instance ${instance.logName} refresh failed", e, st);
    return .failed;
  }
}

@Riverpod(keepAlive: true)
class EnterpriseRefresh extends _$EnterpriseRefresh {
  @override
  bool build() => false;

  // null when another refresh is still running
  Future<({int refreshed, int total})?> refreshAll() async {
    if (state) return null;
    state = true;
    try {
      final db = ref.read(databaseProvider);
      final instances = await db.managers.defguardInstances
          .filter((f) => f.enterpriseEnabled(true))
          .get();
      final outcomes = await Future.wait(
        instances.map((instance) => refreshInstance(db, instance)),
      );
      final refreshed = outcomes.where((o) => o == .refreshed).length;
      talker.info(
        "Manual refresh: $refreshed of ${instances.length} enterprise instances refreshed",
      );
      return (refreshed: refreshed, total: instances.length);
    } catch (e, st) {
      talker.error("Manual enterprise refresh failed", e, st);
      return (refreshed: 0, total: 0);
    } finally {
      state = false;
    }
  }
}
