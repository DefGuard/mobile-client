import 'package:flutter/foundation.dart';

/// Phones without an NFC reader still pass; the FIDO2 screen tells the user.
bool get fido2Supported =>
    defaultTargetPlatform == TargetPlatform.android ||
    defaultTargetPlatform == TargetPlatform.iOS;
