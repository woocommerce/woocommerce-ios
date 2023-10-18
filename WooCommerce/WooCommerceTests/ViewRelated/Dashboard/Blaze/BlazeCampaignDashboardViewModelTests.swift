import Foundation
import XCTest
import Yosemite
import protocol Storage.StorageType

@testable import WooCommerce

/// Test cases for `BlazeCampaignDashboardViewModel`.
///
final class BlazeCampaignDashboardViewModelTests: XCTestCase {
    private let sampleSiteID: Int64 = 122

    private var stores: MockStoresManager!

    /// Mock Storage: InMemory
    private var storageManager: MockStorageManager!

    /// View storage for tests
    private var storage: StorageType {
        storageManager.viewStorage
    }

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
        let sut = BlazeCampaignDashboardViewModel(siteID: sampleSiteID,
                                                  stores: stores,
                                                  storageManager: storageManager,
                                                  blazeEligibilityChecker: checker)

        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case .checkIfStoreHasProducts(_, _, let onCompletion):
                self.storageManager.insertSampleProduct(readOnlyProduct: .fake().copy(siteID: self.sampleSiteID,
                                                                                      statusKey: (ProductStatus.published.rawValue)))
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
        let sut = BlazeCampaignDashboardViewModel(siteID: sampleSiteID,
                                                  stores: stores,
                                                  storageManager: storageManager,
                                                  blazeEligibilityChecker: checker)

        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case .checkIfStoreHasProducts(_, _, let onCompletion):
                self.storageManager.insertSampleProduct(readOnlyProduct: .fake().copy(siteID: self.sampleSiteID,
                                                                                 statusKey: (ProductStatus.published.rawValue)))
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
        let blazeCampaign = BlazeCampaign.fake().copy(siteID: sampleSiteID)
        let sut = BlazeCampaignDashboardViewModel(siteID: sampleSiteID,
                                                  stores: stores,
                                                  storageManager: storageManager,
                                                  blazeEligibilityChecker: checker)

        stores.whenReceivingAction(ofType: BlazeAction.self) { action in
            switch action {
            case .synchronizeCampaigns(_, _, let onCompletion):
                self.insertCampaigns([blazeCampaign])
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
                self.storageManager.insertSampleProduct(readOnlyProduct: .fake().copy(siteID: self.sampleSiteID,
                                                                                 statusKey: (ProductStatus.published.rawValue)))
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

    func test_it_shows_latest_published_product_in_dashboard() async {
        // Given
        let checker = MockBlazeEligibilityChecker(isSiteEligible: true)
        let product1: Product = .fake().copy(siteID: sampleSiteID,
                                             statusKey: (ProductStatus.published.rawValue))
        storageManager.insertSampleProduct(readOnlyProduct: product1)

        let product2: Product = .fake().copy(siteID: sampleSiteID,
                                             statusKey: (ProductStatus.published.rawValue))

        let sut = BlazeCampaignDashboardViewModel(siteID: sampleSiteID,
                                                  stores: stores,
                                                  storageManager: storageManager,
                                                  blazeEligibilityChecker: checker)

        stores.whenReceivingAction(ofType: BlazeAction.self) { action in
            switch action {
            case .synchronizeCampaigns(_, _, let onCompletion):
                self.storageManager.insertSampleProduct(readOnlyProduct: product2)
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

        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case .checkIfStoreHasProducts(_, _, let onCompletion):
                // Then
                if case .loading = sut.state {
                    // Loading state as expected
                } else {
                    XCTFail("Wrong state")
                }
                onCompletion(.success(true))
            default:
                break
            }
        }

        // When
        await sut.reload()
    }

    func test_state_is_showCampaign_if_blaze_campaign_available() async {
        // Given
        let checker = MockBlazeEligibilityChecker(isSiteEligible: true)
        let fakeBlazeCampaign = BlazeCampaign.fake().copy(siteID: sampleSiteID)
        let sut = BlazeCampaignDashboardViewModel(siteID: sampleSiteID,
                                                  stores: stores,
                                                  storageManager: storageManager,
                                                  blazeEligibilityChecker: checker)

        stores.whenReceivingAction(ofType: BlazeAction.self) { action in
            switch action {
            case .synchronizeCampaigns(_, _, let onCompletion):
                self.insertCampaigns([fakeBlazeCampaign])
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

    func test_state_is_showProduct_if_published_product_available_and_blaze_campaign_not_available() async {
        // Given
        let checker = MockBlazeEligibilityChecker(isSiteEligible: true)
        let fakeProduct = Product.fake().copy(siteID: sampleSiteID,
                                              statusKey: (ProductStatus.published.rawValue))

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
                self.storageManager.insertSampleProduct(readOnlyProduct: fakeProduct)
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

    func test_state_is_empty_if_draft_product_available_and_blaze_campaign_not_available() async {
        // Given
        let checker = MockBlazeEligibilityChecker(isSiteEligible: true)
        let fakeProduct = Product.fake().copy(siteID: sampleSiteID,
                                              statusKey: (ProductStatus.draft.rawValue))

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
                self.storageManager.insertSampleProduct(readOnlyProduct: fakeProduct)
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

    func test_state_is_empty_if_no_blaze_campaign_no_product_available() async {
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

        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case .checkIfStoreHasProducts(_, _, let onCompletion):
                // Then
                XCTAssertTrue(sut.shouldRedactView)
                onCompletion(.success(true))
            default:
                break
            }
        }

        // When
        await sut.reload()
    }

    func test_shouldRedactView_is_false_after_reload_finishes_when_blaze_campaign_available() async {
        // Given
        let checker = MockBlazeEligibilityChecker(isSiteEligible: true)
        let fakeBlazeCampaign = BlazeCampaign.fake().copy(siteID: sampleSiteID)
        let sut = BlazeCampaignDashboardViewModel(siteID: sampleSiteID,
                                                  stores: stores,
                                                  storageManager: storageManager,
                                                  blazeEligibilityChecker: checker)

        stores.whenReceivingAction(ofType: BlazeAction.self) { action in
            switch action {
            case .synchronizeCampaigns(_, _, let onCompletion):
                self.insertCampaigns([fakeBlazeCampaign])
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
                self.storageManager.insertSampleProduct(readOnlyProduct: fakeProduct)
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

        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case .checkIfStoreHasProducts(_, _, let onCompletion):
                // Then
                XCTAssertFalse(sut.shouldShowShowAllCampaignsButton)
                onCompletion(.success(true))
            default:
                break
            }
        }

        // When
        await sut.reload()
    }

    func test_shouldShowShowAllCampaignsButton_is_true_after_reload_finishes_when_blaze_campaign_available() async {
        // Given
        let checker = MockBlazeEligibilityChecker(isSiteEligible: true)
        let fakeBlazeCampaign = BlazeCampaign.fake().copy(siteID: sampleSiteID)
        let sut = BlazeCampaignDashboardViewModel(siteID: sampleSiteID,
                                                  stores: stores,
                                                  storageManager: storageManager,
                                                  blazeEligibilityChecker: checker)

        stores.whenReceivingAction(ofType: BlazeAction.self) { action in
            switch action {
            case .synchronizeCampaigns(_, _, let onCompletion):
                self.insertCampaigns([fakeBlazeCampaign])
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
                self.storageManager.insertSampleProduct(readOnlyProduct: fakeProduct)
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

    // MARK: Reload from storage

    func test_reload_does_not_hit_product_remote_when_fetchFromRemote_is_false() async {
        // Given
        let checker = MockBlazeEligibilityChecker(isSiteEligible: true)
        let sut = BlazeCampaignDashboardViewModel(siteID: sampleSiteID,
                                                  stores: stores,
                                                  storageManager: storageManager,
                                                  blazeEligibilityChecker: checker)

        waitForExpectation { exp in
            exp.isInverted = true
            stores.whenReceivingAction(ofType: ProductAction.self) { action in
                switch action {
                case .checkIfStoreHasProducts:
                    exp.fulfill()
                default:
                    break
                }
            }
        }

        // When
        await sut.reload(fetchFromRemote: false)
    }

    func test_reload_hits_product_remote_by_default() async {
        // Given
        var invocationCountOfHasProducts = 0
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
                invocationCountOfHasProducts += 1
                onCompletion(.success(true))
            default:
                break
            }
        }

        // When
        await sut.reload()

        // Then
        XCTAssertEqual(invocationCountOfHasProducts, 1)
    }

    func test_reload_does_not_hit_blaze_remote_when_fetchFromRemote_is_false() async {
        // Given
        let checker = MockBlazeEligibilityChecker(isSiteEligible: true)
        let sut = BlazeCampaignDashboardViewModel(siteID: sampleSiteID,
                                                  stores: stores,
                                                  storageManager: storageManager,
                                                  blazeEligibilityChecker: checker)

        waitForExpectation { exp in
            exp.isInverted = true
            stores.whenReceivingAction(ofType: BlazeAction.self) { action in
                switch action {
                case .synchronizeCampaigns(_, _, _):
                    exp.fulfill()
                }
            }
        }

        // When
        await sut.reload(fetchFromRemote: false)
    }

    func test_reload_hits_blaze_remote_by_default() async {
        // Given
        var invocationCountOfLoadCampaigns = 0
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
                invocationCountOfLoadCampaigns += 1
                onCompletion(.success(true))
            }
        }

        // When
        await sut.reload()

        // Then
        XCTAssertEqual(invocationCountOfLoadCampaigns, 1)
    }
}

private extension BlazeCampaignDashboardViewModelTests {
    func insertCampaigns(_ readOnlyCampaigns: [BlazeCampaign]) {
        readOnlyCampaigns.forEach { campaign in
            let newCampaign = storage.insertNewObject(ofType: StorageBlazeCampaign.self)
            newCampaign.update(with: campaign)
        }
        storage.saveIfNeeded()
    }
}
