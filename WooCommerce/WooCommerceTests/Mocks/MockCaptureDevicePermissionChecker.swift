import AVFoundation
@testable import WooCommerce

/// An implementation of `CaptureDevicePermissionChecker` protocol using `AVFoundation`.
struct MockCaptureDevicePermissionChecker: CaptureDevicePermissionChecker {
    private let authorizationStatus: AVAuthorizationStatus

    init(authorizationStatus: AVAuthorizationStatus) {
        self.authorizationStatus = authorizationStatus
    }

    func authorizationStatus(for mediaType: AVMediaType) -> AVAuthorizationStatus {
        authorizationStatus
    }
}
