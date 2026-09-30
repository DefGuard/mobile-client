import Flutter
import UIKit

public class Fido2Plugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "net.defguard.fido2_plugin", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(Fido2Plugin(), channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "nfcStatus":
      // TODO: yubikit-swift, NFCTagReaderSession.readingAvailable
      result(FlutterMethodNotImplemented)
    case "openNfcSettings":
      // TODO: iOS has no NFC toggle to open
      result(FlutterMethodNotImplemented)
    case "getAssertion":
      // TODO: yubikit-swift CTAP2.Session.getAssertion over NFCSmartCardConnection
      result(FlutterMethodNotImplemented)
    case "cancel":
      // TODO: cancel the NFC reader session
      result(FlutterMethodNotImplemented)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
