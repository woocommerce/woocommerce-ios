import AVFoundation

/// Async wrapper over `AVCaptureDevice` authorization. Injected into the
/// coordinator so the prologue's "Scan QR code" tap can be flow-tested
/// without a real device camera.
protocol QRLoginCameraPermissionCheckerProtocol: Sendable {
    var status: AVAuthorizationStatus { get }
    func requestAccess() async -> Bool
}

struct DefaultQRLoginCameraPermissionChecker: QRLoginCameraPermissionCheckerProtocol {
    var status: AVAuthorizationStatus {
        AVCaptureDevice.authorizationStatus(for: .video)
    }

    func requestAccess() async -> Bool {
        await AVCaptureDevice.requestAccess(for: .video)
    }
}
