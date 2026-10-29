import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/open/widgets/rive_asset_animation.dart';

const _assetRoot = 'assets/next/';

Future<void> precacheAppAssets(BuildContext context) async {
  final manifest = await AssetManifest.loadFromAssetBundle(
    DefaultAssetBundle.of(context),
  );
  if (!context.mounted) return;

  await Future.wait([
    for (final path in manifest.listAssets())
      if (path.startsWith(_assetRoot))
        if (path.endsWith('.riv'))
          RiveFileCache.load(path)
        else if (path.endsWith('.svg'))
          SvgAssetLoader(path).loadBytes(context)
        else if (path.endsWith('.png'))
          precacheImage(AssetImage(path), context),
  ]);
}
