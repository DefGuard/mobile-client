import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/data/proxy/qr_register.dart';
import 'package:mobile/logging.dart';
import 'package:mobile/open/widgets/navigation/dg_scaffold.dart';
import 'package:mobile/router/routes.dart';
import 'package:mobile/theme/color.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanInstanceQrScreen extends HookConsumerWidget {
  const ScanInstanceQrScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useMemoized(
      () => StreamController<QrInstanceRegistration>.broadcast(),
    );
    final controllerRef = useRef(controller);

    useEffect(() {
      final sub = controllerRef.value.stream.take(1).listen((data) {
        if (context.mounted) {
          RegisterFromQrScreenRoute(data).push(context);
        }
      });

      return () {
        sub.cancel();
        controllerRef.value.close();
      };
    }, []);

    return DgScaffold(
      title: "Scan QR",
      child: Container(
        color: DgColor.frameBg,
        child: SafeArea(
          top: false,
          child: MobileScanner(
            onDetectError: (err, trace) {
              talker.error("Mobile scanner widget failed !", err, trace);
            },
            onDetect: (result) {
              final readResult = result.barcodes.first.rawValue;
              if (readResult != null) {
                try {
                  final decodedString = utf8.decode(base64Decode(readResult));
                  final data = QrInstanceRegistration.fromJson(
                    jsonDecode(decodedString),
                  );
                  controllerRef.value.add(data);
                } catch (e) {
                  debugPrint("Error $e");
                }
              }
            },
          ),
        ),
      ),
    );
  }
}
