import 'dart:convert';

import 'package:passkeys/types.dart';

RegisterRequestType parseProxyPasskeyRegistrationResponse(String responseData) {
  Map<String, dynamic> data = jsonDecode(responseData)['publicKey'];
  final challenge = data['challenge'];
  final List<CredentialType> excludeCredentials =
      (data['excludeCredentials'] as List?)
          ?.map(
            (cred) => CredentialType(
              type: cred['type_'],
              id: cred['id'],
              transports: cred['transports'] ?? [],
            ),
          )
          .toList() ??
      [];
  final pubKeyCredParams = (data['pubKeyCredParams'] as List?)?.map(
    (param) => PubKeyCredParamType(alg: param['alg'], type: param['type']),
  ).toList();
  final timeout = data['timeout'];
  final user = UserType(
    displayName: data['user']['displayName'],
    name: data['user']['name'],
    id: data['user']['id'],
  );
  final relyingParty = RelyingPartyType(
    id: data['rp']['id'],
    name: data['rp']['name'],
  );
  final authSelectionType = AuthenticatorSelectionType(
    requireResidentKey: data['authenticatorSelection']['requireResidentKey'],
    residentKey: data['authenticatorSelection']['residentKey'],
    userVerification: data['authenticatorSelection']['userVerification'],
  );
  final attestation = data['attestation'];
  return RegisterRequestType(
    challenge: challenge,
    relyingParty: relyingParty,
    user: user,
    authSelectionType: authSelectionType,
    attestation: attestation,
    excludeCredentials: excludeCredentials,
    timeout: timeout,
    pubKeyCredParams: pubKeyCredParams,
  );
}
