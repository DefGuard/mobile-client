import 'dart:convert';

import 'package:mobile/data/proxy/enrollment.dart';
import 'package:x25519/x25519.dart' as x;


Future<WireguardEncodedKeyPair> generateWireguardKeyPair() async {
  final keyPair = x.generateKeyPair();
  final encodedPriv = base64Encode(keyPair.privateKey);
  final encodedPub = base64Encode(keyPair.publicKey);

  return WireguardEncodedKeyPair(
    privKey: encodedPriv,
    pubKey: encodedPub,
  );
}
