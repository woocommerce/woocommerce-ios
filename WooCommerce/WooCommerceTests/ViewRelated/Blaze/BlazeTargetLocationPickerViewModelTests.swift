import Combine
import XCTest
import Yosemite
@testable import WooCommerce

final class BlazeTargetLocationPickerViewModelTests: XCTestCase {

    private let sampleSiteID: Int64 = 123
    private var stores: MockStoresManager!
    private var subscription: AnyCancellable?

    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: WooAnalytics!

    override func setUp() {
        super.setUp()
        stores = MockStoresManager(sessionManager: .testingInstance)
        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
    }


    override func tearDown() {
        analyticsProvider = nil
        analytics = nil
        stores = nil
        super.tearDown()
    }

    // MARK: - Test `selectedSearchResults`

    func test_selectedSearchResults_is_empty_if_injected_selectedLocations_is_nil() {
        // Given
        let viewModel = BlazeTargetLocationPickerViewModel(siteID: sampleSiteID, selectedLocations: nil, onCompletion: { _ in })

        // Then
        XCTAssertEqual(viewModel.selectedSearchResults, [])
    }

    func test_selectedSearchResults_is_not_empty_if_injected_selectedLocations_not_empty() {
        // Given
        let location = BlazeTargetLocation.fake()
        let viewModel = BlazeTargetLocationPickerViewModel(siteID: sampleSiteID, selectedLocations: [location], onCompletion: { _ in })

        // Then
        XCTAssertEqual(viewModel.selectedSearchResults, [location])
    }

    // MARK: - `shouldDisableSaveButton`

    func test_shouldDisableSaveButton_is_true_if_selectedLocations_is_empty() {
        // Given
        let viewModel = BlazeTargetLocationPickerViewModel(siteID: sampleSiteID, selectedLocations: nil, onCompletion: { _ in })

        // When
        viewModel.selectedLocations = []

        // Then
        XCTAssertTrue(viewModel.shouldDisableSaveButton)
    }

    func test_shouldDisableSaveButton_is_false_if_selectedLocations_is_not_empty() {
        // Given
        let viewModel = BlazeTargetLocationPickerViewModel(siteID: sampleSiteID, selectedLocations: nil, onCompletion: { _ in })

        // When
        viewModel.selectedLocations = [BlazeTargetLocation.fake()]

        // Then
        XCTAssertFalse(viewModel.shouldDisableSaveButton)
    }

    // MARK: - Test `emptyViewImage` and `emptyViewMessage`

    func test_emptyViewImage_is_searchImage_if_searchQuery_length_is_less_than_3_and_vice_versa() {
        // Given
        let viewModel = BlazeTargetLocationPickerViewModel(siteID: sampleSiteID, selectedLocations: nil, onCompletion: { _ in })

        // Then
        XCTAssertEqual(viewModel.searchQuery, "")
        XCTAssertEqual(viewModel.emptyViewImage, .searchImage)

        // When
        viewModel.searchQuery = "te"

        // Then
        XCTAssertEqual(viewModel.emptyViewImage, .searchImage)

        // When
        viewModel.searchQuery = "test"

        // Then
        XCTAssertEqual(viewModel.emptyViewImage, .searchNoResultImage)
    }

    func test_emptyViewMessage_is_updated_based_on_query_length() {
        // Given
        let viewModel = BlazeTargetLocationPickerViewModel(siteID: sampleSiteID, selectedLocations: nil, onCompletion: { _ in })

        // Then
        XCTAssertEqual(viewModel.searchQuery, "")
        XCTAssertEqual(viewModel.emptyViewMessage, BlazeTargetLocationPickerViewModel.Localization.searchViewHintMessage)

        // When
        viewModel.searchQuery = "te"

        // Then
        XCTAssertEqual(viewModel.emptyViewMessage, BlazeTargetLocationPickerViewModel.Localization.longerQuery)

        // When
        viewModel.searchQuery = "test"

        // Then
        XCTAssertEqual(viewModel.emptyViewMessage, BlazeTargetLocationPickerViewModel.Localization.noResult)
    }

    // MARK: - Test search states

    func test_fetchInProgress_is_updated_correctly_when_fetching_search_results() {
        // Given
        let viewModel = BlazeTargetLocationPickerViewModel(siteID: sampleSiteID, selectedLocations: nil, stores: stores, onCompletion: { _ in })
        var fetchingStates: [Bool] = []

        // When
        mockSearchLocationRequest(with: .success([]))
        subscription = viewModel.$fetchInProgress
            .sink { state in
                fetchingStates.append(state)
            }
        viewModel.searchQuery = "test"

        // Then
        waitUntil {
            fetchingStates == [false, true, false]
        }
    }

    func test_searchResults_is_updated_correctly_after_fetching_locations() {
        // Given
        let viewModel = BlazeTargetLocationPickerViewModel(siteID: sampleSiteID, selectedLocations: nil, stores: stores, onCompletion: { _ in })
        let tokyo = BlazeTargetLocation.fake().copy(id: 123, name: "Tokyo")

        // When
        mockSearchLocationRequest(with: .success([tokyo]))
        viewModel.searchQuery = "tok"

        // Then
        waitUntil {
            viewModel.searchResults == [tokyo]
        }
    }

    func test_searchResults_is_updated_correctly_after_updating_searchQuery() {
        // Given
        let viewModel = BlazeTargetLocationPickerViewModel(siteID: sampleSiteID, selectedLocations: nil, stores: stores, onCompletion: { _ in })
        let tokyo = BlazeTargetLocation.fake().copy(id: 123, name: "Tokyo")

        // When
        mockSearchLocationRequest(with: .success([tokyo]))
        viewModel.searchQuery = "tok"
        waitUntil {
            viewModel.searchResults == [tokyo]
        }
        viewModel.searchQuery = "to"

        // Then
        waitUntil {
            viewModel.searchResults == []
        }
    }

    // MARK: - addOptionFromSearchResult

    func test_addOptionFromSearchResult_updates_selectedSearchResults_and_selectedLocations_correctly() throws {
        // Given
        let viewModel = BlazeTargetLocationPickerViewModel(siteID: sampleSiteID, onCompletion: { _ in })
        let tokyo = BlazeTargetLocation.fake().copy(id: 123, name: "Tokyo")

        // When
        viewModel.addOptionFromSearchResult(tokyo)

        // Then
        XCTAssertTrue(viewModel.selectedSearchResults.contains(tokyo))
        XCTAssertTrue(try XCTUnwrap(viewModel.selectedLocations).contains(tokyo))
    }

    func test_addOptionFromSearchResult_clears_searchResult() {
        // Given
        let viewModel = BlazeTargetLocationPickerViewModel(siteID: sampleSiteID, selectedLocations: nil, stores: stores, onCompletion: { _ in })
        let tokyo = BlazeTargetLocation.fake().copy(id: 123, name: "Tokyo")

        // When
        mockSearchLocationRequest(with: .success([tokyo]))
        viewModel.searchQuery = "tok"

        // make sure that the search results are populated from the search response.
        waitUntil {
            viewModel.searchResults == [tokyo]
        }

        viewModel.addOptionFromSearchResult(tokyo)

        // Then
        waitUntil {
            viewModel.searchResults.isEmpty
        }
    }

    // MARK: Analytics

    func test_confirmSelection_tracks_event() throws {
        // Given
        let viewModel = BlazeTargetLocationPickerViewModel(siteID: sampleSiteID,
                                                           selectedLocations: nil,
                                                           stores: stores,
                                                           analytics: analytics,
                                                           onCompletion: { _ in })

        // When
        viewModel.confirmSelection()

        // Then
        XCTAssertTrue(analyticsProvider.receivedEvents.contains("blaze_creation_edit_location_save_tapped"))
    }
}

private extension BlazeTargetLocationPickerViewModelTests {
    func mockSearchLocationRequest(with result: Result<[BlazeTargetLocation], Error>) {
        stores.whenReceivingAction(ofType: BlazeAction.self) { action in
            switch action {
            case let .fetchTargetLocations(_, _, _, onCompletion):
                onCompletion(result)
            default:
                break
            }
        }
    }
}
