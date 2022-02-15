import Combine
import XCTest
import Yosemite
@testable import WooCommerce

final class InboxViewModelTests: XCTestCase {
    private let sampleSiteID: Int64 = 322
    private var subscriptions: [AnyCancellable] = []

    override func setUp() {
        super.setUp()
        subscriptions = []
    }

    func test_state_is_empty_without_any_actions() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        var invocationCountOfLoadInboxNotes = 0
        stores.whenReceivingAction(ofType: InboxNotesAction.self) { action in
            guard case .loadAllInboxNotes = action else {
                return
            }
            invocationCountOfLoadInboxNotes += 1
        }
        let viewModel = InboxViewModel(siteID: sampleSiteID, stores: stores)

        // Then
        XCTAssertEqual(viewModel.syncState, .empty)
        XCTAssertEqual(invocationCountOfLoadInboxNotes, 0)
    }

    func test_state_is_syncingFirstPage_and_loadAllInboxNotes_is_dispatched_after_the_first_onLoadTrigger() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        var invocationCountOfLoadInboxNotes = 0
        stores.whenReceivingAction(ofType: InboxNotesAction.self) { action in
            guard case .loadAllInboxNotes = action else {
                return
            }
            invocationCountOfLoadInboxNotes += 1
        }
        let viewModel = InboxViewModel(siteID: sampleSiteID, stores: stores)

        // When
        viewModel.onLoadTrigger.send()
        let stateAfterTheFirstOnLoadTrigger = viewModel.syncState

        viewModel.onLoadTrigger.send()
        let stateAfterTheSecondOnLoadTrigger = viewModel.syncState

        // Then
        XCTAssertEqual(stateAfterTheFirstOnLoadTrigger, .syncingFirstPage)
        XCTAssertEqual(stateAfterTheSecondOnLoadTrigger, .syncingFirstPage)
        XCTAssertEqual(invocationCountOfLoadInboxNotes, 1)
    }

    func test_state_is_results_after_onLoadTrigger_with_nonempty_results() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        var invocationCountOfLoadInboxNotes = 0
        var syncPageNumber: Int?
        let note = InboxNote.fake()
        stores.whenReceivingAction(ofType: InboxNotesAction.self) { action in
            guard case let .loadAllInboxNotes(_, pageNumber, _, _, _, _, completion) = action else {
                return
            }
            invocationCountOfLoadInboxNotes += 1
            syncPageNumber = pageNumber
            completion(.success([note]))
        }
        let viewModel = InboxViewModel(siteID: sampleSiteID, stores: stores)

        var states = [InboxViewModel.SyncState]()
        viewModel.$syncState.sink { state in
            states.append(state)
        }.store(in: &subscriptions)

        // When
        viewModel.onLoadTrigger.send()

        // Then
        XCTAssertEqual(invocationCountOfLoadInboxNotes, 1)
        XCTAssertEqual(syncPageNumber, 1)
        XCTAssertEqual(states, [.empty, .syncingFirstPage, .results])
    }

    func test_state_is_back_to_empty_after_onLoadTrigger_with_empty_results() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        var invocationCountOfLoadInboxNotes = 0
        var syncPageNumber: Int?
        stores.whenReceivingAction(ofType: InboxNotesAction.self) { action in
            guard case let .loadAllInboxNotes(_, pageNumber, _, _, _, _, completion) = action else {
                return
            }
            invocationCountOfLoadInboxNotes += 1
            syncPageNumber = pageNumber
            completion(.success([]))
        }
        let viewModel = InboxViewModel(siteID: sampleSiteID, stores: stores)

        var states = [InboxViewModel.SyncState]()
        viewModel.$syncState.sink { state in
            states.append(state)
        }.store(in: &subscriptions)

        // When
        viewModel.onLoadTrigger.send()

        // Then
        XCTAssertEqual(invocationCountOfLoadInboxNotes, 1)
        XCTAssertEqual(syncPageNumber, 1)
        XCTAssertEqual(states, [.empty, .syncingFirstPage, .empty])
    }

    func test_it_loads_next_page_after_onLoadTrigger_and_onLoadNextPageAction_until_the_data_size_is_smaller_than_page_size() {
        // Given
        let pageSize: Int = 2

        let stores = MockStoresManager(sessionManager: .testingInstance)
        var invocationCountOfLoadInboxNotes = 0
        var syncPageNumber: Int?
        let firstPageNotes = [InboxNote](repeating: .fake(), count: pageSize)
        let secondPageNotes = [InboxNote](repeating: .fake(), count: pageSize - 1)
        stores.whenReceivingAction(ofType: InboxNotesAction.self) { action in
            guard case let .loadAllInboxNotes(_, pageNumber, _, _, _, _, completion) = action else {
                return
            }
            invocationCountOfLoadInboxNotes += 1
            syncPageNumber = pageNumber
            completion(.success(pageNumber == 1 ? firstPageNotes: secondPageNotes))
        }

        let viewModel = InboxViewModel(siteID: sampleSiteID, pageSize: pageSize, stores: stores)

        var states = [InboxViewModel.SyncState]()
        viewModel.$syncState.sink { state in
            states.append(state)
        }.store(in: &subscriptions)

        // When
        viewModel.onLoadTrigger.send() // Syncs `firstPageNotes` with size as page size.
        viewModel.onLoadNextPageAction() // Syncs `secondPageNotes` with size smaller than page size.
        viewModel.onLoadNextPageAction() // No more data to be synced.

        // Then
        XCTAssertEqual(states, [.empty, .syncingFirstPage, .results, .results])
        XCTAssertEqual(invocationCountOfLoadInboxNotes, 2)
        XCTAssertEqual(syncPageNumber, 2)
    }
}
