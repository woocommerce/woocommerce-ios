import AVFoundation

/// A protocol that checks device permission to capture media.
protocol CaptureDevicePermissionChecker {
    /// Returns a constant indicating whether the app has permission for recording a specified media type.
    /// - Returns: A constant indicating authorization status.
    func authorizationStatus(for mediaType: AVMediaType) -> AVAuthorizationStatus
}

/// An implementation of `CaptureDevicePermissionChecker` protocol using `AVFoundation`.
struct AVCaptureDevicePermissionChecker: CaptureDevicePermissionChecker {
    func authorizationStatus(for mediaType: AVMediaType) -> AVAuthorizationStatus {
        AVCaptureDevice.authorizationStatus(for: mediaType)
    }
}
