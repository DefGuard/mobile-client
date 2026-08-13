import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/data/db/database.dart';
import 'package:mobile/router/routes.dart';
import 'package:mobile/theme/next/color.dart';

class AppSplash extends HookConsumerWidget {
  const AppSplash({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    final instancesAsync = useStream(
      useMemoized(() => db.select(db.defguardInstances).watch(), [db]),
    );

    final timerDone = useState(false);

    useEffect(() {
      final timer = Timer(const Duration(milliseconds: 300), () {
        timerDone.value = true;
      });
      return timer.cancel;
    }, []);

    useEffect(() {
      final instances = instancesAsync.data;
      if (instances != null && timerDone.value) {
        if (instances.isEmpty) {
          const AddInstanceScreenRoute().go(context);
        } else if (instances.length == 1) {
          InstanceScreenRoute(id: instances[0].id.toString()).go(context);
        } else {
          const InstancesListScreenRoute().go(context);
        }
      }
      return null;
    }, [instancesAsync.data, timerDone.value]);

    return Container(
      decoration: const BoxDecoration(gradient: NextColor.gradientPrimary),
      child: Center(child: Image.asset("assets/splash/logo.png")),
    );
  }
}
