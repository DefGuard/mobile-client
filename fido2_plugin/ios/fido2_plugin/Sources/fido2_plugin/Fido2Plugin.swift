import CoreNFC
import Flutter
import UIKit
import YubiKit

private struct AssertionRequest: Sendable {
    let rpId: String
    let clientDataHash: Data
    let allowCredentials: [Data]
    let pin: String?
}

private struct Assertion: Sendable {
    let authenticatorData: Data
    let signature: Data
    let credentialId: Data
}

private struct PinInvalid: Error {
    let retries: Int?
}

/// A CTAP status the plugin concludes on its own, without the key answering it.
private struct CtapFailure: Error {
    let error: CTAP2.Error
}

private struct MalformedAssertion: Error {}

/// Shown on the system NFC sheet as it closes.
private struct SheetError: LocalizedError {
    let errorDescription: String?
}

private final class Ceremony {
    let result: FlutterResult
    var task: Task<Void, Never>?
    var timeout: Task<Void, Never>?
    var connection: NFCSmartCardConnection?
    var timedOut = false

    init(result: @escaping FlutterResult) {
        self.result = result
    }
}

// State is only touched on the main thread: from `handle` and from main-actor tasks.
public class Fido2Plugin: NSObject, FlutterPlugin {
    private var pending: Ceremony?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "net.defguard.fido2_plugin", binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(Fido2Plugin(), channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "nfcStatus":
            // iOS has no NFC toggle, so a reader is either there or not.
            result(NFCTagReaderSession.readingAvailable ? "enabled" : "unsupported")
        case "openNfcSettings":
            result(FlutterError(code: "nfcUnavailable", message: "iOS has no NFC setting", details: nil))
        case "getAssertion":
            getAssertion(call, result: result)
        case "cancel":
            cancelPending()
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    public func detachFromEngine(for registrar: FlutterPluginRegistrar) {
        cancelPending()
    }

    private func getAssertion(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
            let rpId = args["rpId"] as? String,
            let clientDataHash = args["clientDataHash"] as? FlutterStandardTypedData,
            let allowCredentials = args["allowCredentials"] as? [FlutterStandardTypedData],
            let timeoutMs = args["timeoutMs"] as? Int
        else {
            return result(FlutterError(code: "unknown", message: "Malformed getAssertion arguments", details: nil))
        }
        let request = AssertionRequest(
            rpId: rpId,
            clientDataHash: clientDataHash.data,
            allowCredentials: allowCredentials.map(\.data),
            pin: args["pin"] as? String
        )

        // The previous ceremony must release the single NFC session before the next one asks for it.
        let previous = pending?.task
        cancelPending()

        let ceremony = Ceremony(result: result)
        pending = ceremony
        ceremony.task = Task { @MainActor [weak self] in
            await previous?.value
            await self?.run(ceremony, request)
        }
        ceremony.timeout = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(max(timeoutMs, 0)) * 1_000_000)
            if Task.isCancelled { return }
            ceremony.timedOut = true
            ceremony.task?.cancel()
        }
    }

    @MainActor
    private func run(_ ceremony: Ceremony, _ request: AssertionRequest) async {
        let connection: NFCSmartCardConnection
        do {
            connection = try await NFCSmartCardConnection(
                alertMessage: "Hold your security key near the top of your iPhone."
            )
        } catch {
            finish(ceremony) { reportError($0, error, timedOut: ceremony.timedOut) }
            return
        }
        // Every exchange from here on is bounded by Core NFC, so the tap wait no longer applies.
        ceremony.timeout?.cancel()
        // The tag connected just as the ceremony was cancelled or timed out.
        if pending !== ceremony || Task.isCancelled {
            await connection.close(message: nil)
            finish(ceremony) { reportError($0, SmartCardConnectionError.cancelled, timedOut: ceremony.timedOut) }
            return
        }

        ceremony.connection = connection
        let outcome: Result<Assertion, Error>
        do {
            outcome = .success(try await performAssertion(connection, request))
        } catch {
            outcome = .failure(error)
        }
        ceremony.connection = nil

        switch outcome {
        case .success(let assertion):
            finish(ceremony) {
                $0([
                    "authenticatorData": FlutterStandardTypedData(bytes: assertion.authenticatorData),
                    "signature": FlutterStandardTypedData(bytes: assertion.signature),
                    "credentialId": FlutterStandardTypedData(bytes: assertion.credentialId),
                ])
            }
            await connection.close(message: "Security key verified")
        case .failure(let error):
            finish(ceremony) { reportError($0, error, timedOut: false) }
            await connection.close(error: SheetError(errorDescription: sheetMessage(for: error)))
        }
    }

    private func performAssertion(_ connection: NFCSmartCardConnection, _ request: AssertionRequest) async throws
        -> Assertion
    {
        let session = try await CTAP2.Session.makeSession(connection: connection)
        let info = try await session.getInfo()

        var token: CTAP2.Token?
        if let pin = request.pin {
            guard info.options.clientPin == true else { throw CtapFailure(error: .pinNotSet) }
            do {
                token = try await session.getPinUVToken(
                    using: .pin(pin),
                    permissions: .getAssertion,
                    rpId: request.rpId
                )
            } catch {
                guard case .ctapError(.pinInvalid, _) = error else { throw error }
                throw PinInvalid(retries: try? await session.getPinRetries().retries)
            }
        }

        let descriptors = request.allowCredentials.map { WebAuthn.CredentialDescriptor(id: $0) }
        let chunkSize = max(Int(info.maxCredentialCountInList ?? 1), 1)
        for start in stride(from: 0, to: descriptors.count, by: chunkSize) {
            let chunk = Array(descriptors[start..<min(start + chunkSize, descriptors.count)])
            let response: CTAP2.GetAssertion.Response
            do {
                response = try await session.getAssertion(
                    parameters: .init(rpId: request.rpId, clientDataHash: request.clientDataHash, allowList: chunk),
                    token: token
                ).value
            } catch {
                if case .ctapError(.noCredentials, _) = error { continue }
                throw error
            }
            // A key may omit the credential when the allow list held only one.
            guard let credentialId = response.credential?.id ?? (chunk.count == 1 ? chunk[0].id : nil) else {
                throw MalformedAssertion()
            }
            return Assertion(
                authenticatorData: response.authenticatorData.rawData,
                signature: response.signature,
                credentialId: credentialId
            )
        }
        // A key with a PIN set may be hiding a credential registered with credProtect=3.
        if request.pin == nil && info.options.clientPin == true {
            throw CtapFailure(error: .puatRequired)
        }
        throw CtapFailure(error: .noCredentials)
    }

    private func finish(_ ceremony: Ceremony, _ deliver: (FlutterResult) -> Void) {
        guard pending === ceremony else { return }
        pending = nil
        ceremony.timeout?.cancel()
        deliver(ceremony.result)
    }

    private func cancelPending() {
        guard let ceremony = pending else { return }
        ceremony.task?.cancel()
        // Cancelling the task only dismisses a sheet still waiting for a tap; a connected one is closed here.
        if let connection = ceremony.connection {
            Task { await connection.close(message: nil) }
        }
        finish(ceremony) { $0(FlutterError(code: "cancelled", message: "Cancelled", details: nil)) }
    }
}

// Codes and details match the Android implementation, which the Dart side maps one-to-one.
private func reportError(_ result: FlutterResult, _ error: Error, timedOut: Bool) {
    let (code, details) = classify(error, timedOut: timedOut)
    result(FlutterError(code: code, message: String(describing: error), details: details))
}

private func classify(_ error: Error, timedOut: Bool) -> (String, [String: Any]?) {
    switch error {
    case let error as PinInvalid:
        return ("pinInvalid", ["pinRetries": error.retries.map { $0 as Any } ?? NSNull()])
    case let error as CtapFailure:
        return classify(ctap: error.error)
    case let error as CTAP2.SessionError:
        switch error {
        case .ctapError(let ctap, _):
            return classify(ctap: ctap)
        case .featureNotSupported:
            // The FIDO applet answered SELECT with 6A82 or 6D00.
            return ("unsupportedKey", nil)
        case .connectionError(let connection, _):
            return (classify(connection: connection, timedOut: timedOut), nil)
        default:
            return ("unknown", nil)
        }
    case let error as SmartCardConnectionError:
        return (classify(connection: error, timedOut: timedOut), nil)
    default:
        return ("unknown", nil)
    }
}

private func classify(ctap error: CTAP2.Error) -> (String, [String: Any]?) {
    let code =
        switch error {
        case .noCredentials: "noCredentials"
        case .puatRequired: "pinRequired"
        case .pinInvalid: "pinInvalid"
        case .pinBlocked, .uvBlocked: "pinBlocked"
        case .pinAuthBlocked: "pinAuthBlocked"
        case .pinNotSet: "pinNotSet"
        default: "unknown"
        }
    return (code, ctapByte(error).map { ["ctapError": Int($0)] })
}

private func classify(connection error: SmartCardConnectionError, timedOut: Bool) -> String {
    switch error {
    case .unsupported:
        return "nfcUnavailable"
    case .cancelled:
        return timedOut ? "timeout" : "cancelled"
    case .cancelledByUser:
        return "cancelled"
    case .noDevicesFound:
        return "timeout"
    case .transmitFailed, .connectionLost:
        return "tagLost"
    case .setupFailed(_, let cause):
        // Core NFC closes its sheet on its own after about 60 seconds.
        return (cause as? NFCReaderError)?.code == .readerSessionInvalidationErrorSessionTimeout
            ? "timeout" : "unknown"
    case .busy, .malformedData, .pollingFailed:
        return "unknown"
    }
}

/// yubikit-swift keeps the status byte private for the cases it names.
private func ctapByte(_ error: CTAP2.Error) -> UInt8? {
    switch error {
    case .noCredentials: 0x2E
    case .pinInvalid: 0x31
    case .pinBlocked: 0x32
    case .pinAuthInvalid: 0x33
    case .pinAuthBlocked: 0x34
    case .pinNotSet: 0x35
    case .puatRequired: 0x36
    case .uvBlocked: 0x3C
    case .extension(let byte), .vendor(let byte), .unknown(let byte): byte
    default: nil
    }
}

private func sheetMessage(for error: Error) -> String {
    switch classify(error, timedOut: false).0 {
    case "noCredentials": "This security key is not registered"
    case "pinRequired": "This security key requires a PIN"
    case "pinInvalid": "Incorrect PIN"
    case "pinBlocked": "PIN blocked"
    case "pinAuthBlocked": "Too many wrong PINs"
    case "pinNotSet": "This security key has no PIN"
    case "unsupportedKey": "This key does not support FIDO2"
    case "tagLost": "Connection to the key was lost"
    default: "Verification failed"
    }
}
