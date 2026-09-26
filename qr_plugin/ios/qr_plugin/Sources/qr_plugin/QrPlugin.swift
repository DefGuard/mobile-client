import AVFoundation
import Flutter
import UIKit

public class QrPlugin: NSObject, FlutterPlugin {
    private let textures: FlutterTextureRegistry
    private let messenger: FlutterBinaryMessenger
    private var scanners: [Int: QrScanner] = [:]

    init(textures: FlutterTextureRegistry, messenger: FlutterBinaryMessenger) {
        self.textures = textures
        self.messenger = messenger
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = QrPlugin(textures: registrar.textures(), messenger: registrar.messenger())
        let channel = FlutterMethodChannel(name: "net.defguard.qr_plugin", binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let id = call.arguments as? Int else {
            return result(FlutterError(code: "cameraError", message: "Missing scanner id", details: nil))
        }
        switch call.method {
        case "create":
            scanners.removeValue(forKey: id)?.dispose()
            let scanner = QrScanner(id: id, textures: textures, messenger: messenger)
            scanners[id] = scanner
            result(scanner.textureId)
        case "dispose":
            scanners.removeValue(forKey: id)?.dispose()
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    public func detachFromEngine(for registrar: FlutterPluginRegistrar) {
        scanners.values.forEach { $0.dispose() }
        scanners.removeAll()
    }
}

private class QrScanner: NSObject, FlutterTexture, AVCaptureVideoDataOutputSampleBufferDelegate,
    AVCaptureMetadataOutputObjectsDelegate
{
    private let channel: FlutterMethodChannel
    private let textures: FlutterTextureRegistry
    private let session = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let metadataOutput = AVCaptureMetadataOutput()
    private let queue = DispatchQueue(label: "net.defguard.qr_plugin.session")
    private let bufferLock = NSLock()
    private var latestBuffer: CVPixelBuffer?
    private var bufferSize = CGSize.zero
    private(set) var textureId: Int64 = 0
    private var active = true
    private var runtimeErrorObserver: NSObjectProtocol?
    private var geometryObservation: NSKeyValueObservation?

    init(id: Int, textures: FlutterTextureRegistry, messenger: FlutterBinaryMessenger) {
        channel = FlutterMethodChannel(name: "net.defguard.qr_plugin/scanner_\(id)", binaryMessenger: messenger)
        self.textures = textures
        super.init()
        textureId = textures.register(self)
        channel.setMethodCallHandler { [weak self] call, result in
            switch call.method {
            case "start": self?.active = true
            case "stop": self?.active = false
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

    func copyPixelBuffer() -> Unmanaged<CVPixelBuffer>? {
        bufferLock.lock()
        defer { bufferLock.unlock() }
        return latestBuffer.map { Unmanaged.passRetained($0) }
    }

    private func configure() {
        let types: [AVCaptureDevice.DeviceType] = [.builtInTripleCamera, .builtInDualWideCamera, .builtInWideAngleCamera]
        guard let device = types.lazy.compactMap({ AVCaptureDevice.default($0, for: .video, position: .back) }).first
        else { return fail("noCamera", "No back camera available") }
        do {
            let input = try AVCaptureDeviceInput(device: device)
            session.beginConfiguration()
            guard session.canAddInput(input), session.canAddOutput(videoOutput), session.canAddOutput(metadataOutput)
            else {
                session.commitConfiguration()
                return fail("cameraError", "Session rejected camera input or outputs")
            }
            session.addInput(input)
            session.addOutput(videoOutput)
            session.addOutput(metadataOutput)
            if session.canSetSessionPreset(.hd1920x1080) {
                session.sessionPreset = .hd1920x1080
            }
            videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
            videoOutput.alwaysDiscardsLateVideoFrames = true
            videoOutput.setSampleBufferDelegate(self, queue: queue)
            metadataOutput.setMetadataObjectsDelegate(self, queue: .main)
            metadataOutput.metadataObjectTypes = [.qr]
            session.commitConfiguration()
            // Applying the preset resets the active format and zoom, so the device is set up afterwards.
            try configureDevice(device)
            session.startRunning()
            DispatchQueue.main.async { [weak self] in self?.onSessionStarted() }
        } catch {
            fail("cameraError", "\(error)")
        }
    }

    private func configureDevice(_ device: AVCaptureDevice) throws {
        try device.lockForConfiguration()
        defer { device.unlockForConfiguration() }
        let center = CGPoint(x: 0.5, y: 0.5)
        if device.isFocusPointOfInterestSupported {
            device.focusPointOfInterest = center
        }
        if device.isFocusModeSupported(.continuousAutoFocus) {
            device.focusMode = .continuousAutoFocus
        }
        if device.isAutoFocusRangeRestrictionSupported {
            device.autoFocusRangeRestriction = .near
        }
        if device.isExposurePointOfInterestSupported {
            device.exposurePointOfInterest = center
        }
        if device.isExposureModeSupported(.continuousAutoExposure) {
            device.exposureMode = .continuousAutoExposure
        }
        if let factor = device.virtualDeviceSwitchOverVideoZoomFactors.first {
            device.videoZoomFactor = CGFloat(truncating: factor)
        }
    }

    private func onSessionStarted() {
        let scene = UIApplication.shared.connectedScenes.lazy.compactMap { $0 as? UIWindowScene }.first
        applyInterfaceOrientation(scene)
        if #available(iOS 16.0, *) {
            geometryObservation = scene?.observe(\.effectiveGeometry) { [weak self] scene, _ in
                self?.applyInterfaceOrientation(scene)
            }
        }
    }

    // Buffers are rotated upright on the connection, so the Flutter texture is drawn as-is.
    private func applyInterfaceOrientation(_ scene: UIWindowScene?) {
        guard let connection = videoOutput.connection(with: .video), let orientation = scene?.interfaceOrientation
        else { return }
        if #available(iOS 17.0, *) {
            guard let angle = rotationAngle(orientation), connection.isVideoRotationAngleSupported(angle)
            else { return }
            connection.videoRotationAngle = angle
        } else {
            guard connection.isVideoOrientationSupported,
                let videoOrientation = AVCaptureVideoOrientation(rawValue: orientation.rawValue)
            else { return }
            connection.videoOrientation = videoOrientation
        }
    }

    private func rotationAngle(_ orientation: UIInterfaceOrientation) -> CGFloat? {
        switch orientation {
        case .landscapeRight: return 0
        case .portrait: return 90
        case .landscapeLeft: return 180
        case .portraitUpsideDown: return 270
        default: return nil
        }
    }

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let buffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let width = CVPixelBufferGetWidth(buffer)
        let height = CVPixelBufferGetHeight(buffer)
        let size = CGSize(width: width, height: height)
        if size != bufferSize {
            bufferSize = size
            DispatchQueue.main.async { [channel] in
                channel.invokeMethod("size", arguments: ["width": width, "height": height, "quarterTurns": 0])
            }
        }
        bufferLock.lock()
        latestBuffer = buffer
        bufferLock.unlock()
        textures.textureFrameAvailable(textureId)
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

    func dispose() {
        active = false
        channel.setMethodCallHandler(nil)
        if let observer = runtimeErrorObserver {
            NotificationCenter.default.removeObserver(observer)
            runtimeErrorObserver = nil
        }
        geometryObservation?.invalidate()
        geometryObservation = nil
        queue.async { [session, videoOutput, metadataOutput, textures, textureId] in
            videoOutput.setSampleBufferDelegate(nil, queue: nil)
            metadataOutput.setMetadataObjectsDelegate(nil, queue: nil)
            session.stopRunning()
            DispatchQueue.main.async { textures.unregisterTexture(textureId) }
        }
    }
}
