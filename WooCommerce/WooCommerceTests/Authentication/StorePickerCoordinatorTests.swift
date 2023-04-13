import TestKit
import WordPressAuthenticator
import XCTest
import Yosemite
@testable import WooCommerce

@MainActor
final class StorePickerCoordinatorTests: XCTestCase {
    private var navigationController: UINavigationController!
    private let window = UIWindow(frame: UIScreen.main.bounds)
    private var storageManager: MockStorageManager!

    override func setUp() {
        super.setUp()

        window.makeKeyAndVisible()
        navigationController = .init()
        window.rootViewController = navigationController
        storageManager = MockStorageManager()

        WordPressAuthenticator.initializeAuthenticator()
    }

    override func tearDown() {
        storageManager = nil
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

    func test_switchStoreIfOnlyOneStoreIsAvailable_retuns_false_noStoresAvailable_when_there_are_no_stores_with_active_woocommerce() async {
        // Given
        storageManager.insertSampleSite(readOnlySite: Site.fake().copy(isWooCommerceActive: false))
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let coordinator = StorePickerCoordinator(navigationController,
                                                 config: .listStores,
                                                 stores: stores,
                                                 storageManager: storageManager)
        stores.whenReceivingAction(ofType: AccountAction.self) { action in
            switch action {
            case let .synchronizeSites(_, onCompletion):
                onCompletion(.success(false))
            default:
                break
            }
        }

        // When
        let isSwitchStoreSuccess = await coordinator.switchStoreIfOnlyOneStoreIsAvailable()

        // Then
        XCTAssertFalse(isSwitchStoreSuccess)
    }

    func test_switchStoreIfOnlyOneStoreIsAvailable_retuns_false_moreThanOneStoreAvailable_when_there_are_many_stores_with_active_woocommerce() async {
        // Given
        storageManager.insertSampleSite(readOnlySite: Site.fake().copy(isWooCommerceActive: true))
        storageManager.insertSampleSite(readOnlySite: Site.fake().copy(isWooCommerceActive: true))
        storageManager.insertSampleSite(readOnlySite: Site.fake().copy(isWooCommerceActive: false))
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let coordinator = StorePickerCoordinator(navigationController,
                                                 config: .listStores,
                                                 stores: stores,
                                                 storageManager: storageManager)
        stores.whenReceivingAction(ofType: AccountAction.self) { action in
            switch action {
            case let .synchronizeSites(_, onCompletion):
                onCompletion(.success(false))
            default:
                break
            }
        }

        // When
        let isSwitchStoreSuccess = await coordinator.switchStoreIfOnlyOneStoreIsAvailable()

        // Then
        XCTAssertFalse(isSwitchStoreSuccess)
    }

    func test_switchStoreIfOnlyOneStoreIsAvailable_retuns_true_when_there_is_only_one_store_with_active_woocommerce() async {
        // Given
        storageManager.insertSampleSite(readOnlySite: Site.fake().copy(isWooCommerceActive: true))
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let coordinator = StorePickerCoordinator(navigationController,
                                                 config: .listStores,
                                                 stores: stores,
                                                 storageManager: storageManager)
        stores.whenReceivingAction(ofType: AccountAction.self) { action in
            switch action {
            case let .synchronizeSites(_, onCompletion):
                onCompletion(.success(false))
            default:
                break
            }
        }

        // When
        let isSwitchStoreSuccess = await coordinator.switchStoreIfOnlyOneStoreIsAvailable()

        // Then
        XCTAssertTrue(isSwitchStoreSuccess)
    }

    func test_it_switches_store_when_there_is_only_one_store_with_active_woocommerce() async {
        // Given
        let switchStoreUseCase = MockSwitchStoreUseCase()
        let site = Site.fake().copy(isWooCommerceActive: true)
        storageManager.insertSampleSite(readOnlySite: site)
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let coordinator = StorePickerCoordinator(navigationController,
                                                 config: .listStores,
                                                 stores: stores,
                                                 storageManager: storageManager,
                                                 switchStoreUseCase: switchStoreUseCase)
        stores.whenReceivingAction(ofType: AccountAction.self) { action in
            switch action {
            case let .synchronizeSites(_, onCompletion):
                onCompletion(.success(false))
            default:
                break
            }
        }

        // When
        _ = await coordinator.switchStoreIfOnlyOneStoreIsAvailable()

        // Then
        XCTAssertEqual(switchStoreUseCase.destinationStoreIDs, [site.siteID])
    }
}
