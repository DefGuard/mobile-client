# qr_plugin

Native QR scanner view used by the defguard mobile client.

- Android: CameraX `LifecycleCameraController` + `PreviewView`, bundled ML Kit barcode scanning with auto-zoom.
- iOS: `AVCaptureSession` + `AVCaptureMetadataOutput`, Swift Package Manager only.

Camera permission must be granted before `QrScannerView` is shown.
