import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/data/db/database.dart';
import 'package:mobile/open/api.dart';
import 'package:mobile/open/constants.dart';
import 'package:mobile/utils/update_instance.dart';
import "package:flutter/foundation.dart";

import '../logging.dart';

class ConfigurationUpdater extends HookConsumerWidget {
  final Widget child;

  const ConfigurationUpdater({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updatePending = useState(false);
    final db = ref.read(databaseProvider);
    final lifecycle = useAppLifecycleState();

    final updateConfiguration = useCallback(() async {
      // cancel if update is already pending
      if (updatePending.value) return;
      updatePending.value = true;
      try {
        final instances = await db.managers.defguardInstances.get();
        if (instances.isEmpty) {
          talker.debug("Auto configuration polling canceled, no instances.");
          updatePending.value = false;
          return;
        }
        talker.debug(
          "Polling configurations for ${instances.length} instances.",
        );
        for (final instance in instances) {
          talker.debug(
            "Auto configuration update started for ${instance.name} (${instance.id})",
          );
          final proxyUrl = kDebugMode ? localDebugProxyUrl : instance.proxyUrl;
          final (responseData, responseStatus) = await proxyApi
              .pollConfiguration(proxyUrl, instance.token);
          // instance lost it's enterprise status
          if (responseStatus == 402) {
            instance.copyWith(
              disableAllTraffic: false,
              enterpriseEnabled: false,
            );
            await db.managers.defguardInstances.replace(instance);
            continue;
          }
          if (responseData == null) {
            talker.error(
              "Auto configuration update failed for ${instance.logName} ! Proxy response empty !",
            );
            continue;
          }
          try {
            await updateInstance(
              db: db,
              instance: instance,
              configs: responseData.configs,
              info: responseData.instance,
            );
          } catch (e) {
            talker.error(
              "Failed to process update for ${instance.logName} ",
              e,
            );
          }
        }
      } catch (e) {
        talker.error("Auto configuration update handler failed !", e);
      } finally {
        updatePending.value = false;
      }
    }, [updatePending]);

    useEffect(() {
      updateConfiguration();
      return null;
    }, []);

    // update when user wakes up application
    useEffect(() {
      if (lifecycle == AppLifecycleState.resumed) {
        updateConfiguration();
      }
      return null;
    }, [lifecycle]);

    return child;
  }
}
