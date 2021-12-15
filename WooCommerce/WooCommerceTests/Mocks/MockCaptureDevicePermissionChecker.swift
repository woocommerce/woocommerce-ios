import AVFoundation
@testable import WooCommerce

/// A mock implementation of `CaptureDevicePermissionChecker` protocol.
struct MockCaptureDevicePermissionChecker: CaptureDevicePermissionChecker {
    private let authorizationStatus: AVAuthorizationStatus

    init(authorizationStatus: AVAuthorizationStatus) {
        self.authorizationStatus = authorizationStatus
    }

    func authorizationStatus(for mediaType: AVMediaType) -> AVAuthorizationStatus {
        authorizationStatus
    }
}
