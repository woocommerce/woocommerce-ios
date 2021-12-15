import AVFoundation

/// A protocol that checks device permission to capture media.
protocol CaptureDevicePermissionChecker {
    /// Returns a constant indicating whether the app has permission for recording a specified media type.
    /// - Returns: A constant indicating authorization status.
    func authorizationStatus(for mediaType: AVMediaType) -> AVAuthorizationStatus

    /// Requests the user’s permission, if needed, for recording a specified media type.
    /// - Parameters:
    ///   - mediaType: A media type constant, either video or audio.
    ///   - handler: A block to be called once permission is granted or denied, always on the main thread.
    func requestAccess(for mediaType: AVMediaType,
                       completionHandler handler: @escaping (_ isGranted: Bool) -> Void)
}

/// An implementation of `CaptureDevicePermissionChecker` protocol using `AVFoundation`.
struct AVCaptureDevicePermissionChecker: CaptureDevicePermissionChecker {
    func authorizationStatus(for mediaType: AVMediaType) -> AVAuthorizationStatus {
        AVCaptureDevice.authorizationStatus(for: mediaType)
    }

    func requestAccess(for mediaType: AVMediaType,
                       completionHandler handler: @escaping (_ isGranted: Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: mediaType) { granted in
            DispatchQueue.main.async {
                handler(granted)
            }
        }
    }
}
