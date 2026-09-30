import 'package:flutter/foundation.dart';

/// Only Android has an NFC implementation so far; the iOS side of the plugin is
/// a stub.
bool get fido2Supported => defaultTargetPlatform == TargetPlatform.android;
