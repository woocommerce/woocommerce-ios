import AVFoundation
@testable import WooCommerce

/// A mock implementation of `CaptureDevicePermissionChecker` protocol.
final class MockCaptureDevicePermissionChecker {
    private let authorizationStatus: AVAuthorizationStatus
    private var isAccessGranted: Bool = false

    init(authorizationStatus: AVAuthorizationStatus) {
        self.authorizationStatus = authorizationStatus
    }

    func whenRequestingAccess(thenReturn isGranted: Bool) {
        isAccessGranted = isGranted
    }
}

extension MockCaptureDevicePermissionChecker: CaptureDevicePermissionChecker {
    func authorizationStatus(for mediaType: AVMediaType) -> AVAuthorizationStatus {
        authorizationStatus
    }

    func requestAccess(for mediaType: AVMediaType, completionHandler handler: @escaping (_ isGranted: Bool) -> Void) {
        handler(isAccessGranted)
    }
}
