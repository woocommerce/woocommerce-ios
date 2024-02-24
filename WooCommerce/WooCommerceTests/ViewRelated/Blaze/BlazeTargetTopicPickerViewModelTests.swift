import XCTest
import Yosemite
import protocol Storage.StorageType
@testable import WooCommerce

@MainActor
final class BlazeTargetTopicPickerViewModelTests: XCTestCase {

    private let sampleSiteID: Int64 = 122
    private let locale = Locale(identifier: "en_US")

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
        stores = MockStoresManager(sessionManager: .makeForTesting())
        storageManager = MockStorageManager()
        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
    }

    override func tearDown() {
        analyticsProvider = nil
        analytics = nil
        storageManager = nil
        stores = nil
        super.tearDown()
    }

    func test_list_includes_all_fetchedTopics_if_searchQuery_is_empty() {
        // Given
        let topic1 = BlazeTargetTopic(id: "test", name: "Test", locale: locale.identifier)
        let topic2 = BlazeTargetTopic(id: "test-2", name: "Test 2", locale: locale.identifier)
        insertTopic(topic1)
        insertTopic(topic2)
        let viewModel = BlazeTargetTopicPickerViewModel(siteID: sampleSiteID,
                                                        locale: locale,
                                                        storageManager: storageManager,
                                                        onSelection: { _ in })

        // When
        viewModel.searchQuery = ""

        // Then
        waitUntil {
            viewModel.syncState == .result(items: [topic1, topic2])
        }
    }

    func test_languages_filters_matching_languages_if_searchQuery_is_not_empty() {
        // Given
        let topic1 = BlazeTargetTopic(id: "test", name: "Test", locale: locale.identifier)
        let topic2 = BlazeTargetTopic(id: "test-2", name: "Test 2", locale: locale.identifier)
        insertTopic(topic1)
        insertTopic(topic2)
        let viewModel = BlazeTargetTopicPickerViewModel(siteID: sampleSiteID,
                                                        locale: locale,
                                                        storageManager: storageManager,
                                                        onSelection: { _ in })

        // When
        viewModel.searchQuery = "2"

        // Then
        waitUntil {
            viewModel.syncState == .result(items: [topic2])
        }
    }

    func test_result_state_contains_only_topics_matching_given_locale() {
        // Given
        let topic = BlazeTargetTopic(id: "test", name: "Test", locale: locale.identifier)
        let topicVi = BlazeTargetTopic(id: "test", name: "Test", locale: "vi")
        insertTopic(topic)
        insertTopic(topicVi)
        let viewModel = BlazeTargetTopicPickerViewModel(siteID: sampleSiteID,
                                                        locale: locale,
                                                        storageManager: storageManager,
                                                        onSelection: { _ in })

        // Then
        XCTAssertEqual(viewModel.syncState, .result(items: [topic]))
    }

    func test_state_is_correct_when_no_cached_data_is_found() async {
        // Given
        let viewModel = BlazeTargetTopicPickerViewModel(siteID: sampleSiteID,
                                                        locale: locale,
                                                        stores: stores,
                                                        storageManager: storageManager,
                                                        onSelection: { _ in })

        // When
        stores.whenReceivingAction(ofType: BlazeAction.self) { action in
            switch action {
            case let .synchronizeTargetTopics(_, _, onCompletion):
                // Then
                XCTAssertEqual(viewModel.syncState, .syncing)
                onCompletion(.failure(NSError(domain: "Test", code: 500)))
            default:
                break
            }
        }
        await viewModel.syncTopics()

        // Then
        XCTAssertEqual(viewModel.syncState, .error)
    }

    func test_state_is_result_when_there_is_cached_data() async {
        // Given
        let topic = BlazeTargetTopic(id: "test", name: "Test", locale: locale.identifier)
        insertTopic(topic)
        let viewModel = BlazeTargetTopicPickerViewModel(siteID: sampleSiteID,
                                                        locale: locale,
                                                        stores: stores,
                                                        storageManager: storageManager,
                                                        onSelection: { _ in })

        // When
        stores.whenReceivingAction(ofType: BlazeAction.self) { action in
            switch action {
            case let .synchronizeTargetTopics(_, _, onCompletion):
                XCTAssertEqual(viewModel.syncState, .result(items: [topic]))
                onCompletion(.failure(NSError(domain: "Test", code: 500)))
            default:
                break
            }
        }
        await viewModel.syncTopics()

        // Then
        XCTAssertEqual(viewModel.syncState, .result(items: [topic]))
    }

    func test_save_button_is_enabled_when_selectedTopics_is_not_empty_and_syncState_is_result() {
        // Given
        let topic = BlazeTargetTopic(id: "test", name: "Test", locale: locale.identifier)
        insertTopic(topic)
        let viewModel = BlazeTargetTopicPickerViewModel(siteID: sampleSiteID,
                                                        locale: locale,
                                                        stores: stores,
                                                        storageManager: storageManager,
                                                        onSelection: { _ in })
        XCTAssertEqual(viewModel.syncState, .result(items: [topic]))

        // When
        viewModel.selectedTopics = []

        // Then
        XCTAssertTrue(viewModel.shouldDisableSaveButton)

        // When
        viewModel.selectedTopics = [topic]

        // Then
        XCTAssertFalse(viewModel.shouldDisableSaveButton)
    }

    func test_save_button_is_disabled_when_syncState_is_not_result() async {
        // Given
        let viewModel = BlazeTargetTopicPickerViewModel(siteID: sampleSiteID,
                                                        locale: locale,
                                                        stores: stores,
                                                        storageManager: storageManager,
                                                        onSelection: { _ in })

        // When
        stores.whenReceivingAction(ofType: BlazeAction.self) { action in
            switch action {
            case let .synchronizeTargetTopics(_, _, onCompletion):
                // Then
                XCTAssertTrue(viewModel.shouldDisableSaveButton)
                onCompletion(.failure(NSError(domain: "Test", code: 500)))
            default:
                break
            }
        }
        await viewModel.syncTopics()

        // Then
        XCTAssertTrue(viewModel.shouldDisableSaveButton)
    }

    func test_confirmSelection_triggers_onSelection_correctly() {
        // Given
        let topic = BlazeTargetTopic(id: "test", name: "Test", locale: "en")
        var selectedItems: Set<BlazeTargetTopic>?
        let viewModel = BlazeTargetTopicPickerViewModel(siteID: sampleSiteID,
                                                        locale: locale,
                                                        storageManager: storageManager,
                                                        onSelection: { items in
            selectedItems = items
        })

        // When
        let expectedItems = Set([topic])
        viewModel.selectedTopics = expectedItems
        viewModel.confirmSelection()

        // Then
        XCTAssertEqual(selectedItems, expectedItems)
    }

    // MARK: Analytics

    func test_confirmSelection_tracks_event() throws {
        // Given
        let viewModel = BlazeTargetTopicPickerViewModel(siteID: sampleSiteID,
                                                        locale: locale,
                                                        storageManager: storageManager,
                                                        analytics: analytics,
                                                        onSelection: { _ in })

        // When
        viewModel.confirmSelection()

        // Then
        XCTAssertTrue(analyticsProvider.receivedEvents.contains("blaze_creation_edit_interest_save_tapped"))
    }
}

private extension BlazeTargetTopicPickerViewModelTests {
    func insertTopic(_ readOnlyTopic: BlazeTargetTopic) {
        let newTopic = storage.insertNewObject(ofType: StorageBlazeTargetTopic.self)
        newTopic.update(with: readOnlyTopic)
        storage.saveIfNeeded()
    }
}
