import TestKit
import XCTest
@testable import WooCommerce

final class ProductSKUBarcodeScannerCoordinatorTests: XCTestCase {
    private var navigationController: UINavigationController!
    private var window: UIWindow?

    override func setUp() {
        super.setUp()
        navigationController = UINavigationController()

        let window = UIWindow(frame: UIScreen.main.bounds)
        window.makeKeyAndVisible()
        window.rootViewController = navigationController
        self.window = window
    }

    override func tearDown() {
        navigationController = nil

        // Resets `UIWindow` and its view hierarchy so that it can be deallocated cleanly.
        window?.resignKey()
        window?.rootViewController = nil

        super.tearDown()
    }

    func test_coordinator_shows_sku_scanner_after_granting_camera_access() {
        // Given
        let permissionChecker = MockCaptureDevicePermissionChecker(authorizationStatus: .notDetermined)
        // Grants access.
        permissionChecker.whenRequestingAccess(thenReturn: true)
        let coordinator = ProducBarcodeScannerCoordinator(sourceNavigationController: navigationController,
                                                              permissionChecker: permissionChecker,
                                                              onBarcodeScanned: { _ in })

        // When
        coordinator.start()

        // Then
        assertThat(navigationController.presentedViewController, isAnInstanceOf: ScannerContainerViewController.self)
    }

    func test_coordinator_does_not_present_scanner_after_denying_camera_access() {
        // Given
        let permissionChecker = MockCaptureDevicePermissionChecker(authorizationStatus: .notDetermined)
        // Denies access.
        permissionChecker.whenRequestingAccess(thenReturn: false)
        let coordinator = ProducBarcodeScannerCoordinator(sourceNavigationController: navigationController,
                                                              permissionChecker: permissionChecker,
                                                              onBarcodeScanned: { _ in })

        // When
        coordinator.start()

        // Then
        XCTAssertNil(navigationController.topViewController)
        XCTAssertNil(navigationController.presentedViewController)
    }

    func test_coordinator_shows_sku_scanner_when_permission_is_authorized() {
        // Given
        let coordinator = ProducBarcodeScannerCoordinator(sourceNavigationController: navigationController,
                                                              permissionChecker: MockCaptureDevicePermissionChecker(authorizationStatus: .authorized),
                                                              onBarcodeScanned: { _ in })

        // When
        coordinator.start()

        // Then
        assertThat(navigationController.presentedViewController, isAnInstanceOf: ScannerContainerViewController.self)
    }

    func test_coordinator_shows_alert_when_permission_is_denied() {
        // Given
        let coordinator = ProducBarcodeScannerCoordinator(sourceNavigationController: navigationController,
                                                              permissionChecker: MockCaptureDevicePermissionChecker(authorizationStatus: .denied),
                                                              onBarcodeScanned: { _ in })

        // When
        coordinator.start()

        // Then
        assertThat(navigationController.presentedViewController, isAnInstanceOf: UIAlertController.self)
        XCTAssertNil(navigationController.topViewController)
    }

    func test_coordinator_shows_alert_when_permission_is_restricted() {
        // Given
        let coordinator = ProducBarcodeScannerCoordinator(sourceNavigationController: navigationController,
                                                              permissionChecker: MockCaptureDevicePermissionChecker(authorizationStatus: .restricted),
                                                              onBarcodeScanned: { _ in })

        // When
        coordinator.start()

        // Then
        assertThat(navigationController.presentedViewController, isAnInstanceOf: UIAlertController.self)
        XCTAssertNil(navigationController.topViewController)
    }

    // MARK: - Failure reason reporting

    func test_coordinator_when_permission_is_denied_then_reports_camera_access_not_permitted() {
        // Given
        var reportedReasons: [ProducBarcodeScannerCoordinator.FailureReason] = []
        let coordinator = ProducBarcodeScannerCoordinator(sourceNavigationController: navigationController,
                                                          permissionChecker: MockCaptureDevicePermissionChecker(authorizationStatus: .denied),
                                                          onBarcodeScanned: { _ in },
                                                          onPermissionsDenied: { reportedReasons.append($0) })

        // When
        coordinator.start()

        // Then
        XCTAssertEqual(reportedReasons, [.cameraAccessNotPermitted])
    }

    func test_coordinator_when_permission_is_restricted_then_reports_camera_access_restricted() {
        // Given
        var reportedReasons: [ProducBarcodeScannerCoordinator.FailureReason] = []
        let coordinator = ProducBarcodeScannerCoordinator(sourceNavigationController: navigationController,
                                                          permissionChecker: MockCaptureDevicePermissionChecker(authorizationStatus: .restricted),
                                                          onBarcodeScanned: { _ in },
                                                          onPermissionsDenied: { reportedReasons.append($0) })

        // When
        coordinator.start()

        // Then
        XCTAssertEqual(reportedReasons, [.cameraAccessRestricted])
    }

    func test_coordinator_when_access_is_refused_at_the_prompt_then_reports_denied_at_prompt() {
        // Given
        let permissionChecker = MockCaptureDevicePermissionChecker(authorizationStatus: .notDetermined)
        permissionChecker.whenRequestingAccess(thenReturn: false)
        var reportedReasons: [ProducBarcodeScannerCoordinator.FailureReason] = []
        let coordinator = ProducBarcodeScannerCoordinator(sourceNavigationController: navigationController,
                                                          permissionChecker: permissionChecker,
                                                          onBarcodeScanned: { _ in },
                                                          onPermissionsDenied: { reportedReasons.append($0) })

        // When
        coordinator.start()

        // Then
        XCTAssertEqual(reportedReasons, [.cameraAccessDeniedAtPrompt])
    }

    func test_coordinator_when_access_is_granted_at_the_prompt_then_reports_no_failure() {
        // Given
        let permissionChecker = MockCaptureDevicePermissionChecker(authorizationStatus: .notDetermined)
        permissionChecker.whenRequestingAccess(thenReturn: true)
        var reportedReasons: [ProducBarcodeScannerCoordinator.FailureReason] = []
        let coordinator = ProducBarcodeScannerCoordinator(sourceNavigationController: navigationController,
                                                          permissionChecker: permissionChecker,
                                                          onBarcodeScanned: { _ in },
                                                          onPermissionsDenied: { reportedReasons.append($0) })

        // When
        coordinator.start()

        // Then
        XCTAssertTrue(reportedReasons.isEmpty)
    }

    func test_coordinator_when_permission_is_authorized_then_reports_no_failure() {
        // Given
        var reportedReasons: [ProducBarcodeScannerCoordinator.FailureReason] = []
        let coordinator = ProducBarcodeScannerCoordinator(sourceNavigationController: navigationController,
                                                          permissionChecker: MockCaptureDevicePermissionChecker(authorizationStatus: .authorized),
                                                          onBarcodeScanned: { _ in },
                                                          onPermissionsDenied: { reportedReasons.append($0) })

        // When
        coordinator.start()

        // Then
        XCTAssertTrue(reportedReasons.isEmpty)
    }
}
