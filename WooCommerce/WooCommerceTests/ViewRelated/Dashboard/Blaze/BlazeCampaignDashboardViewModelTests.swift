import Foundation
import XCTest
import Yosemite

@testable import WooCommerce

/// Test cases for `BlazeCampaignDashboardViewModel`.
///
final class BlazeCampaignDashboardViewModelTests: XCTestCase {
    private let sampleSiteID: Int64 = 122
    private var stores: MockStoresManager!
    private var storageManager: MockStorageManager!

    override func setUp() {
        super.setUp()
        stores = MockStoresManager(sessionManager: .testingInstance)
        storageManager = MockStorageManager()
    }

    override func tearDown() {
        storageManager = nil
        stores = nil
        super.tearDown()
    }

    // MARK: `shouldShowInDashboard`

    func test_shouldShowInDashboard_is_true_by_default() async {
        // Given
        let checker = MockBlazeEligibilityChecker(isSiteEligible: true)
        storageManager.insertSampleProduct(readOnlyProduct: .fake().copy(siteID: sampleSiteID,
                                                                         statusKey: (ProductStatus.published.rawValue)))

        let sut = BlazeCampaignDashboardViewModel(siteID: sampleSiteID,
                                                  stores: stores,
                                                  storageManager: storageManager,
                                                  blazeEligibilityChecker: checker)

        // Then
        XCTAssertTrue(sut.shouldShowInDashboard)
    }

    // MARK: Blaze eligibility

    func test_it_shows_in_dashboard_if_eligible_for_blaze() async {
        // Given
        let checker = MockBlazeEligibilityChecker(isSiteEligible: true)
        storageManager.insertSampleProduct(readOnlyProduct: .fake().copy(siteID: sampleSiteID,
                                                                         statusKey: (ProductStatus.published.rawValue)))

        let sut = BlazeCampaignDashboardViewModel(siteID: sampleSiteID,
                                                  stores: stores,
                                                  storageManager: storageManager,
                                                  blazeEligibilityChecker: checker)

        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case .checkIfStoreHasProducts(_, _, let onCompletion):
                onCompletion(.success(true))
            default:
                break
            }
        }

        stores.whenReceivingAction(ofType: BlazeAction.self) { action in
            switch action {
            case .synchronizeCampaigns(_, _, let onCompletion):
                onCompletion(.success(false))
            }
        }

        // When
        await sut.reload()

        // Then
        XCTAssertTrue(sut.shouldShowInDashboard)
    }

    func test_it_hides_from_dashboard_if_not_eligible_for_blaze() async {
        // Given
        let checker = MockBlazeEligibilityChecker(isSiteEligible: false)
        storageManager.insertSampleProduct(readOnlyProduct: .fake().copy(siteID: sampleSiteID,
                                                                         statusKey: (ProductStatus.published.rawValue)))

        let sut = BlazeCampaignDashboardViewModel(siteID: sampleSiteID,
                                                  stores: stores,
                                                  storageManager: storageManager,
                                                  blazeEligibilityChecker: checker)

        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case .checkIfStoreHasProducts(_, _, let onCompletion):
                onCompletion(.success(true))
            default:
                break
            }
        }

        stores.whenReceivingAction(ofType: BlazeAction.self) { action in
            switch action {
            case .synchronizeCampaigns(_, _, let onCompletion):
                onCompletion(.success(false))
            }
        }

        // When
        await sut.reload()

        // Then
        XCTAssertFalse(sut.shouldShowInDashboard)
    }

    // MARK: Blaze campaigns

    func test_it_shows_in_dashboard_if_blaze_campaign_available() async {
        // Given
        let checker = MockBlazeEligibilityChecker(isSiteEligible: true)
        storageManager.insertSampleProduct(readOnlyProduct: .fake().copy(siteID: sampleSiteID,
                                                                         statusKey: (ProductStatus.published.rawValue)))

        let blazeCampaign = storageManager.viewStorage.insertNewObject(ofType: StorageBlazeCampaign.self)
        blazeCampaign.update(with: BlazeCampaign.fake().copy(siteID: sampleSiteID))

        let sut = BlazeCampaignDashboardViewModel(siteID: sampleSiteID,
                                                  stores: stores,
                                                  storageManager: storageManager,
                                                  blazeEligibilityChecker: checker)

        stores.whenReceivingAction(ofType: BlazeAction.self) { action in
            switch action {
            case .synchronizeCampaigns(_, _, let onCompletion):
                onCompletion(.success(false))
            }
        }

        // When
        await sut.reload()

        // Then
        XCTAssertTrue(sut.shouldShowInDashboard)
    }

    func test_it_hides_from_dashboard_if_blaze_campaign_not_available() async {
        // Given
        let checker = MockBlazeEligibilityChecker(isSiteEligible: true)
        let sut = BlazeCampaignDashboardViewModel(siteID: sampleSiteID,
                                                  stores: stores,
                                                  storageManager: storageManager,
                                                  blazeEligibilityChecker: checker)

        // When
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case .checkIfStoreHasProducts(_, _, let onCompletion):
                onCompletion(.success(true))
            default:
                break
            }
        }

        stores.whenReceivingAction(ofType: BlazeAction.self) { action in
            switch action {
            case .synchronizeCampaigns(_, _, let onCompletion):
                onCompletion(.success(false))
            }
        }

        // When
        await sut.reload()

        // Then
        XCTAssertFalse(sut.shouldShowInDashboard)
    }

    // MARK: Published product

    func test_it_shows_in_dashboard_if_published_product_available() async {
        // Given
        let checker = MockBlazeEligibilityChecker(isSiteEligible: true)
        storageManager.insertSampleProduct(readOnlyProduct: .fake().copy(siteID: sampleSiteID,
                                                                         statusKey: (ProductStatus.published.rawValue)))

        let sut = BlazeCampaignDashboardViewModel(siteID: sampleSiteID,
                                                  stores: stores,
                                                  storageManager: storageManager,
                                                  blazeEligibilityChecker: checker)

        stores.whenReceivingAction(ofType: BlazeAction.self) { action in
            switch action {
            case .synchronizeCampaigns(_, _, let onCompletion):
                onCompletion(.success(false))
            }
        }

        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case .checkIfStoreHasProducts(_, _, let onCompletion):
                onCompletion(.success(true))
            default:
                break
            }
        }

        // When
        await sut.reload()

        // Then
        XCTAssertTrue(sut.shouldShowInDashboard)
    }

    func test_it_hides_from_dashboard_if_published_product_not_available() async {
        // Given
        let checker = MockBlazeEligibilityChecker(isSiteEligible: true)

        let sut = BlazeCampaignDashboardViewModel(siteID: sampleSiteID,
                                                  stores: stores,
                                                  storageManager: storageManager,
                                                  blazeEligibilityChecker: checker)

        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case .checkIfStoreHasProducts(_, _, let onCompletion):
                onCompletion(.success(true))
            default:
                break
            }
        }

        stores.whenReceivingAction(ofType: BlazeAction.self) { action in
            switch action {
            case .synchronizeCampaigns(_, _, let onCompletion):
                onCompletion(.success(false))
            }
        }

        // When
        await sut.reload()

        // Then
        XCTAssertFalse(sut.shouldShowInDashboard)
    }

    func test_it_shows_latest_published_in_dashboard() async {
        // Given
        let checker = MockBlazeEligibilityChecker(isSiteEligible: true)
        let product1: Product = .fake().copy(siteID: sampleSiteID,
                                             statusKey: (ProductStatus.published.rawValue))
        storageManager.insertSampleProduct(readOnlyProduct: product1)

        let product2: Product = .fake().copy(siteID: sampleSiteID,
                                             statusKey: (ProductStatus.published.rawValue))
        storageManager.insertSampleProduct(readOnlyProduct: product2)

        let sut = BlazeCampaignDashboardViewModel(siteID: sampleSiteID,
                                                  stores: stores,
                                                  storageManager: storageManager,
                                                  blazeEligibilityChecker: checker)

        stores.whenReceivingAction(ofType: BlazeAction.self) { action in
            switch action {
            case .synchronizeCampaigns(_, _, let onCompletion):
                onCompletion(.success(false))
            }
        }

        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case .checkIfStoreHasProducts(_, _, let onCompletion):
                onCompletion(.success(true))
            default:
                break
            }
        }

        // When
        await sut.reload()

        // Then
        if case .showProduct(let product) = sut.state {
            XCTAssertEqual(product, product2)
        } else {
            XCTFail("Wrong state")
        }
    }

    // MARK: `state`

    func test_state_is_loading_while_reloading() async {
        // Given
        let checker = MockBlazeEligibilityChecker(isSiteEligible: true)
        let fakeBlazeCampaign = BlazeCampaign.fake().copy(siteID: sampleSiteID)
        let storageBlazeCampaign = storageManager.viewStorage.insertNewObject(ofType: StorageBlazeCampaign.self)
        storageBlazeCampaign.update(with: fakeBlazeCampaign)

        let sut = BlazeCampaignDashboardViewModel(siteID: sampleSiteID,
                                                  stores: stores,
                                                  storageManager: storageManager,
                                                  blazeEligibilityChecker: checker)

        stores.whenReceivingAction(ofType: BlazeAction.self) { action in
            switch action {
            case .synchronizeCampaigns(_, _, let onCompletion):
                // Then
                if case .loading = sut.state {
                    // Loading state as expected
                } else {
                    XCTFail("Wrong state")
                }
                onCompletion(.success(false))
            }
        }

        // When
        await sut.reload()
    }

    func test_state_is_showCampaign_if_blaze_campaign_available() async {
        // Given
        let checker = MockBlazeEligibilityChecker(isSiteEligible: true)
        let fakeBlazeCampaign = BlazeCampaign.fake().copy(siteID: sampleSiteID)
        let storageBlazeCampaign = storageManager.viewStorage.insertNewObject(ofType: StorageBlazeCampaign.self)
        storageBlazeCampaign.update(with: fakeBlazeCampaign)

        let sut = BlazeCampaignDashboardViewModel(siteID: sampleSiteID,
                                                  stores: stores,
                                                  storageManager: storageManager,
                                                  blazeEligibilityChecker: checker)

        stores.whenReceivingAction(ofType: BlazeAction.self) { action in
            switch action {
            case .synchronizeCampaigns(_, _, let onCompletion):
                onCompletion(.success(false))
            }
        }

        // When
        await sut.reload()

        // Then
        if case .showCampaign(let campaign) = sut.state {
            XCTAssertEqual(campaign, fakeBlazeCampaign)
        } else {
            XCTFail("Wrong state")
        }
    }

    func test_state_is_showProduct_if_published_product_available() async {
        // Given
        let checker = MockBlazeEligibilityChecker(isSiteEligible: true)
        let fakeProduct = Product.fake().copy(siteID: sampleSiteID,
                                              statusKey: (ProductStatus.published.rawValue))
        storageManager.insertSampleProduct(readOnlyProduct: fakeProduct)

        let sut = BlazeCampaignDashboardViewModel(siteID: sampleSiteID,
                                                  stores: stores,
                                                  storageManager: storageManager,
                                                  blazeEligibilityChecker: checker)

        stores.whenReceivingAction(ofType: BlazeAction.self) { action in
            switch action {
            case .synchronizeCampaigns(_, _, let onCompletion):
                onCompletion(.success(false))
            }
        }

        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case .checkIfStoreHasProducts(_, _, let onCompletion):
                onCompletion(.success(true))
            default:
                break
            }
        }

        // When
        await sut.reload()

        // Then
        if case .showProduct(let product) = sut.state {
            XCTAssertEqual(product, fakeProduct)
        } else {
            XCTFail("Wrong state")
        }
    }

    func test_state_is_empty_if_no_data_available() async {
        // Given
        let checker = MockBlazeEligibilityChecker(isSiteEligible: true)
        let sut = BlazeCampaignDashboardViewModel(siteID: sampleSiteID,
                                                  stores: stores,
                                                  storageManager: storageManager,
                                                  blazeEligibilityChecker: checker)

        stores.whenReceivingAction(ofType: BlazeAction.self) { action in
            switch action {
            case .synchronizeCampaigns(_, _, let onCompletion):
                onCompletion(.success(false))
            }
        }

        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case .checkIfStoreHasProducts(_, _, let onCompletion):
                onCompletion(.success(true))
            default:
                break
            }
        }

        // When
        await sut.reload()

        // Then
        if case .empty = sut.state {
            // empty state as expected
        } else {
            XCTFail("Wrong state")
        }
    }

    // MARK: `shouldRedactView`

    func test_shouldRedactView_is_true_while_reloading() async {
        // Given
        let checker = MockBlazeEligibilityChecker(isSiteEligible: true)
        let fakeBlazeCampaign = BlazeCampaign.fake().copy(siteID: sampleSiteID)
        let storageBlazeCampaign = storageManager.viewStorage.insertNewObject(ofType: StorageBlazeCampaign.self)
        storageBlazeCampaign.update(with: fakeBlazeCampaign)

        let sut = BlazeCampaignDashboardViewModel(siteID: sampleSiteID,
                                                  stores: stores,
                                                  storageManager: storageManager,
                                                  blazeEligibilityChecker: checker)

        stores.whenReceivingAction(ofType: BlazeAction.self) { action in
            switch action {
            case .synchronizeCampaigns(_, _, let onCompletion):
                // Then
                XCTAssertTrue(sut.shouldRedactView)
                onCompletion(.success(false))
            }
        }

        // When
        await sut.reload()
    }

    func test_shouldRedactView_is_false_after_reload_finishes_when_blaze_campaign_available() async {
        // Given
        let checker = MockBlazeEligibilityChecker(isSiteEligible: true)
        let fakeBlazeCampaign = BlazeCampaign.fake().copy(siteID: sampleSiteID)
        let storageBlazeCampaign = storageManager.viewStorage.insertNewObject(ofType: StorageBlazeCampaign.self)
        storageBlazeCampaign.update(with: fakeBlazeCampaign)

        let sut = BlazeCampaignDashboardViewModel(siteID: sampleSiteID,
                                                  stores: stores,
                                                  storageManager: storageManager,
                                                  blazeEligibilityChecker: checker)

        stores.whenReceivingAction(ofType: BlazeAction.self) { action in
            switch action {
            case .synchronizeCampaigns(_, _, let onCompletion):
                onCompletion(.success(false))
            }
        }

        // When
        await sut.reload()

        // Then
        XCTAssertFalse(sut.shouldRedactView)
    }

    func test_shouldRedactView_is_false_after_reload_finishes_when_product_available() async {
        // Given
        let checker = MockBlazeEligibilityChecker(isSiteEligible: true)
        let fakeProduct = Product.fake().copy(siteID: sampleSiteID,
                                              statusKey: (ProductStatus.published.rawValue))
        storageManager.insertSampleProduct(readOnlyProduct: fakeProduct)

        let sut = BlazeCampaignDashboardViewModel(siteID: sampleSiteID,
                                                  stores: stores,
                                                  storageManager: storageManager,
                                                  blazeEligibilityChecker: checker)

        stores.whenReceivingAction(ofType: BlazeAction.self) { action in
            switch action {
            case .synchronizeCampaigns(_, _, let onCompletion):
                onCompletion(.success(false))
            }
        }

        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case .checkIfStoreHasProducts(_, _, let onCompletion):
                onCompletion(.success(true))
            default:
                break
            }
        }

        // When
        await sut.reload()

        // Then
        XCTAssertFalse(sut.shouldRedactView)
    }

    func test_shouldRedactView_is_true_after_reload_finishes_with_no_data() async {
        // Given
        let checker = MockBlazeEligibilityChecker(isSiteEligible: true)
        let sut = BlazeCampaignDashboardViewModel(siteID: sampleSiteID,
                                                  stores: stores,
                                                  storageManager: storageManager,
                                                  blazeEligibilityChecker: checker)

        stores.whenReceivingAction(ofType: BlazeAction.self) { action in
            switch action {
            case .synchronizeCampaigns(_, _, let onCompletion):
                onCompletion(.success(false))
            }
        }

        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case .checkIfStoreHasProducts(_, _, let onCompletion):
                onCompletion(.success(true))
            default:
                break
            }
        }

        // When
        await sut.reload()

        // Then
        XCTAssertTrue(sut.shouldRedactView)
    }

    // MARK: `shouldShowShowAllCampaignsButton`

    func test_shouldShowShowAllCampaignsButton_is_false_while_reloading() async {
        // Given
        let checker = MockBlazeEligibilityChecker(isSiteEligible: true)
        let fakeBlazeCampaign = BlazeCampaign.fake().copy(siteID: sampleSiteID)
        let storageBlazeCampaign = storageManager.viewStorage.insertNewObject(ofType: StorageBlazeCampaign.self)
        storageBlazeCampaign.update(with: fakeBlazeCampaign)

        let sut = BlazeCampaignDashboardViewModel(siteID: sampleSiteID,
                                                  stores: stores,
                                                  storageManager: storageManager,
                                                  blazeEligibilityChecker: checker)

        stores.whenReceivingAction(ofType: BlazeAction.self) { action in
            switch action {
            case .synchronizeCampaigns(_, _, let onCompletion):
                // Then
                XCTAssertFalse(sut.shouldShowShowAllCampaignsButton)
                onCompletion(.success(false))
            }
        }

        // When
        await sut.reload()
    }

    func test_shouldShowShowAllCampaignsButton_is_true_after_reload_finishes_when_blaze_campaign_available() async {
        // Given
        let checker = MockBlazeEligibilityChecker(isSiteEligible: true)
        let fakeBlazeCampaign = BlazeCampaign.fake().copy(siteID: sampleSiteID)
        let storageBlazeCampaign = storageManager.viewStorage.insertNewObject(ofType: StorageBlazeCampaign.self)
        storageBlazeCampaign.update(with: fakeBlazeCampaign)

        let sut = BlazeCampaignDashboardViewModel(siteID: sampleSiteID,
                                                  stores: stores,
                                                  storageManager: storageManager,
                                                  blazeEligibilityChecker: checker)

        stores.whenReceivingAction(ofType: BlazeAction.self) { action in
            switch action {
            case .synchronizeCampaigns(_, _, let onCompletion):
                onCompletion(.success(false))
            }
        }

        // When
        await sut.reload()

        // Then
        XCTAssertTrue(sut.shouldShowShowAllCampaignsButton)
    }

    func test_shouldShowShowAllCampaignsButton_is_false_after_reload_finishes_when_product_available() async {
        // Given
        let checker = MockBlazeEligibilityChecker(isSiteEligible: true)
        let fakeProduct = Product.fake().copy(siteID: sampleSiteID,
                                              statusKey: (ProductStatus.published.rawValue))
        storageManager.insertSampleProduct(readOnlyProduct: fakeProduct)

        let sut = BlazeCampaignDashboardViewModel(siteID: sampleSiteID,
                                                  stores: stores,
                                                  storageManager: storageManager,
                                                  blazeEligibilityChecker: checker)

        stores.whenReceivingAction(ofType: BlazeAction.self) { action in
            switch action {
            case .synchronizeCampaigns(_, _, let onCompletion):
                onCompletion(.success(false))
            }
        }

        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case .checkIfStoreHasProducts(_, _, let onCompletion):
                onCompletion(.success(true))
            default:
                break
            }
        }

        // When
        await sut.reload()

        // Then
        XCTAssertFalse(sut.shouldShowShowAllCampaignsButton)
    }

    func test_shouldShowShowAllCampaignsButton_is_false_after_reload_finishes_with_no_data() async {
        // Given
        let checker = MockBlazeEligibilityChecker(isSiteEligible: true)
        let sut = BlazeCampaignDashboardViewModel(siteID: sampleSiteID,
                                                  stores: stores,
                                                  storageManager: storageManager,
                                                  blazeEligibilityChecker: checker)

        stores.whenReceivingAction(ofType: BlazeAction.self) { action in
            switch action {
            case .synchronizeCampaigns(_, _, let onCompletion):
                onCompletion(.success(false))
            }
        }

        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case .checkIfStoreHasProducts(_, _, let onCompletion):
                onCompletion(.success(true))
            default:
                break
            }
        }

        // When
        await sut.reload()

        // Then
        XCTAssertFalse(sut.shouldShowShowAllCampaignsButton)
    }
}
