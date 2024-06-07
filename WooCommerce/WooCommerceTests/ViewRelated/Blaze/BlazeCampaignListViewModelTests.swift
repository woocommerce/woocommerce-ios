import Combine
import XCTest
import Yosemite
import protocol Storage.StorageManagerType
import protocol Storage.StorageType
@testable import WooCommerce

final class BlazeCampaignListViewModelTests: XCTestCase {

    private let sampleSiteID: Int64 = 322

    private var subscriptions: [AnyCancellable] = []

    /// Mock Storage: InMemory
    private var storageManager: StorageManagerType!

    /// View storage for tests
    private var storage: StorageType {
        storageManager.viewStorage
    }

    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: WooAnalytics!

    override func setUp() {
        super.setUp()
        storageManager = MockStorageManager()
        subscriptions = []
        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
    }

    // MARK: - State transitions

    func test_state_is_empty_without_any_actions() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        var invocationCountOfLoadCampaigns = 0
        stores.whenReceivingAction(ofType: BlazeAction.self) { action in
            guard case .synchronizeCampaignsList = action else {
                return
            }
            invocationCountOfLoadCampaigns += 1
        }
        let viewModel = BlazeCampaignListViewModel(siteID: sampleSiteID, stores: stores)

        // Then
        XCTAssertEqual(viewModel.syncState, .empty)
        XCTAssertEqual(invocationCountOfLoadCampaigns, 0)
    }

    func test_synchronizeCampaignsList_is_dispatched_upon_loadCampaigns() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        var invocationCountOfLoadCampaigns = 0
        stores.whenReceivingAction(ofType: BlazeAction.self) { action in
            guard case .synchronizeCampaignsList = action else {
                return
            }
            invocationCountOfLoadCampaigns += 1
        }
        let viewModel = BlazeCampaignListViewModel(siteID: sampleSiteID, stores: stores)

        // When
        viewModel.loadCampaigns()

        // Then
        XCTAssertEqual(invocationCountOfLoadCampaigns, 1)
    }

    func test_state_is_syncingFirstPage_upon_loadCampaigns_if_there_is_no_existing_campaign_in_storage() {
        let viewModel = BlazeCampaignListViewModel(siteID: sampleSiteID)

        // When
        viewModel.loadCampaigns()

        // Then
        XCTAssertEqual(viewModel.syncState, .syncingFirstPage)
    }

    func test_state_is_results_upon_loadCampaigns_if_there_are_existing_campaigns_in_storage() {
        let existingCampaign = BlazeCampaignListItem.fake().copy(siteID: sampleSiteID, campaignID: "123")
        insertCampaigns([existingCampaign])
        let viewModel = BlazeCampaignListViewModel(siteID: sampleSiteID, storageManager: storageManager)

        // When
        viewModel.loadCampaigns()

        // Then
        XCTAssertEqual(viewModel.syncState, .results)
    }

    func test_state_is_results_after_loadCampaigns_with_nonempty_results() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        var skip: Int?
        let campaign = BlazeCampaignListItem.fake().copy(siteID: sampleSiteID)
        stores.whenReceivingAction(ofType: BlazeAction.self) { action in
            guard case let .synchronizeCampaignsList(_, skipValue, _, onCompletion) = action else {
                return
            }
            skip = skipValue
            self.insertCampaigns([campaign])
            onCompletion(.success(true))
        }
        let viewModel = BlazeCampaignListViewModel(siteID: sampleSiteID, stores: stores, storageManager: storageManager)

        var states = [BlazeCampaignListViewModel.SyncState]()
        viewModel.$syncState
            .removeDuplicates()
            .sink { state in
                states.append(state)
            }
            .store(in: &subscriptions)

        // When
        viewModel.loadCampaigns()

        // Then
        XCTAssertEqual(skip, 0)
        XCTAssertEqual(states, [.empty, .syncingFirstPage, .results])
    }

    func test_state_is_back_to_empty_after_loadCampaigns_with_empty_results() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        var skip: Int?
        stores.whenReceivingAction(ofType: BlazeAction.self) { action in
            guard case let .synchronizeCampaignsList(_, skipValue, _, onCompletion) = action else {
                return
            }
            skip = skipValue
            onCompletion(.success(false))
        }
        let viewModel = BlazeCampaignListViewModel(siteID: sampleSiteID, stores: stores, storageManager: storageManager)

        var states = [BlazeCampaignListViewModel.SyncState]()
        viewModel.$syncState
            .removeDuplicates()
            .sink { state in
                states.append(state)
            }
            .store(in: &subscriptions)

        // When
        viewModel.loadCampaigns()

        // Then
        XCTAssertEqual(skip, 0)
        XCTAssertEqual(states, [.empty, .syncingFirstPage, .empty])
    }

    func test_it_loads_next_page_after_loadCampaigns_and_onLoadNextPageAction_until_hasNextPage_is_false() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        var invocationCountOfLoadCampaigns = 0
        var skip: Int?
        let firstPageItems = [BlazeCampaignListItem](repeating: .fake().copy(siteID: sampleSiteID), count: 2)
        let secondPageItems = [BlazeCampaignListItem](repeating: .fake().copy(siteID: sampleSiteID), count: 1)
        stores.whenReceivingAction(ofType: BlazeAction.self) { action in
            guard case let .synchronizeCampaignsList(_, skipValue, _, onCompletion) = action else {
                return
            }
            invocationCountOfLoadCampaigns += 1
            skip = skipValue
            let campaigns = skipValue == 0 ? firstPageItems: secondPageItems
            self.insertCampaigns(campaigns)
            onCompletion(.success(skipValue == 0 ? true : false))
        }

        let viewModel = BlazeCampaignListViewModel(siteID: sampleSiteID, stores: stores, storageManager: storageManager)

        var states = [BlazeCampaignListViewModel.SyncState]()
        viewModel.$syncState
            .removeDuplicates()
            .sink { state in
                states.append(state)
            }
            .store(in: &subscriptions)

        // When
        viewModel.loadCampaigns()// Syncs first page of campaigns.
        viewModel.onLoadNextPageAction() // Syncs next page of campaigns.
        viewModel.onLoadNextPageAction() // No more data to be synced.

        // Then
        XCTAssertEqual(states, [.empty, .syncingFirstPage, .results])
        XCTAssertEqual(invocationCountOfLoadCampaigns, 2)
        XCTAssertEqual(skip, 1 * PaginationTracker.Defaults.pageSize)
    }

    // MARK: - Row view models

    func test_campaignModels_match_loaded_campaigns() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let campaign1 = BlazeCampaignListItem.fake().copy(siteID: sampleSiteID, campaignID: "9", budgetCurrency: "USD")
        let campaign2 = BlazeCampaignListItem.fake().copy(siteID: sampleSiteID, campaignID: "10", budgetCurrency: "USD")
        stores.whenReceivingAction(ofType: BlazeAction.self) { action in
            guard case let .synchronizeCampaignsList(_, _, _, onCompletion) = action else {
                return
            }
            self.insertCampaigns([campaign1, campaign2])
            onCompletion(.success(true))
        }
        let viewModel = BlazeCampaignListViewModel(siteID: sampleSiteID, stores: stores, storageManager: storageManager)

        // When
        viewModel.loadCampaigns()

        // Then
        // ensure that the items are sorted correctly by IDs
        XCTAssertEqual(viewModel.campaigns, [campaign2, campaign1])
    }

    func test_campaignModels_are_empty_when_loaded_campaigns_are_empty() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        stores.whenReceivingAction(ofType: BlazeAction.self) { action in
            guard case let .synchronizeCampaignsList(_, _, _, onCompletion) = action else {
                return
            }
            onCompletion(.success(false))
        }
        let viewModel = BlazeCampaignListViewModel(siteID: sampleSiteID, stores: stores, storageManager: storageManager)

        // When
        viewModel.loadCampaigns()

        // Then
        XCTAssertEqual(viewModel.campaigns, [])
    }

    func test_campaignModels_are_sorted_by_id() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let campaignWithSmallerID = BlazeCampaignListItem.fake().copy(siteID: sampleSiteID, campaignID: "1", budgetCurrency: "USD")
        let campaignWithLargerID = BlazeCampaignListItem.fake().copy(siteID: sampleSiteID, campaignID: "3", budgetCurrency: "USD")
        stores.whenReceivingAction(ofType: BlazeAction.self) { action in
            guard case let .synchronizeCampaignsList(_, _, _, onCompletion) = action else {
                return
            }
            let items = [campaignWithSmallerID, campaignWithLargerID]
            self.insertCampaigns(items)
            onCompletion(.success(false))
        }
        let viewModel = BlazeCampaignListViewModel(siteID: sampleSiteID, stores: stores, storageManager: storageManager)

        // When
        viewModel.loadCampaigns()

        // Then notes are first sorted by descending ID
        XCTAssertEqual(viewModel.campaigns.count, 2)
        assertEqual(viewModel.campaigns[0], campaignWithLargerID)
        assertEqual(viewModel.campaigns[1], campaignWithSmallerID)
    }

    // MARK: - `onRefreshAction`

    func test_onRefreshAction_resyncs_the_first_page() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        var invocationCountOfLoadCampaigns = 0
        var skip: Int?
        stores.whenReceivingAction(ofType: BlazeAction.self) { action in
            guard case let .synchronizeCampaignsList(_, skipValue, _, onCompletion) = action else {
                return
            }
            invocationCountOfLoadCampaigns += 1
            skip = skipValue

            onCompletion(.success(false))
        }
        let viewModel = BlazeCampaignListViewModel(siteID: sampleSiteID, stores: stores)

        // When
        waitFor { promise in
            viewModel.onRefreshAction {
                promise(())
            }
        }

        // Then
        XCTAssertEqual(skip, 0)
        XCTAssertEqual(invocationCountOfLoadCampaigns, 1)
    }

    // MARK: - shouldShowIntroView

    func test_shouldShowIntroView_is_false_when_there_are_existing_campaigns() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let campaign = BlazeCampaignListItem.fake().copy(siteID: sampleSiteID)
        let viewModel = BlazeCampaignListViewModel(siteID: sampleSiteID, stores: stores, storageManager: storageManager)

        // Confidence check
        XCTAssertFalse(viewModel.shouldShowIntroView)

        // When
        stores.whenReceivingAction(ofType: BlazeAction.self) { action in
            guard case let .synchronizeCampaignsList(_, _, _, onCompletion) = action else {
                return
            }
            self.insertCampaigns([campaign])
            onCompletion(.success(true))
        }
        viewModel.loadCampaigns()

        // Then
        XCTAssertFalse(viewModel.shouldShowIntroView)
    }

    func test_shouldShowIntroView_is_true_only_when_loading_campaigns_for_the_first_time_and_there_are_no_existing_campaigns() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = BlazeCampaignListViewModel(siteID: sampleSiteID, stores: stores, storageManager: storageManager)

        // Confidence check
        XCTAssertFalse(viewModel.shouldShowIntroView)

        // When
        stores.whenReceivingAction(ofType: BlazeAction.self) { action in
            guard case let .synchronizeCampaignsList(_, _, _, onCompletion) = action else {
                return
            }
            onCompletion(.success(true))
        }
        viewModel.loadCampaigns()

        // Then
        XCTAssertTrue(viewModel.shouldShowIntroView)

        // When
        viewModel.shouldShowIntroView = false
        viewModel.loadCampaigns()

        // Then
        XCTAssertFalse(viewModel.shouldShowIntroView)
    }

    // MARK: `selectedCampaignURL`

    func test_didSelectCampaignDetails_updates_selectedCampaignURL_correctly() {
        // Given
        let testURL = "https://example.com"
        let site = Site.fake().copy(siteID: sampleSiteID, url: testURL)
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, isWPCom: true, defaultSite: site))
        let campaign = BlazeCampaignListItem.fake().copy(siteID: sampleSiteID, campaignID: "123")
        let viewModel = BlazeCampaignListViewModel(siteID: sampleSiteID, stores: stores)

        // Confidence check
        XCTAssertNil(viewModel.selectedCampaignURL)

        // When
        viewModel.didSelectCampaignDetails(campaign)

        // Then
        XCTAssertEqual(viewModel.selectedCampaignURL?.absoluteString, "https://wordpress.com/advertising/campaigns/123/example.com?source=campaign_list")
    }

    // MARK: - Analytics

    func test_blazeEntryPointDisplayed_is_tracked_upon_view_appear() throws {
        // Given
        let viewModel = BlazeCampaignListViewModel(siteID: sampleSiteID, analytics: analytics)

        // Confidence check
        XCTAssertFalse(analyticsProvider.receivedEvents.contains("blaze_entry_point_displayed"))

        // When
        viewModel.onViewAppear()

        // Then
        XCTAssertTrue(analyticsProvider.receivedEvents.contains("blaze_entry_point_displayed"))
        let index = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == "blaze_entry_point_displayed"}))
        let eventProperties = try XCTUnwrap(analyticsProvider.receivedProperties[index])
        XCTAssertEqual(eventProperties["source"] as? String, "campaign_list")
    }

    func test_didSelectCampaignDetails_tracks_blazeCampaignDetailSelected_with_correct_source() throws {
        // Given
        let viewModel = BlazeCampaignListViewModel(siteID: sampleSiteID, analytics: analytics)

        // When
        viewModel.didSelectCampaignDetails(.fake())

        // Then
        XCTAssertTrue(analyticsProvider.receivedEvents.contains("blaze_campaign_detail_selected"))
        let index = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == "blaze_campaign_detail_selected"}))
        let eventProperties = try XCTUnwrap(analyticsProvider.receivedProperties[index])
        XCTAssertEqual(eventProperties["source"] as? String, "campaign_list")
    }

    func test_didSelectCreateCampaign_tracks_blazeEntryPointTapped() throws {
        // Given
        let viewModel = BlazeCampaignListViewModel(siteID: sampleSiteID, analytics: analytics)

        // When
        viewModel.didSelectCreateCampaign(source: .introView)

        // Then
        XCTAssertTrue(analyticsProvider.receivedEvents.contains("blaze_entry_point_tapped"))
        let index = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(of: "blaze_entry_point_tapped"))
        let properties = try XCTUnwrap(analyticsProvider.receivedProperties[index])
        XCTAssertEqual(properties["source"] as? String, "intro_view")
    }
}

private extension BlazeCampaignListViewModelTests {
    func insertCampaigns(_ readOnlyCampaigns: [BlazeCampaignListItem]) {
        readOnlyCampaigns.forEach { campaign in
            let newCampaign = storage.insertNewObject(ofType: StorageBlazeCampaignListItem.self)
            newCampaign.update(with: campaign)
        }
        storage.saveIfNeeded()
    }
}
