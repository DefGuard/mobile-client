import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:fido2_plugin/fido2_plugin.dart';
import 'package:mobile/data/mfa/fido2_pin_memory.dart';

sealed class Fido2Attempt {
  const Fido2Attempt();
}

class Fido2Success extends Fido2Attempt {
  final Fido2Assertion assertion;

  const Fido2Success(this.assertion);
}

/// The key hid its credential or demanded a PIN, which a credential registered
/// with `credProtect=3` does whenever no PIN is given.
class Fido2NeedsPin extends Fido2Attempt {
  const Fido2NeedsPin();
}

/// Even with the PIN the key has none of the offered credentials.
class Fido2WrongKey extends Fido2Attempt {
  const Fido2WrongKey();
}

class Fido2PinInvalid extends Fido2Attempt {
  final int? retries;

  const Fido2PinInvalid(this.retries);
}

class Fido2Failed extends Fido2Attempt {
  final Fido2Exception error;

  const Fido2Failed(this.error);
}

/// One tap against the key. Signs the server's challenge the way the core
/// verifies it: `clientDataHash = SHA-256(challenge)`, no clientDataJSON.
class Fido2StepRunner {
  final Fido2Plugin plugin;
  final Fido2PinMemory pinMemory;

  const Fido2StepRunner({
    this.plugin = const Fido2Plugin(),
    required this.pinMemory,
  });

  Future<Fido2Attempt> attempt({
    required String rpId,
    required String challenge,
    required List<String> credentialIds,
    String? pin,
  }) async {
    final Fido2Assertion assertion;
    try {
      assertion = await plugin.getAssertion(
        rpId: rpId,
        clientDataHash: Uint8List.fromList(
          sha256.convert(utf8.encode(challenge)).bytes,
        ),
        allowCredentials: credentialIds.map(decodeCredentialId).toList(),
        pin: pin,
      );
    } on Fido2Exception catch (e) {
      return switch (e.code) {
        Fido2ErrorCode.noCredentials when pin == null => const Fido2NeedsPin(),
        Fido2ErrorCode.pinRequired => const Fido2NeedsPin(),
        Fido2ErrorCode.noCredentials => const Fido2WrongKey(),
        Fido2ErrorCode.pinInvalid => Fido2PinInvalid(e.pinRetries),
        _ => Fido2Failed(e),
      };
    }

    if (pin != null) {
      await pinMemory.remember(encodeCredentialId(assertion.credentialId));
    }
    return Fido2Success(assertion);
  }
}

Uint8List decodeCredentialId(String id) =>
    base64Url.decode(base64Url.normalize(id));

String encodeCredentialId(List<int> id) =>
    base64Url.encode(id).replaceAll('=', '');
