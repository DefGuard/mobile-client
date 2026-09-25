import AVFoundation
import Flutter
import UIKit

public class QrPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        registrar.register(QrViewFactory(messenger: registrar.messenger()), withId: "net.defguard.qr_plugin/view")
    }
}

private class QrViewFactory: NSObject, FlutterPlatformViewFactory {
    private let messenger: FlutterBinaryMessenger

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
    }

    func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        QrView(frame: frame, channelId: args as! Int, messenger: messenger)
    }

    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        FlutterStandardMessageCodec.sharedInstance()
    }
}

private class PreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }

    override func layoutSubviews() {
        super.layoutSubviews()
        if #unavailable(iOS 17.0) {
            applyInterfaceOrientation()
        }
    }

    private func applyInterfaceOrientation() {
        guard let connection = previewLayer.connection, connection.isVideoOrientationSupported,
            let orientation = window?.windowScene?.interfaceOrientation,
            let videoOrientation = AVCaptureVideoOrientation(rawValue: orientation.rawValue)
        else { return }
        connection.videoOrientation = videoOrientation
    }
}

private class QrView: NSObject, FlutterPlatformView, AVCaptureMetadataOutputObjectsDelegate {
    private let preview: PreviewView
    private let channel: FlutterMethodChannel
    private let session = AVCaptureSession()
    private let output = AVCaptureMetadataOutput()
    private let queue = DispatchQueue(label: "net.defguard.qr_plugin.session")
    private var active = true
    private var runtimeErrorObserver: NSObjectProtocol?
    private var rotationCoordinator: AnyObject?
    private var rotationObservation: NSKeyValueObservation?

    init(frame: CGRect, channelId: Int, messenger: FlutterBinaryMessenger) {
        preview = PreviewView(frame: frame)
        channel = FlutterMethodChannel(name: "net.defguard.qr_plugin/view_\(channelId)", binaryMessenger: messenger)
        super.init()
        preview.previewLayer.session = session
        preview.previewLayer.videoGravity = .resizeAspectFill
        channel.setMethodCallHandler { [weak self] call, result in
            switch call.method {
            case "start": self?.active = true
            case "stop": self?.active = false
            case "dispose": self?.dispose()
            default: return result(FlutterMethodNotImplemented)
            }
            result(nil)
        }
        runtimeErrorObserver = NotificationCenter.default.addObserver(
            forName: AVCaptureSession.runtimeErrorNotification,
            object: session,
            queue: .main
        ) { [weak self] notification in
            let error = notification.userInfo?[AVCaptureSessionErrorKey] as? Error
            self?.fail("cameraError", error.map { "\($0)" } ?? "Capture session runtime error")
        }
        queue.async { [weak self] in self?.configure() }
    }

    deinit {
        removeObservers()
        stopSession()
    }

    func view() -> UIView {
        preview
    }

    private func configure() {
        let types: [AVCaptureDevice.DeviceType] = [.builtInTripleCamera, .builtInDualWideCamera, .builtInWideAngleCamera]
        guard let device = types.lazy.compactMap({ AVCaptureDevice.default($0, for: .video, position: .back) }).first
        else { return fail("noCamera", "No back camera available") }
        do {
            try device.lockForConfiguration()
            if device.isFocusModeSupported(.continuousAutoFocus) {
                device.focusMode = .continuousAutoFocus
            }
            if let factor = device.virtualDeviceSwitchOverVideoZoomFactors.first {
                device.videoZoomFactor = CGFloat(truncating: factor)
            }
            device.unlockForConfiguration()

            let input = try AVCaptureDeviceInput(device: device)
            session.beginConfiguration()
            guard session.canAddInput(input), session.canAddOutput(output) else {
                session.commitConfiguration()
                return fail("cameraError", "Session rejected camera input or metadata output")
            }
            session.addInput(input)
            session.addOutput(output)
            output.setMetadataObjectsDelegate(self, queue: .main)
            output.metadataObjectTypes = [.qr]
            session.commitConfiguration()
            session.startRunning()
            DispatchQueue.main.async { [weak self] in self?.onSessionStarted(device) }
        } catch {
            fail("cameraError", "\(error)")
        }
    }

    private func onSessionStarted(_ device: AVCaptureDevice) {
        guard #available(iOS 17.0, *) else { return preview.setNeedsLayout() }
        let coordinator = AVCaptureDevice.RotationCoordinator(device: device, previewLayer: preview.previewLayer)
        rotationCoordinator = coordinator
        rotationObservation = coordinator.observe(
            \.videoRotationAngleForHorizonLevelPreview,
            options: [.initial, .new]
        ) { [weak self] coordinator, _ in
            let angle = coordinator.videoRotationAngleForHorizonLevelPreview
            DispatchQueue.main.async {
                guard let connection = self?.preview.previewLayer.connection,
                    connection.isVideoRotationAngleSupported(angle)
                else { return }
                connection.videoRotationAngle = angle
            }
        }
    }

    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        let values = metadataObjects.lazy.compactMap { ($0 as? AVMetadataMachineReadableCodeObject)?.stringValue }
        guard active, let value = values.first(where: { !$0.isEmpty }) else { return }
        channel.invokeMethod("code", arguments: value)
    }

    private func fail(_ code: String, _ message: String) {
        DispatchQueue.main.async { [channel] in
            channel.invokeMethod("error", arguments: ["code": code, "message": message])
        }
    }

    private func dispose() {
        active = false
        channel.setMethodCallHandler(nil)
        removeObservers()
        queue.async { [output] in output.setMetadataObjectsDelegate(nil, queue: nil) }
        stopSession()
    }

    private func removeObservers() {
        if let observer = runtimeErrorObserver {
            NotificationCenter.default.removeObserver(observer)
            runtimeErrorObserver = nil
        }
        rotationObservation?.invalidate()
        rotationObservation = nil
        rotationCoordinator = nil
    }

    private func stopSession() {
        let session = session
        queue.async { session.stopRunning() }
    }
}
