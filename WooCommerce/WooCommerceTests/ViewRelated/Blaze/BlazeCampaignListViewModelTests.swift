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

    override func setUp() {
        super.setUp()
        storageManager = MockStorageManager()
        subscriptions = []
    }

    // MARK: - State transitions

    func test_state_is_empty_without_any_actions() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        var invocationCountOfLoadCampaigns = 0
        stores.whenReceivingAction(ofType: BlazeAction.self) { action in
            guard case .synchronizeCampaigns = action else {
                return
            }
            invocationCountOfLoadCampaigns += 1
        }
        let viewModel = BlazeCampaignListViewModel(siteID: sampleSiteID, stores: stores)

        // Then
        XCTAssertEqual(viewModel.syncState, .empty)
        XCTAssertEqual(invocationCountOfLoadCampaigns, 0)
    }

    func test_synchronizeCampaigns_is_dispatched_upon_loadCampaigns() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        var invocationCountOfLoadCampaigns = 0
        stores.whenReceivingAction(ofType: BlazeAction.self) { action in
            guard case .synchronizeCampaigns = action else {
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
        let existingCampaign = BlazeCampaign.fake().copy(siteID: sampleSiteID, campaignID: 123)
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
        var syncPageNumber: Int?
        let campaign = BlazeCampaign.fake().copy(siteID: sampleSiteID)
        stores.whenReceivingAction(ofType: BlazeAction.self) { action in
            guard case let .synchronizeCampaigns(_, pageNumber, onCompletion) = action else {
                return
            }
            syncPageNumber = pageNumber
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
        XCTAssertEqual(syncPageNumber, 1)
        XCTAssertEqual(states, [.empty, .syncingFirstPage, .results])
    }

    func test_state_is_back_to_empty_after_loadCampaigns_with_empty_results() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        var syncPageNumber: Int?
        stores.whenReceivingAction(ofType: BlazeAction.self) { action in
            guard case let .synchronizeCampaigns(_, pageNumber, onCompletion) = action else {
                return
            }
            syncPageNumber = pageNumber
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
        XCTAssertEqual(syncPageNumber, 1)
        XCTAssertEqual(states, [.empty, .syncingFirstPage, .empty])
    }

    func test_it_loads_next_page_after_loadCampaigns_and_onLoadNextPageAction_until_hasNextPage_is_false() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        var invocationCountOfLoadCampaigns = 0
        var syncPageNumber: Int?
        let firstPageItems = [BlazeCampaign](repeating: .fake().copy(siteID: sampleSiteID), count: 2)
        let secondPageItems = [BlazeCampaign](repeating: .fake().copy(siteID: sampleSiteID), count: 1)
        stores.whenReceivingAction(ofType: BlazeAction.self) { action in
            guard case let .synchronizeCampaigns(_, pageNumber, onCompletion) = action else {
                return
            }
            invocationCountOfLoadCampaigns += 1
            syncPageNumber = pageNumber
            let campaigns = pageNumber == 1 ? firstPageItems: secondPageItems
            self.insertCampaigns(campaigns)
            onCompletion(.success(pageNumber == 1 ? true : false))
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
        XCTAssertEqual(syncPageNumber, 2)
    }
}

private extension BlazeCampaignListViewModelTests {
    func insertCampaigns(_ readOnlyCampaigns: [BlazeCampaign]) {
        readOnlyCampaigns.forEach { campaign in
            let newCampaign = storage.insertNewObject(ofType: StorageBlazeCampaign.self)
            newCampaign.update(with: campaign)
        }
        storage.saveIfNeeded()
    }
}
