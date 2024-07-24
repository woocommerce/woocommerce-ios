import Foundation
import XCTest
import Yosemite
import protocol Storage.StorageType
import WordPressAuthenticator

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

    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: WooAnalytics!

    override func setUp() {
        super.setUp()
        WordPressAuthenticator.initializeAuthenticator()
        stores = MockStoresManager(sessionManager: .testingInstance)
        stores.updateDefaultStore(storeID: sampleSiteID)
        stores.updateDefaultStore(.fake().copy(siteID: sampleSiteID))
        storageManager = MockStorageManager()
        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
    }

    override func tearDown() {
        storageManager = nil
        stores = nil
        analyticsProvider = nil
        analytics = nil
        super.tearDown()
    }

    // MARK: `canShowInDashboard`

    @MainActor
    func test_canShowInDashboard_returns_true_if_store_is_eligible_for_blaze_and_has_at_least_one_published_product() async {
        // Given
        let checker = MockBlazeEligibilityChecker(isSiteEligible: true)

        let sut = BlazeCampaignDashboardViewModel(siteID: sampleSiteID,
                                                  stores: stores,
                                                  storageManager: storageManager,
                                                  blazeEligibilityChecker: checker)
        XCTAssertFalse(sut.canShowInDashboard)
        mockSynchronizeProducts(insertProductToStorage: .fake().copy(siteID: sampleSiteID,
                                                                     statusKey: (ProductStatus.published.rawValue),
                                                                     purchasable: true))

        mockSynchronizeCampaignsList()

        // When
        await sut.checkAvailability()

        // Then
        XCTAssertTrue(sut.canShowInDashboard)
    }

    @MainActor
    func test_canShowInDashboard_returns_false_if_store_is_eligible_for_blaze_but_has_no_published_product() async {
        // Given
        let checker = MockBlazeEligibilityChecker(isSiteEligible: true)

        let sut = BlazeCampaignDashboardViewModel(siteID: sampleSiteID,
                                                  stores: stores,
                                                  storageManager: storageManager,
                                                  blazeEligibilityChecker: checker)
        XCTAssertFalse(sut.canShowInDashboard)
        mockSynchronizeProducts()

        mockSynchronizeCampaignsList()

        // When
        await sut.checkAvailability()

        // Then
        XCTAssertFalse(sut.canShowInDashboard)
    }

    @MainActor
    func test_canShowInDashboard_returns_false_if_store_is_not_eligible_for_blaze() async {
        // Given
        let checker = MockBlazeEligibilityChecker(isSiteEligible: false)

        let sut = BlazeCampaignDashboardViewModel(siteID: sampleSiteID,
                                                  stores: stores,
                                                  storageManager: storageManager,
                                                  blazeEligibilityChecker: checker)
        XCTAssertFalse(sut.canShowInDashboard)
        mockSynchronizeProducts()

        mockSynchronizeCampaignsList()

        // When
        await sut.checkAvailability()

        // Then
        XCTAssertFalse(sut.canShowInDashboard)
    }

    // MARK: Published product

    @MainActor
    func test_it_shows_latest_published_product_in_dashboard() async {
        // Given
        let checker = MockBlazeEligibilityChecker(isSiteEligible: true)
        let product1: Product = .fake().copy(siteID: sampleSiteID,
                                             statusKey: (ProductStatus.published.rawValue),
                                             purchasable: true)
        insertProduct(product1)

        let product2: Product = .fake().copy(siteID: sampleSiteID,
                                             statusKey: (ProductStatus.published.rawValue),
                                             purchasable: true)

        let sut = BlazeCampaignDashboardViewModel(siteID: sampleSiteID,
                                                  stores: stores,
                                                  storageManager: storageManager,
                                                  blazeEligibilityChecker: checker)

        mockSynchronizeProducts(insertProductToStorage: product2)
        mockSynchronizeCampaignsList()

        // When
        await sut.checkAvailability()
        await sut.reload()

        // Then
        if case .showProduct(let product) = sut.state {
            XCTAssertEqual(product, product2)
        } else {
            XCTFail("Wrong state")
        }
    }

    // MARK: `state`

    @MainActor
    func test_state_is_loading_while_reloading() async {
        // Given
        let checker = MockBlazeEligibilityChecker(isSiteEligible: true)
        let sut = BlazeCampaignDashboardViewModel(siteID: sampleSiteID,
                                                  stores: stores,
                                                  storageManager: storageManager,
                                                  blazeEligibilityChecker: checker)

        stores.whenReceivingAction(ofType: BlazeAction.self) { action in
            switch action {
            case .synchronizeCampaignsList(_, _, _, let onCompletion):
                // Then
                if case .loading = sut.state {
                    // Loading state as expected
                } else {
                    XCTFail("Wrong state")
                }
                onCompletion(.success(false))
            default:
                break
            }
        }

        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case .synchronizeProducts(_, _, _, _, _, _, _, _, _, _, let onCompletion):
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

    @MainActor
    func test_state_is_showCampaign_if_blaze_campaign_available() async {
        // Given
        let checker = MockBlazeEligibilityChecker(isSiteEligible: true)
        let fakeBlazeCampaign = BlazeCampaignListItem.fake().copy(siteID: sampleSiteID, budgetCurrency: "USD")
        let sut = BlazeCampaignDashboardViewModel(siteID: sampleSiteID,
                                                  stores: stores,
                                                  storageManager: storageManager,
                                                  blazeEligibilityChecker: checker)

        mockSynchronizeCampaignsList(insertCampaignToStorage: fakeBlazeCampaign)
        mockSynchronizeProducts()

        // When
        await sut.checkAvailability()
        await sut.reload()

        // Then
        if case .showCampaign(let campaign) = sut.state {
            XCTAssertEqual(campaign, fakeBlazeCampaign)
        } else {
            XCTFail("Wrong state")
        }
    }

    @MainActor
    func test_state_is_showProduct_if_published_product_available_and_blaze_campaign_not_available() async {
        // Given
        let checker = MockBlazeEligibilityChecker(isSiteEligible: true)
        let fakeProduct = Product.fake().copy(siteID: sampleSiteID,
                                              statusKey: (ProductStatus.published.rawValue),
                                              purchasable: true)

        let sut = BlazeCampaignDashboardViewModel(siteID: sampleSiteID,
                                                  stores: stores,
                                                  storageManager: storageManager,
                                                  blazeEligibilityChecker: checker)

        mockSynchronizeCampaignsList()
        mockSynchronizeProducts(insertProductToStorage: fakeProduct)

        // When
        await sut.checkAvailability()
        await sut.reload()

        // Then
        if case .showProduct(let product) = sut.state {
            XCTAssertEqual(product, fakeProduct)
        } else {
            XCTFail("Wrong state")
        }
    }

    @MainActor
    func test_state_is_empty_if_draft_product_available_and_blaze_campaign_not_available() async {
        // Given
        let checker = MockBlazeEligibilityChecker(isSiteEligible: true)
        let fakeProduct = Product.fake().copy(siteID: sampleSiteID,
                                              statusKey: (ProductStatus.draft.rawValue))

        let sut = BlazeCampaignDashboardViewModel(siteID: sampleSiteID,
                                                  stores: stores,
                                                  storageManager: storageManager,
                                                  blazeEligibilityChecker: checker)

        mockSynchronizeCampaignsList()
        mockSynchronizeProducts(insertProductToStorage: fakeProduct)

        // When
        await sut.checkAvailability()
        await sut.reload()

        // Then
        if case .empty = sut.state {
            // empty state as expected
        } else {
            XCTFail("Wrong state")
        }
    }

    @MainActor
    func test_state_is_empty_if_no_blaze_campaign_no_product_available() async {
        // Given
        let checker = MockBlazeEligibilityChecker(isSiteEligible: true)
        let sut = BlazeCampaignDashboardViewModel(siteID: sampleSiteID,
                                                  stores: stores,
                                                  storageManager: storageManager,
                                                  blazeEligibilityChecker: checker)

        mockSynchronizeCampaignsList()
        mockSynchronizeProducts()

        // When
        await sut.checkAvailability()
        await sut.reload()

        // Then
        if case .empty = sut.state {
            // empty state as expected
        } else {
            XCTFail("Wrong state")
        }
    }

    // MARK: `shouldRedactView`

    @MainActor
    func test_shouldRedactView_is_true_while_reloading() async {
        // Given
        let checker = MockBlazeEligibilityChecker(isSiteEligible: true)
        let sut = BlazeCampaignDashboardViewModel(siteID: sampleSiteID,
                                                  stores: stores,
                                                  storageManager: storageManager,
                                                  blazeEligibilityChecker: checker)

        stores.whenReceivingAction(ofType: BlazeAction.self) { action in
            switch action {
            case .synchronizeCampaignsList(_, _, _, let onCompletion):
                // Then
                XCTAssertTrue(sut.shouldRedactView)
                onCompletion(.success(false))
            default:
                break
            }
        }

        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case .synchronizeProducts(_, _, _, _, _, _, _, _, _, _, let onCompletion):
                // Then
                XCTAssertTrue(sut.shouldRedactView)
                onCompletion(.success(true))
            default:
                break
            }
        }

        // When
        await sut.checkAvailability()
        await sut.reload()
    }

    @MainActor
    func test_shouldRedactView_is_false_after_reload_finishes_when_blaze_campaign_available() async {
        // Given
        let checker = MockBlazeEligibilityChecker(isSiteEligible: true)
        let fakeBlazeCampaign = BlazeCampaignListItem.fake().copy(siteID: sampleSiteID)
        let sut = BlazeCampaignDashboardViewModel(siteID: sampleSiteID,
                                                  stores: stores,
                                                  storageManager: storageManager,
                                                  blazeEligibilityChecker: checker)

        mockSynchronizeCampaignsList(insertCampaignToStorage: fakeBlazeCampaign)
        mockSynchronizeProducts()

        // When
        await sut.checkAvailability()
        await sut.reload()

        // Then
        XCTAssertFalse(sut.shouldRedactView)
    }

    @MainActor
    func test_shouldRedactView_is_false_after_reload_finishes_when_product_available() async {
        // Given
        let checker = MockBlazeEligibilityChecker(isSiteEligible: true)
        let fakeProduct = Product.fake().copy(siteID: sampleSiteID,
                                              statusKey: (ProductStatus.published.rawValue),
                                              purchasable: true)

        let sut = BlazeCampaignDashboardViewModel(siteID: sampleSiteID,
                                                  stores: stores,
                                                  storageManager: storageManager,
                                                  blazeEligibilityChecker: checker)

        mockSynchronizeCampaignsList()
        mockSynchronizeProducts(insertProductToStorage: fakeProduct)

        // When
        await sut.checkAvailability()
        await sut.reload()

        // Then
        XCTAssertFalse(sut.shouldRedactView)
    }

    @MainActor
    func test_shouldRedactView_is_true_after_reload_finishes_with_no_data() async {
        // Given
        let checker = MockBlazeEligibilityChecker(isSiteEligible: true)
        let sut = BlazeCampaignDashboardViewModel(siteID: sampleSiteID,
                                                  stores: stores,
                                                  storageManager: storageManager,
                                                  blazeEligibilityChecker: checker)

        mockSynchronizeCampaignsList()
        mockSynchronizeProducts()

        // When
        await sut.checkAvailability()
        await sut.reload()

        // Then
        XCTAssertTrue(sut.shouldRedactView)
    }

    // MARK: `shouldShowShowAllCampaignsButton`

    @MainActor
    func test_shouldShowShowAllCampaignsButton_is_false_while_reloading() async {
        // Given
        let checker = MockBlazeEligibilityChecker(isSiteEligible: true)
        let sut = BlazeCampaignDashboardViewModel(siteID: sampleSiteID,
                                                  stores: stores,
                                                  storageManager: storageManager,
                                                  blazeEligibilityChecker: checker)

        stores.whenReceivingAction(ofType: BlazeAction.self) { action in
            switch action {
            case .synchronizeCampaignsList(_, _, _, let onCompletion):
                // Then
                XCTAssertFalse(sut.shouldShowShowAllCampaignsButton)
                onCompletion(.success(false))
            default:
                break
            }
        }

        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case .synchronizeProducts(_, _, _, _, _, _, _, _, _, _, let onCompletion):
                // Then
                XCTAssertFalse(sut.shouldShowShowAllCampaignsButton)
                onCompletion(.success(true))
            default:
                break
            }
        }

        // When
        await sut.checkAvailability()
        await sut.reload()
    }

    @MainActor
    func test_shouldShowShowAllCampaignsButton_is_true_after_reload_finishes_when_blaze_campaign_available() async {
        // Given
        let checker = MockBlazeEligibilityChecker(isSiteEligible: true)
        let fakeBlazeCampaign = BlazeCampaignListItem.fake().copy(siteID: sampleSiteID)
        let sut = BlazeCampaignDashboardViewModel(siteID: sampleSiteID,
                                                  stores: stores,
                                                  storageManager: storageManager,
                                                  blazeEligibilityChecker: checker)

        mockSynchronizeCampaignsList(insertCampaignToStorage: fakeBlazeCampaign)
        mockSynchronizeProducts()

        // When
        await sut.checkAvailability()
        await sut.reload()

        // Then
        XCTAssertTrue(sut.shouldShowShowAllCampaignsButton)
    }

    @MainActor
    func test_shouldShowShowAllCampaignsButton_is_false_after_reload_finishes_when_product_available() async {
        // Given
        let checker = MockBlazeEligibilityChecker(isSiteEligible: true)
        let fakeProduct = Product.fake().copy(siteID: sampleSiteID,
                                              statusKey: (ProductStatus.published.rawValue))

        let sut = BlazeCampaignDashboardViewModel(siteID: sampleSiteID,
                                                  stores: stores,
                                                  storageManager: storageManager,
                                                  blazeEligibilityChecker: checker)

        mockSynchronizeCampaignsList()
        mockSynchronizeProducts(insertProductToStorage: fakeProduct)

        // When
        await sut.checkAvailability()
        await sut.reload()

        // Then
        XCTAssertFalse(sut.shouldShowShowAllCampaignsButton)
    }

    @MainActor
    func test_shouldShowShowAllCampaignsButton_is_false_after_reload_finishes_with_no_data() async {
        // Given
        let checker = MockBlazeEligibilityChecker(isSiteEligible: true)
        let sut = BlazeCampaignDashboardViewModel(siteID: sampleSiteID,
                                                  stores: stores,
                                                  storageManager: storageManager,
                                                  blazeEligibilityChecker: checker)

        mockSynchronizeCampaignsList()
        mockSynchronizeProducts()

        // When
        await sut.checkAvailability()
        await sut.reload()

        // Then
        XCTAssertFalse(sut.shouldShowShowAllCampaignsButton)
    }

    // MARK: Listen from storage

    @MainActor
    func test_state_is_showCampaign_if_blaze_campaign_is_added_to_storage() async {
        // Given
        let checker = MockBlazeEligibilityChecker(isSiteEligible: true)
        let fakeBlazeCampaign = BlazeCampaignListItem.fake().copy(siteID: sampleSiteID, budgetCurrency: "USD")
        let sut = BlazeCampaignDashboardViewModel(siteID: sampleSiteID,
                                                  stores: stores,
                                                  storageManager: storageManager,
                                                  blazeEligibilityChecker: checker)

        mockSynchronizeCampaignsList()
        mockSynchronizeProducts()

        await sut.checkAvailability()
        await sut.reload()

        if case .empty = sut.state {
            // Expected empty state when no Blaze campaign or published product
        } else {
            XCTFail("Wrong state")
        }

        // When
        insertCampaigns([fakeBlazeCampaign])

        // Then
        if case .showCampaign(let campaign) = sut.state {
            XCTAssertEqual(campaign, fakeBlazeCampaign)
        } else {
            XCTFail("Wrong state")
        }
    }

    @MainActor
    func test_latest_campaign_is_displayed() async {
        // Given
        let checker = MockBlazeEligibilityChecker(isSiteEligible: true)
        let campaign1 = BlazeCampaignListItem.fake().copy(siteID: sampleSiteID, campaignID: "9", budgetCurrency: "USD")
        let campaign2 = BlazeCampaignListItem.fake().copy(siteID: sampleSiteID, campaignID: "10", budgetCurrency: "USD")
        let sut = BlazeCampaignDashboardViewModel(siteID: sampleSiteID,
                                                  stores: stores,
                                                  storageManager: storageManager,
                                                  blazeEligibilityChecker: checker)

        mockSynchronizeCampaignsList()
        mockSynchronizeProducts()

        await sut.checkAvailability()
        await sut.reload()

        if case .empty = sut.state {
            // Expected empty state when no Blaze campaign or published product
        } else {
            XCTFail("Wrong state")
        }

        // When
        insertCampaigns([campaign1, campaign2])

        // Then
        if case .showCampaign(let campaign) = sut.state {
            XCTAssertEqual(campaign, campaign2)
        } else {
            XCTFail("Wrong state")
        }
    }

    @MainActor
    func test_state_is_showProduct_if_published_product_is_added_to_storage() async {
        // Given
        let checker = MockBlazeEligibilityChecker(isSiteEligible: true)
        let fakeProduct = Product.fake().copy(siteID: sampleSiteID,
                                              statusKey: (ProductStatus.published.rawValue),
                                              purchasable: true)
        let sut = BlazeCampaignDashboardViewModel(siteID: sampleSiteID,
                                                  stores: stores,
                                                  storageManager: storageManager,
                                                  blazeEligibilityChecker: checker)

        mockSynchronizeCampaignsList()
        mockSynchronizeProducts()

        await sut.checkAvailability()
        await sut.reload()

        if case .empty = sut.state {
            // Expected empty state when no Blaze campaign or published product
        } else {
            XCTFail("Wrong state")
        }

        // When
        insertProduct(fakeProduct)

        // Then
        if case .showProduct(let product) = sut.state {
            XCTAssertEqual(product, fakeProduct)
        } else {
            XCTFail("Wrong state")
        }
    }

    // MARK: latestPublishedProduct

    @MainActor
    func test_latestPublishedProduct_returns_correct_product() throws {
        // Given
        insertProduct(Product.fake().copy(siteID: sampleSiteID,
                                          productID: 1,
                                          statusKey: (ProductStatus.published.rawValue),
                                          purchasable: true))
        insertProduct(Product.fake().copy(siteID: sampleSiteID,
                                          productID: 2,
                                          statusKey: (ProductStatus.draft.rawValue),
                                          purchasable: true))
        insertProduct(Product.fake().copy(siteID: sampleSiteID,
                                          productID: 3,
                                          statusKey: (ProductStatus.published.rawValue),
                                          purchasable: true))

        let checker = MockBlazeEligibilityChecker(isSiteEligible: true)
        let viewModel = BlazeCampaignDashboardViewModel(siteID: sampleSiteID,
                                                        stores: stores,
                                                        storageManager: storageManager,
                                                        blazeEligibilityChecker: checker)
        // Then
        let product = try XCTUnwrap(viewModel.latestPublishedProduct)
        XCTAssertEqual(product.productID, 3)
    }

    @MainActor
    func test_latestPublishedProduct_is_nil_when_no_published_product_available() throws {
        // Given
        insertProduct(Product.fake().copy(siteID: sampleSiteID,
                                          productID: 1,
                                          statusKey: (ProductStatus.draft.rawValue),
                                          purchasable: true))

        let checker = MockBlazeEligibilityChecker(isSiteEligible: true)
        let viewModel = BlazeCampaignDashboardViewModel(siteID: sampleSiteID,
                                                        stores: stores,
                                                        storageManager: storageManager,
                                                        blazeEligibilityChecker: checker)
        // Then
        XCTAssertNil(viewModel.latestPublishedProduct)
    }

    // MARK: `selectedCampaignURL`

    @MainActor
    func test_didSelectCampaignDetails_updates_selectedCampaignURL_correctly() {
        // Given
        let testURL = "https://example.com"
        let site = Site.fake().copy(siteID: sampleSiteID, url: testURL)
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, isWPCom: true, defaultSite: site))
        let campaign = BlazeCampaignListItem.fake().copy(siteID: sampleSiteID, campaignID: "123")
        let checker = MockBlazeEligibilityChecker(isSiteEligible: true)
        let viewModel = BlazeCampaignDashboardViewModel(siteID: sampleSiteID,
                                                        stores: stores,
                                                        storageManager: storageManager,
                                                        blazeEligibilityChecker: checker)
        // Confidence check
        XCTAssertNil(viewModel.selectedCampaignURL)

        // When
        viewModel.didSelectCampaignDetails(campaign)

        // Then
        XCTAssertEqual(viewModel.selectedCampaignURL?.absoluteString, "https://wordpress.com/advertising/campaigns/123/example.com?source=my_store_section")
    }

    // MARK: Analytics

    @MainActor
    func test_didTapCreateYourCampaignButtonFromIntroView_tracks_entry_point_tapped() throws {
        // Given
        let checker = MockBlazeEligibilityChecker(isSiteEligible: true)
        let viewModel = BlazeCampaignDashboardViewModel(siteID: sampleSiteID,
                                                        stores: stores,
                                                        storageManager: storageManager,
                                                        analytics: analytics,
                                                        blazeEligibilityChecker: checker)

        // When
        viewModel.didTapCreateYourCampaignButtonFromIntroView()

        // Then
        let index = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(of: "blaze_entry_point_tapped"))
        let properties = try XCTUnwrap(analyticsProvider.receivedProperties[index])
        XCTAssertEqual(properties["source"] as? String, "intro_view")
    }

    @MainActor
    func test_didSelectCampaignList_tracks_blazeCampaignListEntryPointSelected_with_the_correct_source() throws {
        // Given
        let checker = MockBlazeEligibilityChecker(isSiteEligible: true)
        let viewModel = BlazeCampaignDashboardViewModel(siteID: sampleSiteID,
                                                        stores: stores,
                                                        storageManager: storageManager,
                                                        analytics: analytics,
                                                        blazeEligibilityChecker: checker)

        // When
        viewModel.didSelectCampaignList()

        // Then
        XCTAssertTrue(analyticsProvider.receivedEvents.contains("blaze_campaign_list_entry_point_selected"))
        let index = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(of: "blaze_campaign_list_entry_point_selected"))
        let properties = try XCTUnwrap(analyticsProvider.receivedProperties[index])
        XCTAssertEqual(properties["source"] as? String, "my_store_section")
    }

    @MainActor
    func test_didSelectCampaignDetails_tracks_blazeCampaignDetailSelected_with_the_correct_source() throws {
        // Given
        let checker = MockBlazeEligibilityChecker(isSiteEligible: true)
        let viewModel = BlazeCampaignDashboardViewModel(siteID: sampleSiteID,
                                                        stores: stores,
                                                        storageManager: storageManager,
                                                        analytics: analytics,
                                                        blazeEligibilityChecker: checker)

        // When
        viewModel.didSelectCampaignDetails(.fake())

        // Then
        XCTAssertTrue(analyticsProvider.receivedEvents.contains("blaze_campaign_detail_selected"))
        let index = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(of: "blaze_campaign_detail_selected"))
        let properties = try XCTUnwrap(analyticsProvider.receivedProperties[index])
        XCTAssertEqual(properties["source"] as? String, "my_store_section")
    }

    @MainActor
    func test_didSelectCreateCampaign_tracks_blazeEntryPointTapped() throws {
        // Given
        let checker = MockBlazeEligibilityChecker(isSiteEligible: true)
        let viewModel = BlazeCampaignDashboardViewModel(siteID: sampleSiteID,
                                                        stores: stores,
                                                        storageManager: storageManager,
                                                        analytics: analytics,
                                                        blazeEligibilityChecker: checker)

        // When
        viewModel.didSelectCreateCampaign(source: .introView)

        // Then
        XCTAssertTrue(analyticsProvider.receivedEvents.contains("blaze_entry_point_tapped"))
        let index = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(of: "blaze_entry_point_tapped"))
        let properties = try XCTUnwrap(analyticsProvider.receivedProperties[index])
        XCTAssertEqual(properties["source"] as? String, "intro_view")
    }

    @MainActor
    func test_blazeEntryPointDisplayed_tracked_if_blaze_campaign_available() async throws {
        // Given
        let checker = MockBlazeEligibilityChecker(isSiteEligible: true)
        let fakeBlazeCampaign = BlazeCampaignListItem.fake().copy(siteID: sampleSiteID)
        let sut = BlazeCampaignDashboardViewModel(siteID: sampleSiteID,
                                                  stores: stores,
                                                  storageManager: storageManager,
                                                  analytics: analytics,
                                                  blazeEligibilityChecker: checker)

        mockSynchronizeCampaignsList(insertCampaignToStorage: fakeBlazeCampaign)
        mockSynchronizeProducts()

        // When
        await sut.checkAvailability()
        await sut.reload()

        // Then
        XCTAssertTrue(analyticsProvider.receivedEvents.contains("blaze_entry_point_displayed"))
        let index = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(of: "blaze_entry_point_displayed"))
        let eventProperties = try XCTUnwrap(analyticsProvider.receivedProperties[index])
        XCTAssertEqual(eventProperties["source"] as? String, "my_store_section")
    }

    @MainActor
    func test_blazeEntryPointDisplayed_tracked_if_published_product_available_and_blaze_campaign_not_available() async throws {
        // Given
        let checker = MockBlazeEligibilityChecker(isSiteEligible: true)
        let fakeProduct = Product.fake().copy(siteID: sampleSiteID,
                                              statusKey: (ProductStatus.published.rawValue),
                                              purchasable: true)

        let sut = BlazeCampaignDashboardViewModel(siteID: sampleSiteID,
                                                  stores: stores,
                                                  storageManager: storageManager,
                                                  analytics: analytics,
                                                  blazeEligibilityChecker: checker)

        mockSynchronizeCampaignsList()
        mockSynchronizeProducts(insertProductToStorage: fakeProduct)

        // When
        await sut.checkAvailability()
        await sut.reload()

        // Then
        XCTAssertTrue(analyticsProvider.receivedEvents.contains("blaze_entry_point_displayed"))
        let index = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(of: "blaze_entry_point_displayed"))
        let eventProperties = try XCTUnwrap(analyticsProvider.receivedProperties[index])
        XCTAssertEqual(eventProperties["source"] as? String, "my_store_section")
    }

    @MainActor
    func test_blazeEntryPointDisplayed_is_not_tracked_if_draft_product_available_and_blaze_campaign_not_available() async {
        // Given
        let checker = MockBlazeEligibilityChecker(isSiteEligible: true)
        let fakeProduct = Product.fake().copy(siteID: sampleSiteID,
                                              statusKey: (ProductStatus.draft.rawValue))

        let sut = BlazeCampaignDashboardViewModel(siteID: sampleSiteID,
                                                  stores: stores,
                                                  storageManager: storageManager,
                                                  analytics: analytics,
                                                  blazeEligibilityChecker: checker)

        mockSynchronizeCampaignsList()
        mockSynchronizeProducts(insertProductToStorage: fakeProduct)

        // When
        await sut.reload()

        // Then
        XCTAssertFalse(analyticsProvider.receivedEvents.contains("blaze_entry_point_displayed"))
    }

    @MainActor
    func test_blazeEntryPointDisplayed_is_not_tracked_if_no_blaze_campaign_no_product_available() async {
        // Given
        let checker = MockBlazeEligibilityChecker(isSiteEligible: true)
        let sut = BlazeCampaignDashboardViewModel(siteID: sampleSiteID,
                                                  stores: stores,
                                                  storageManager: storageManager,
                                                  analytics: analytics,
                                                  blazeEligibilityChecker: checker)

        mockSynchronizeCampaignsList()
        mockSynchronizeProducts()

        // When
        await sut.reload()

        // Then
        XCTAssertFalse(analyticsProvider.receivedEvents.contains("blaze_entry_point_displayed"))
    }

    @MainActor
    func test_blazeEntryPointDisplayed_is_not_tracked_again_after_reload() async throws {
        // Given
        let checker = MockBlazeEligibilityChecker(isSiteEligible: true)
        let fakeBlazeCampaign = BlazeCampaignListItem.fake().copy(siteID: sampleSiteID)
        let sut = BlazeCampaignDashboardViewModel(siteID: sampleSiteID,
                                                  stores: stores,
                                                  storageManager: storageManager,
                                                  analytics: analytics,
                                                  blazeEligibilityChecker: checker)

        mockSynchronizeCampaignsList(insertCampaignToStorage: fakeBlazeCampaign)
        mockSynchronizeProducts()

        // When
        await sut.checkAvailability()
        await sut.reload()

        // Then
        XCTAssertTrue(analyticsProvider.receivedEvents.filter { $0 == "blaze_entry_point_displayed" }.count == 1)

        // When
        await sut.checkAvailability()
        await sut.reload()

        // Then
        XCTAssertTrue(analyticsProvider.receivedEvents.filter { $0 == "blaze_entry_point_displayed" }.count == 1)
    }

    @MainActor
    func test_dismissBlazeSection_triggers_tracking_event() throws {
        // Given
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        let viewModel = BlazeCampaignDashboardViewModel(siteID: 123, analytics: analytics)

        // When
        viewModel.dismissBlazeSection()

        // Then
        let index = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == "dynamic_dashboard_hide_card_tapped" }))
        let properties = analyticsProvider.receivedProperties[index] as? [String: AnyHashable]
        XCTAssertEqual(properties?["type"], "blaze")
    }
}

private extension BlazeCampaignDashboardViewModelTests {
    func insertProduct(_ readOnlyProduct: Product) {
        let newProduct = storage.insertNewObject(ofType: StorageProduct.self)
        newProduct.update(with: readOnlyProduct)
        storage.saveIfNeeded()
    }

    func insertCampaigns(_ readOnlyCampaigns: [BlazeCampaignListItem]) {
        readOnlyCampaigns.forEach { campaign in
            let newCampaign = storage.insertNewObject(ofType: StorageBlazeCampaignListItem.self)
            newCampaign.update(with: campaign)
        }
        storage.saveIfNeeded()
    }

    func mockSynchronizeProducts(insertProductToStorage product: Product? = nil) {
        stores.whenReceivingAction(ofType: ProductAction.self) { [weak self] action in
            switch action {
            case .synchronizeProducts(_, _, _, _, _, _, _, _, _, _, let onCompletion):
                if let product {
                    self?.insertProduct(product)
                }
                onCompletion(.success(true))
            default:
                break
            }
        }
    }

    func mockSynchronizeCampaignsList(insertCampaignToStorage BlazeCampaignListItem: BlazeCampaignListItem? = nil) {
        stores.whenReceivingAction(ofType: BlazeAction.self) { [weak self] action in
            switch action {
            case .synchronizeCampaignsList(_, _, _, let onCompletion):
                if let BlazeCampaignListItem {
                    self?.insertCampaigns([BlazeCampaignListItem])
                }
                onCompletion(.success(false))
            default:
                break
            }
        }
    }
}
