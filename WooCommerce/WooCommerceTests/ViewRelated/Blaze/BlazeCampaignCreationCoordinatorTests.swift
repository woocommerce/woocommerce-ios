import XCTest
import Yosemite
import protocol Storage.StorageManagerType
import protocol Storage.StorageType
@testable import WooCommerce

final class BlazeCampaignCreationCoordinatorTests: XCTestCase {
    /// Mock Storage: InMemory
    private var storageManager: StorageManagerType!

    /// View storage for tests
    private var storage: StorageType {
        storageManager.viewStorage
    }

    private var navigationController: UINavigationController!

    override func setUp() {
        super.setUp()
        storageManager = MockStorageManager()

        navigationController = UINavigationController()
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = UIViewController()
        window.makeKeyAndVisible()
        window.rootViewController = navigationController
     }

     override func tearDown() {
         super.tearDown()
         navigationController = nil
     }

    func test_webview_is_presented_when_blazei3NativeCampaignCreation_is_disabled() {
        // Given
        let featureFlagService = MockFeatureFlagService(blazei3NativeCampaignCreation: false)
        let sut = BlazeCampaignCreationCoordinator(siteID: 1,
                                                   siteURL: "https://woo.com/",
                                                   source: .campaignList,
                                                   featureFlagService: featureFlagService,
                                                   navigationController: navigationController,
                                                   onCampaignCreated: { }
        )

        // When
        sut.start()

        // Then
        XCTAssertTrue(sut.navigationController.viewControllers.first is AuthenticatedWebViewController)
    }

    func test_given_enabled_i3_featureflag_when_product_id_supplied_then_navigate_to_creation_form() {
        // Given
        let featureFlagService = MockFeatureFlagService(blazei3NativeCampaignCreation: true)
        let sut = BlazeCampaignCreationCoordinator(siteID: 1,
                                                   siteURL: "https://woo.com/",
                                                   productID: 2,
                                                   source: .campaignList,
                                                   featureFlagService: featureFlagService,
                                                   navigationController: navigationController,
                                                   onCampaignCreated: { }
        )

        // When
        sut.start()

        // Then
        XCTAssertTrue(sut.navigationController.viewControllers.first is BlazeCampaignCreationFormHostingController)
    }

    func test_given_enabled_i3_featureflag_when_no_product_id_supplied_and_there_is_one_eligible_product_then_navigate_to_creation_form() {
        // Given
        let featureFlagService = MockFeatureFlagService(blazei3NativeCampaignCreation: true)
        insertProduct(.fake().copy(siteID: 1,
                                   productID: 1,
                                   statusKey: (ProductStatus.published.rawValue),
                                   purchasable: true))

        let sut = BlazeCampaignCreationCoordinator(siteID: 1,
                                                   siteURL: "https://woo.com/",
                                                   source: .campaignList,
                                                   storageManager: storageManager,
                                                   featureFlagService: featureFlagService,
                                                   navigationController: navigationController,
                                                   onCampaignCreated: { }
        )
        // When
        sut.start()

        // Then
        XCTAssertTrue(sut.navigationController.viewControllers.first is BlazeCampaignCreationFormHostingController)
    }

    func test_given_enabled_i3_featureflag_when_no_product_id_supplied_and_there_are_multiple_eligible_products_then_navigate_to_product_selector() throws {
        // Given
        let featureFlagService = MockFeatureFlagService(blazei3NativeCampaignCreation: true)
        insertProduct(.fake().copy(siteID: 1,
                                   productID: 1,
                                   statusKey: (ProductStatus.published.rawValue)))

        insertProduct(.fake().copy(siteID: 1,
                                   productID: 2,
                                   statusKey: (ProductStatus.published.rawValue)))

        let sut = BlazeCampaignCreationCoordinator(siteID: 1,
                                                   siteURL: "https://woo.com/",
                                                   source: .campaignList,
                                                   storageManager: storageManager,
                                                   featureFlagService: featureFlagService,
                                                   navigationController: navigationController,
                                                   onCampaignCreated: { }
        )

        // When
        sut.start()

        // Then
        // The Product Selector is shown using a WooNavigationController
        // The Product Selector is the first view controller in the presented WooNavigationController
        let presentedNavigationController = try XCTUnwrap(sut.navigationController.presentedViewController as? WooNavigationController)
        let viewController = try XCTUnwrap(presentedNavigationController.viewControllers.first)
        XCTAssertTrue(viewController is ProductSelectorViewController)
    }
}

private extension BlazeCampaignCreationCoordinatorTests {
    /// Insert a `Product` into storage.
    ///
    func insertProduct(_ readOnlyProduct: Product) {
        let product = storage.insertNewObject(ofType: StorageProduct.self)
        product.update(with: readOnlyProduct)
        storage.saveIfNeeded()
    }
}
