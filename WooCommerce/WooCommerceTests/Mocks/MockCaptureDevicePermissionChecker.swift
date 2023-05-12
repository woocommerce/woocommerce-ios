import AVFoundation
@testable import WooCommerce

/// A mock implementation of `CaptureDevicePermissionChecker` protocol.
final class MockCaptureDevicePermissionChecker {
    private var authorizationStatus: AVAuthorizationStatus
    private var updatedAuthorizationStatus: AVAuthorizationStatus? = nil
    private var isAccessGranted: Bool = false

    init(authorizationStatus: AVAuthorizationStatus) {
        self.authorizationStatus = authorizationStatus
    }

    func whenRequestingAccess(thenReturn isGranted: Bool) {
        isAccessGranted = isGranted
    }

    func whenRequestingAccess(setAuthorizationStatus status: AVAuthorizationStatus) {
        updatedAuthorizationStatus = status
    }
}

extension MockCaptureDevicePermissionChecker: CaptureDevicePermissionChecker {
    func authorizationStatus(for mediaType: AVMediaType) -> AVAuthorizationStatus {
        authorizationStatus
    }

    func requestAccess(for mediaType: AVMediaType, completionHandler handler: @escaping (_ isGranted: Bool) -> Void) {
        if let updatedAuthorizationStatus = updatedAuthorizationStatus {
            authorizationStatus = updatedAuthorizationStatus
        }
        handler(isAccessGranted)
    }
}
