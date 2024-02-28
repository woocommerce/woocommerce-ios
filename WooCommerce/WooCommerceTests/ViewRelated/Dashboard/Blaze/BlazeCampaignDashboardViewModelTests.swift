import Foundation
import XCTest
import Yosemite
import protocol Storage.StorageType
import WordPressAuthenticator

@testable import WooCommerce

/// Test cases for `BlazeCampaignDashboardViewModel`.
///
@MainActor
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

    // MARK: `shouldShowInDashboard`

    func test_shouldShowInDashboard_is_false_by_default() async {
        // Given
        let checker = MockBlazeEligibilityChecker(isSiteEligible: true)
        insertProduct(.fake().copy(siteID: sampleSiteID,
                                   statusKey: (ProductStatus.published.rawValue),
                                   purchasable: true))

        let sut = BlazeCampaignDashboardViewModel(siteID: sampleSiteID,
                                                  stores: stores,
                                                  storageManager: storageManager,
                                                  blazeEligibilityChecker: checker)

        // Then
        XCTAssertFalse(sut.shouldShowInDashboard)
    }

    // MARK: Blaze eligibility

    func test_it_shows_in_dashboard_if_eligible_for_blaze() async {
        // Given
        let checker = MockBlazeEligibilityChecker(isSiteEligible: true)
        let sut = BlazeCampaignDashboardViewModel(siteID: sampleSiteID,
                                                  stores: stores,
                                                  storageManager: storageManager,
                                                  blazeEligibilityChecker: checker)

        mockSynchronizeProducts(insertProductToStorage: .fake().copy(siteID: sampleSiteID,
                                                                     statusKey: (ProductStatus.published.rawValue),
                                                                     purchasable: true))

        mockSynchronizeBriefCampaigns()

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

        mockSynchronizeProducts(insertProductToStorage: .fake().copy(siteID: sampleSiteID,
                                                                     statusKey: (ProductStatus.published.rawValue)))

        mockSynchronizeBriefCampaigns()

        // When
        await sut.reload()

        // Then
        XCTAssertFalse(sut.shouldShowInDashboard)
    }

    func test_it_hides_from_dashboard_if_a_product_gets_published_while_site_not_eligible_for_blaze() async {
        // Given
        let checker = MockBlazeEligibilityChecker(isSiteEligible: false)
        let sut = BlazeCampaignDashboardViewModel(siteID: sampleSiteID,
                                                  stores: stores,
                                                  storageManager: storageManager,
                                                  blazeEligibilityChecker: checker)

        mockSynchronizeProducts()

        mockSynchronizeBriefCampaigns()

        // When
        await sut.reload()

        insertProduct(.fake().copy(siteID: sampleSiteID,
                                   statusKey: (ProductStatus.published.rawValue)))

        // Then
        XCTAssertFalse(sut.shouldShowInDashboard)
    }

    // MARK: Blaze campaigns

    func test_it_shows_in_dashboard_if_blaze_campaign_available() async {
        // Given
        let checker = MockBlazeEligibilityChecker(isSiteEligible: true)
        let BriefBlazeCampaignInfo = BriefBlazeCampaignInfo.fake().copy(siteID: sampleSiteID)
        let sut = BlazeCampaignDashboardViewModel(siteID: sampleSiteID,
                                                  stores: stores,
                                                  storageManager: storageManager,
                                                  blazeEligibilityChecker: checker)

        stores.whenReceivingAction(ofType: BlazeAction.self) { [weak self] action in
            switch action {
            case .synchronizeBriefCampaigns(_, _, _, let onCompletion):
                self?.insertCampaigns([BriefBlazeCampaignInfo])
                onCompletion(.success(false))
            default:
                break
            }
        }

        mockSynchronizeProducts()

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

        mockSynchronizeProducts()
        mockSynchronizeBriefCampaigns()

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

        mockSynchronizeProducts(insertProductToStorage: .fake().copy(siteID: sampleSiteID,
                                                                     statusKey: (ProductStatus.published.rawValue),
                                                                     purchasable: true))
        mockSynchronizeBriefCampaigns()

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

        mockSynchronizeProducts()
        mockSynchronizeBriefCampaigns()

        // When
        await sut.reload()

        // Then
        XCTAssertFalse(sut.shouldShowInDashboard)
    }

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
        mockSynchronizeBriefCampaigns()

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
            case .synchronizeBriefCampaigns(_, _, _, let onCompletion):
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

    func test_state_is_showCampaign_if_blaze_campaign_available() async {
        // Given
        let checker = MockBlazeEligibilityChecker(isSiteEligible: true)
        let fakeBlazeCampaign = BriefBlazeCampaignInfo.fake().copy(siteID: sampleSiteID)
        let sut = BlazeCampaignDashboardViewModel(siteID: sampleSiteID,
                                                  stores: stores,
                                                  storageManager: storageManager,
                                                  blazeEligibilityChecker: checker)

        mockSynchronizeBriefCampaigns(insertCampaignToStorage: fakeBlazeCampaign)
        mockSynchronizeProducts()

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
                                              statusKey: (ProductStatus.published.rawValue),
                                              purchasable: true)

        let sut = BlazeCampaignDashboardViewModel(siteID: sampleSiteID,
                                                  stores: stores,
                                                  storageManager: storageManager,
                                                  blazeEligibilityChecker: checker)

        mockSynchronizeBriefCampaigns()
        mockSynchronizeProducts(insertProductToStorage: fakeProduct)

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

        mockSynchronizeBriefCampaigns()
        mockSynchronizeProducts(insertProductToStorage: fakeProduct)

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

        mockSynchronizeBriefCampaigns()
        mockSynchronizeProducts()

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
            case .synchronizeBriefCampaigns(_, _, _, let onCompletion):
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
        await sut.reload()
    }

    func test_shouldRedactView_is_false_after_reload_finishes_when_blaze_campaign_available() async {
        // Given
        let checker = MockBlazeEligibilityChecker(isSiteEligible: true)
        let fakeBlazeCampaign = BriefBlazeCampaignInfo.fake().copy(siteID: sampleSiteID)
        let sut = BlazeCampaignDashboardViewModel(siteID: sampleSiteID,
                                                  stores: stores,
                                                  storageManager: storageManager,
                                                  blazeEligibilityChecker: checker)

        mockSynchronizeBriefCampaigns(insertCampaignToStorage: fakeBlazeCampaign)
        mockSynchronizeProducts()

        // When
        await sut.reload()

        // Then
        XCTAssertFalse(sut.shouldRedactView)
    }

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

        mockSynchronizeBriefCampaigns()
        mockSynchronizeProducts(insertProductToStorage: fakeProduct)

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

        mockSynchronizeBriefCampaigns()
        mockSynchronizeProducts()

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
            case .synchronizeBriefCampaigns(_, _, _, let onCompletion):
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
        await sut.reload()
    }

    func test_shouldShowShowAllCampaignsButton_is_true_after_reload_finishes_when_blaze_campaign_available() async {
        // Given
        let checker = MockBlazeEligibilityChecker(isSiteEligible: true)
        let fakeBlazeCampaign = BriefBlazeCampaignInfo.fake().copy(siteID: sampleSiteID)
        let sut = BlazeCampaignDashboardViewModel(siteID: sampleSiteID,
                                                  stores: stores,
                                                  storageManager: storageManager,
                                                  blazeEligibilityChecker: checker)

        mockSynchronizeBriefCampaigns(insertCampaignToStorage: fakeBlazeCampaign)
        mockSynchronizeProducts()
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

        mockSynchronizeBriefCampaigns()
        mockSynchronizeProducts(insertProductToStorage: fakeProduct)

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

        mockSynchronizeBriefCampaigns()
        mockSynchronizeProducts()

        // When
        await sut.reload()

        // Then
        XCTAssertFalse(sut.shouldShowShowAllCampaignsButton)
    }

    // MARK: Listen from storage

    func test_state_is_showCampaign_if_blaze_campaign_is_added_to_storage() async {
        // Given
        let checker = MockBlazeEligibilityChecker(isSiteEligible: true)
        let fakeBlazeCampaign = BriefBlazeCampaignInfo.fake().copy(siteID: sampleSiteID)
        let sut = BlazeCampaignDashboardViewModel(siteID: sampleSiteID,
                                                  stores: stores,
                                                  storageManager: storageManager,
                                                  blazeEligibilityChecker: checker)

        mockSynchronizeBriefCampaigns()
        mockSynchronizeProducts()

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

        mockSynchronizeBriefCampaigns()
        mockSynchronizeProducts()

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

    func test_didSelectCampaignDetails_updates_selectedCampaignURL_correctly() {
        // Given
        let testURL = "https://example.com"
        let site = Site.fake().copy(siteID: sampleSiteID, url: testURL)
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, isWPCom: true, defaultSite: site))
        let campaign = BriefBlazeCampaignInfo.fake().copy(siteID: sampleSiteID, campaignID: "123")
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

    func test_blazeEntryPointDisplayed_tracked_if_blaze_campaign_available() async throws {
        // Given
        let checker = MockBlazeEligibilityChecker(isSiteEligible: true)
        let fakeBlazeCampaign = BriefBlazeCampaignInfo.fake().copy(siteID: sampleSiteID)
        let sut = BlazeCampaignDashboardViewModel(siteID: sampleSiteID,
                                                  stores: stores,
                                                  storageManager: storageManager,
                                                  analytics: analytics,
                                                  blazeEligibilityChecker: checker)

        mockSynchronizeBriefCampaigns(insertCampaignToStorage: fakeBlazeCampaign)
        mockSynchronizeProducts()

        // When
        await sut.reload()

        // Then
        XCTAssertTrue(analyticsProvider.receivedEvents.contains("blaze_entry_point_displayed"))
        let index = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(of: "blaze_entry_point_displayed"))
        let eventProperties = try XCTUnwrap(analyticsProvider.receivedProperties[index])
        XCTAssertEqual(eventProperties["source"] as? String, "my_store_section")
    }

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

        mockSynchronizeBriefCampaigns()
        mockSynchronizeProducts(insertProductToStorage: fakeProduct)

        // When
        await sut.reload()

        // Then
        XCTAssertTrue(analyticsProvider.receivedEvents.contains("blaze_entry_point_displayed"))
        let index = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(of: "blaze_entry_point_displayed"))
        let eventProperties = try XCTUnwrap(analyticsProvider.receivedProperties[index])
        XCTAssertEqual(eventProperties["source"] as? String, "my_store_section")
    }

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

        mockSynchronizeBriefCampaigns()
        mockSynchronizeProducts(insertProductToStorage: fakeProduct)

        // When
        await sut.reload()

        // Then
        XCTAssertFalse(analyticsProvider.receivedEvents.contains("blaze_entry_point_displayed"))
    }

    func test_blazeEntryPointDisplayed_is_not_tracked_if_no_blaze_campaign_no_product_available() async {
        // Given
        let checker = MockBlazeEligibilityChecker(isSiteEligible: true)
        let sut = BlazeCampaignDashboardViewModel(siteID: sampleSiteID,
                                                  stores: stores,
                                                  storageManager: storageManager,
                                                  analytics: analytics,
                                                  blazeEligibilityChecker: checker)

        mockSynchronizeBriefCampaigns()
        mockSynchronizeProducts()

        // When
        await sut.reload()

        // Then
        XCTAssertFalse(analyticsProvider.receivedEvents.contains("blaze_entry_point_displayed"))
    }

    func test_blazeEntryPointDisplayed_is_not_tracked_again_after_reload() async throws {
        // Given
        let checker = MockBlazeEligibilityChecker(isSiteEligible: true)
        let fakeBlazeCampaign = BriefBlazeCampaignInfo.fake().copy(siteID: sampleSiteID)
        let sut = BlazeCampaignDashboardViewModel(siteID: sampleSiteID,
                                                  stores: stores,
                                                  storageManager: storageManager,
                                                  analytics: analytics,
                                                  blazeEligibilityChecker: checker)

        mockSynchronizeBriefCampaigns(insertCampaignToStorage: fakeBlazeCampaign)
        mockSynchronizeProducts()

        // When
        await sut.reload()

        // Then
        XCTAssertTrue(analyticsProvider.receivedEvents.filter { $0 == "blaze_entry_point_displayed" }.count == 1)

        // When
        await sut.reload()

        // Then
        XCTAssertTrue(analyticsProvider.receivedEvents.filter { $0 == "blaze_entry_point_displayed" }.count == 1)
    }

    func test_dismissBlazeSection_sets_state_to_empty() async throws {
        // Given
        let checker = MockBlazeEligibilityChecker(isSiteEligible: true)
        let uuid = UUID().uuidString
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        let viewModel = BlazeCampaignDashboardViewModel(siteID: sampleSiteID,
                                                        stores: stores,
                                                        storageManager: storageManager,
                                                        blazeEligibilityChecker: checker,
                                                        userDefaults: userDefaults)

        let fakeBlazeCampaign = BriefBlazeCampaignInfo.fake().copy(siteID: sampleSiteID)
        mockSynchronizeBriefCampaigns(insertCampaignToStorage: fakeBlazeCampaign)
        mockSynchronizeProducts()

        await viewModel.reload()
        // confidence check
        XCTAssertEqual(viewModel.state, .showCampaign(campaign: fakeBlazeCampaign))

        // When
        viewModel.dismissBlazeSection()

        // Then
        XCTAssertEqual(viewModel.state, .empty)
    }
}

private extension BlazeCampaignDashboardViewModelTests {
    func insertProduct(_ readOnlyProduct: Product) {
        let newProduct = storage.insertNewObject(ofType: StorageProduct.self)
        newProduct.update(with: readOnlyProduct)
        storage.saveIfNeeded()
    }

    func insertCampaigns(_ readOnlyCampaigns: [BriefBlazeCampaignInfo]) {
        readOnlyCampaigns.forEach { campaign in
            let newCampaign = storage.insertNewObject(ofType: StorageBriefBlazeCampaignInfo.self)
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

    func mockSynchronizeBriefCampaigns(insertCampaignToStorage BriefBlazeCampaignInfo: BriefBlazeCampaignInfo? = nil) {
        stores.whenReceivingAction(ofType: BlazeAction.self) { [weak self] action in
            switch action {
            case .synchronizeBriefCampaigns(_, _, _, let onCompletion):
                if let BriefBlazeCampaignInfo {
                    self?.insertCampaigns([BriefBlazeCampaignInfo])
                }
                onCompletion(.success(false))
            default:
                break
            }
        }
    }
}
