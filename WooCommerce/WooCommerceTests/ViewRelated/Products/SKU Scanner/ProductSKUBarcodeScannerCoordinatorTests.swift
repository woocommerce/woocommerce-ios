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
        let coordinator = ProductSKUBarcodeScannerCoordinator(sourceNavigationController: navigationController,
                                                              permissionChecker: permissionChecker,
                                                              onSKUBarcodeScanned: { _ in })

        // When
        coordinator.start()

        // Then
        assertThat(navigationController.topViewController, isAnInstanceOf: ProductSKUInputScannerViewController.self)
    }

    func test_coordinator_does_nothing_after_denying_camera_access() {
        // Given
        let permissionChecker = MockCaptureDevicePermissionChecker(authorizationStatus: .notDetermined)
        // Denies access.
        permissionChecker.whenRequestingAccess(thenReturn: false)
        let coordinator = ProductSKUBarcodeScannerCoordinator(sourceNavigationController: navigationController,
                                                              permissionChecker: permissionChecker,
                                                              onSKUBarcodeScanned: { _ in })

        // When
        coordinator.start()

        // Then
        XCTAssertNil(navigationController.topViewController)
        XCTAssertNil(navigationController.presentedViewController)
    }

    func test_coordinator_shows_sku_scanner_when_permission_is_authorized() {
        // Given
        let coordinator = ProductSKUBarcodeScannerCoordinator(sourceNavigationController: navigationController,
                                                              permissionChecker: MockCaptureDevicePermissionChecker(authorizationStatus: .authorized),
                                                              onSKUBarcodeScanned: { _ in })

        // When
        coordinator.start()

        // Then
        assertThat(navigationController.topViewController, isAnInstanceOf: ProductSKUInputScannerViewController.self)
    }

    func test_coordinator_shows_alert_when_permission_is_denied() {
        // Given
        let coordinator = ProductSKUBarcodeScannerCoordinator(sourceNavigationController: navigationController,
                                                              permissionChecker: MockCaptureDevicePermissionChecker(authorizationStatus: .denied),
                                                              onSKUBarcodeScanned: { _ in })

        // When
        coordinator.start()

        // Then
        assertThat(navigationController.presentedViewController, isAnInstanceOf: UIAlertController.self)
        XCTAssertNil(navigationController.topViewController)
    }

    func test_coordinator_shows_alert_when_permission_is_restricted() {
        // Given
        let coordinator = ProductSKUBarcodeScannerCoordinator(sourceNavigationController: navigationController,
                                                              permissionChecker: MockCaptureDevicePermissionChecker(authorizationStatus: .restricted),
                                                              onSKUBarcodeScanned: { _ in })

        // When
        coordinator.start()

        // Then
        assertThat(navigationController.presentedViewController, isAnInstanceOf: UIAlertController.self)
        XCTAssertNil(navigationController.topViewController)
    }
}
