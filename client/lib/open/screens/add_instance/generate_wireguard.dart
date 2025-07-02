import 'dart:convert';

import 'package:cryptography_plus/cryptography_plus.dart';
import 'package:mobile/data/proxy/enrollment.dart';

Future<WireguardEncodedKeyPair> generateWireguardKeyPair() async {
  final algorithm = X25519();
  final keyPair = await algorithm.newKeyPair();
  final privateKeyBytes = await keyPair.extractPrivateKeyBytes();
  final publicKey = await keyPair.extractPublicKey();
  final encodedPriv = base64Encode(privateKeyBytes);
  final encodedPublic = base64Encode(publicKey.bytes);

  return WireguardEncodedKeyPair(privKey: encodedPriv, pubKey: encodedPublic);
}
