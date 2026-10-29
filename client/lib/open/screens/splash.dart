import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/data/db/database.dart';
import 'package:mobile/logging.dart';
import 'package:mobile/router/routes.dart';
import 'package:mobile/theme/color.dart';
import 'package:mobile/utils/asset_precache.dart';

const _splashCanvasSize = 288.0;
const _assetWarmUpLimit = Duration(milliseconds: 1500);

Future<void> _warmUpAssets(BuildContext context) async {
  try {
    await precacheAppAssets(context).timeout(_assetWarmUpLimit);
  } on TimeoutException {
    talker.warning("Asset warm-up exceeded $_assetWarmUpLimit");
  } catch (e, s) {
    talker.error("Asset warm-up failed", e, s);
  }
}

class AppSplash extends HookConsumerWidget {
  const AppSplash({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    final instancesAsync = useStream(
      useMemoized(() => db.select(db.defguardInstances).watch(), [db]),
    );

    final timerDone = useState(false);
    final warmUp = useFuture(useMemoized(() => _warmUpAssets(context)));
    final assetsWarm = warmUp.connectionState == .done;

    useEffect(() {
      final timer = Timer(const Duration(milliseconds: 300), () {
        timerDone.value = true;
      });
      return timer.cancel;
    }, []);

    useEffect(() {
      final instances = instancesAsync.data;
      if (instances != null && timerDone.value && assetsWarm) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            if (instances.isEmpty) {
              const AddInstanceScreenRoute().go(context);
            } else if (instances.length == 1) {
              InstanceScreenRoute(id: instances[0].id.toString()).go(context);
            } else {
              const InstancesListScreenRoute().go(context);
            }
          }
        });
      }
      return null;
    }, [instancesAsync.data, timerDone.value, assetsWarm]);

    return ColoredBox(
      color: DgColor.bgAppBase,
      child: Center(
        child: Image.asset("assets/splash/logo.png", width: _splashCanvasSize),
      ),
    );
  }
}
