# qr_plugin

Native QR scanner used by the defguard mobile client.

- Android: CameraX preview rendered into a Flutter texture, bundled ML Kit barcode scanning with auto-zoom.
- iOS: `AVCaptureSession` video output rendered into a Flutter texture + `AVCaptureMetadataOutput`, Swift Package Manager only.

Camera permission must be granted before `QrScannerView` is shown.
