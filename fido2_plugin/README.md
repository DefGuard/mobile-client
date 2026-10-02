# fido2_plugin

FIDO2 security key assertions used by the defguard mobile client for connect-time MFA.

- Android: yubikit-android CTAP2 over NFC reader mode.
- iOS: yubikit-swift CTAP2 over a Core NFC ISO 7816 session. Needs iOS 16 and a Swift 6.1 toolchain (Xcode 16.3+).

Both work with any FIDO2 NFC key, not only YubiKeys: they select the standard FIDO applet and gate features on `authenticatorGetInfo` alone. Both platforms answer with the same error codes, see `Fido2ErrorCode`.

`getAssertion` sends a raw CTAP2 `authenticatorGetAssertion` with the caller's `clientDataHash`. Without `pin` no user verification is requested, so a credential registered with `credProtect=3` stays hidden. A key with a PIN set then answers `pinRequired`, and `noCredentials` always means the key holds none of the offered credentials.

## iOS host app setup

- Entitlement `com.apple.developer.nfc.readersession.formats` = `[TAG]`, with NFC Tag Reading enabled on the App ID.
- `Info.plist`: `NFCReaderUsageDescription`, and `com.apple.developer.nfc.readersession.iso7816.select-identifiers` = `[A0000006472F0001]`. Core NFC only reports keys that answer an AID listed there.

iOS has no NFC toggle, so `nfcStatus` is never `disabled` there and `openNfcSettings` fails with `nfcUnavailable`.
