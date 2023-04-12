import TestKit
import WordPressAuthenticator
import XCTest
import struct Yosemite.Site
@testable import WooCommerce

final class StorePickerCoordinatorTests: XCTestCase {
    private var navigationController: UINavigationController!
    private let window = UIWindow(frame: UIScreen.main.bounds)

    override func setUp() {
        super.setUp()

        window.makeKeyAndVisible()
        navigationController = .init()
        window.rootViewController = navigationController

        WordPressAuthenticator.initializeAuthenticator()
    }

    override func tearDown() {
        navigationController = nil
        window.resignKey()
        window.rootViewController = nil

        super.tearDown()
    }

    func test_storeCreationFromLogin_configuration_shows_storePicker() throws {
        // Given
        let coordinator = StorePickerCoordinator(navigationController, config: .storeCreationFromLogin(source: .prologue))

        // When
        coordinator.start()

        // Then
        waitUntil {
            self.navigationController.topViewController is StorePickerViewController
        }
    }

    func test_standard_configuration_presents_storePicker() throws {
        // Given
        let coordinator = StorePickerCoordinator(navigationController, config: .standard)

        // When
        coordinator.start()

        // Then
        waitUntil {
            self.navigationController.presentedViewController is WooNavigationController
        }
        XCTAssertNil(navigationController.topViewController)

        let storePickerNavigationController = try XCTUnwrap(navigationController.presentedViewController as? UINavigationController)
        assertThat(storePickerNavigationController.topViewController, isAnInstanceOf: StorePickerViewController.self)
    }

    func test_switchingStores_configuration_presents_storePicker() throws {
        // Given
        let coordinator = StorePickerCoordinator(navigationController, config: .switchingStores)

        // When
        coordinator.start()

        // Then
        waitUntil {
            self.navigationController.presentedViewController is WooNavigationController
        }
        XCTAssertNil(navigationController.topViewController)

        let storePickerNavigationController = try XCTUnwrap(navigationController.presentedViewController as? UINavigationController)
        assertThat(storePickerNavigationController.topViewController, isAnInstanceOf: StorePickerViewController.self)
    }

    func test_login_configuration_shows_storePicker() throws {
        // Given
        let coordinator = StorePickerCoordinator(navigationController, config: .login)

        // When
        coordinator.start()

        // Then
        waitUntil {
            self.navigationController.topViewController is StorePickerViewController
        }
    }

    func test_listStores_configuration_shows_storePicker() throws {
        // Given
        let coordinator = StorePickerCoordinator(navigationController, config: .listStores)

        // When
        coordinator.start()

        // Then
        waitUntil {
            self.navigationController.topViewController is StorePickerViewController
        }
    }

    // MARK: switchStoreIfOnlyOneStoreIsAvailable

    func test_it_throws_noStoresAvailable_when_there_are_no_stores_with_active_woocommerce() async throws {
        // Given
        let switchStoreUseCase = MockSwitchStoreUseCase()
        switchStoreUseCase.availableStores = [Site.fake().copy(isWooCommerceActive: false)]
        let coordinator = StorePickerCoordinator(navigationController,
                                                 config: .listStores,
                                                 switchStoreUseCase: switchStoreUseCase)

        do {
            // When
            try await coordinator.switchStoreIfOnlyOneStoreIsAvailable()
        } catch {
            guard let dotcomError = error as? StorePickerCoordinator.StoreSelectionError else {
                return XCTFail()
            }

            // Then
            XCTAssertEqual(dotcomError, .noStoresAvailable)
        }
    }

    func test_it_throws_moreThanOneStoreAvailable_when_there_are_many_stores_with_active_woocommerce() async throws {
        // Given
        let switchStoreUseCase = MockSwitchStoreUseCase()
        switchStoreUseCase.availableStores = [Site.fake().copy(isWooCommerceActive: true),
                                              Site.fake().copy(isWooCommerceActive: true),
                                              Site.fake().copy(isWooCommerceActive: false)]
        let coordinator = StorePickerCoordinator(navigationController,
                                                 config: .listStores,
                                                 switchStoreUseCase: switchStoreUseCase)

        do {
            // When
            try await coordinator.switchStoreIfOnlyOneStoreIsAvailable()
        } catch {
            guard let dotcomError = error as? StorePickerCoordinator.StoreSelectionError else {
                return XCTFail()
            }

            // Then
            XCTAssertEqual(dotcomError, .moreThanOneStoreAvailable)
        }
    }

    func test_it_does_not_throw_error_when_there_is_only_one_store_with_active_woocommerce() async throws {
        // Given
        let switchStoreUseCase = MockSwitchStoreUseCase()
        switchStoreUseCase.availableStores = [Site.fake().copy(isWooCommerceActive: true)]
        let coordinator = StorePickerCoordinator(navigationController,
                                                 config: .listStores,
                                                 switchStoreUseCase: switchStoreUseCase)

        do {
            // When
            try await coordinator.switchStoreIfOnlyOneStoreIsAvailable()
        } catch {
            XCTFail("Should not throw an error")
        }
    }

    func test_it_switches_store_when_there_is_only_one_store_with_active_woocommerce() async throws {
        // Given
        let switchStoreUseCase = MockSwitchStoreUseCase()
        let site = Site.fake().copy(isWooCommerceActive: true)
        switchStoreUseCase.availableStores = [site]
        let coordinator = StorePickerCoordinator(navigationController,
                                                 config: .listStores,
                                                 switchStoreUseCase: switchStoreUseCase)

        // When
        try await coordinator.switchStoreIfOnlyOneStoreIsAvailable()

        // Then
        XCTAssertEqual(switchStoreUseCase.destinationStoreIDs, [site.siteID])
    }
}
