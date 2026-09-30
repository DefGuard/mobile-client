# fido2_plugin

FIDO2 security key assertions used by the defguard mobile client for connect-time MFA.

- Android: yubikit-android CTAP2 over NFC reader mode. Works with any FIDO2 NFC key, not only YubiKeys.
- iOS: not implemented yet, every call answers `FlutterMethodNotImplemented`.

`getAssertion` sends a raw CTAP2 `authenticatorGetAssertion` with the caller's `clientDataHash`. Without `pin` no user verification is requested, so a credential registered with `credProtect=3` stays hidden. A key with a PIN set then answers `pinRequired`, and `noCredentials` always means the key holds none of the offered credentials.
