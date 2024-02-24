import XCTest
import Yosemite
import protocol Storage.StorageType
@testable import WooCommerce

final class BlazeTargetLanguagePickerViewModelTests: XCTestCase {

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
        stores = MockStoresManager(sessionManager: .testingInstance)
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

    func test_languages_include_all_fetchedLanguages_if_searchQuery_is_empty() {
        // Given
        let locale = "en_US"
        let english = BlazeTargetLanguage(id: "en", name: "English", locale: locale)
        let vietnamese = BlazeTargetLanguage(id: "vi", name: "Vietnamese", locale: locale)
        insertLanguage(english)
        insertLanguage(vietnamese)
        let viewModel = BlazeTargetLanguagePickerViewModel(siteID: sampleSiteID,
                                                           locale: Locale(identifier: locale),
                                                           storageManager: storageManager,
                                                           onSelection: { _ in })

        // When
        viewModel.searchQuery = ""

        // Then
        waitUntil {
            viewModel.syncState == .result(items: [english, vietnamese])
        }
    }

    func test_languages_filters_matching_languages_if_searchQuery_is_not_empty() {
        // Given
        let locale = "en_US"
        let english = BlazeTargetLanguage(id: "en", name: "English", locale: locale)
        let vietnamese = BlazeTargetLanguage(id: "vi", name: "Vietnamese", locale: locale)
        insertLanguage(english)
        insertLanguage(vietnamese)
        let viewModel = BlazeTargetLanguagePickerViewModel(siteID: sampleSiteID,
                                                           locale: Locale(identifier: locale),
                                                           storageManager: storageManager,
                                                           onSelection: { _ in })

        // When
        viewModel.searchQuery = "vi"

        // Then
        waitUntil {
            viewModel.syncState == .result(items: [vietnamese])
        }
    }

    func test_state_is_correct_when_no_cached_data_is_found() async {
        // Given
        let locale = "en_US"
        let viewModel = BlazeTargetLanguagePickerViewModel(siteID: sampleSiteID,
                                                           locale: Locale(identifier: locale),
                                                           stores: stores,
                                                           storageManager: storageManager,
                                                           onSelection: { _ in })

        // When
        stores.whenReceivingAction(ofType: BlazeAction.self) { action in
            switch action {
            case let .synchronizeTargetLanguages(_, _, onCompletion):
                // Then
                XCTAssertEqual(viewModel.syncState, .syncing)
                onCompletion(.failure(NSError(domain: "Test", code: 500)))
            default:
                break
            }
        }
        await viewModel.syncLanguages()

        // Then
        XCTAssertEqual(viewModel.syncState, .error)
    }

    func test_state_is_result_when_there_is_cached_data() async {
        // Given
        let locale = "en_US"
        let english = BlazeTargetLanguage(id: "en", name: "English", locale: locale)
        insertLanguage(english)
        let viewModel = BlazeTargetLanguagePickerViewModel(siteID: sampleSiteID,
                                                           locale: Locale(identifier: locale),
                                                           stores: stores,
                                                           storageManager: storageManager,
                                                           onSelection: { _ in })

        // When
        stores.whenReceivingAction(ofType: BlazeAction.self) { action in
            switch action {
            case let .synchronizeTargetLanguages(_, _, onCompletion):
                XCTAssertEqual(viewModel.syncState, .result(items: [english]))
                onCompletion(.failure(NSError(domain: "Test", code: 500)))
            default:
                break
            }
        }
        await viewModel.syncLanguages()

        // Then
        XCTAssertEqual(viewModel.syncState, .result(items: [english]))
    }

    func test_save_button_is_enabled_when_selectedLanguages_is_not_empty_and_syncState_is_result() {
        // Given
        let locale = "en_US"
        let english = BlazeTargetLanguage(id: "en", name: "English", locale: locale)
        insertLanguage(english)
        let viewModel = BlazeTargetLanguagePickerViewModel(siteID: sampleSiteID,
                                                           locale: Locale(identifier: locale),
                                                           stores: stores,
                                                           storageManager: storageManager,
                                                           onSelection: { _ in })
        XCTAssertEqual(viewModel.syncState, .result(items: [english]))

        // When
        viewModel.selectedLanguages = []

        // Then
        XCTAssertTrue(viewModel.shouldDisableSaveButton)

        // When
        viewModel.selectedLanguages = [english]

        // Then
        XCTAssertFalse(viewModel.shouldDisableSaveButton)
    }

    func test_save_button_is_disabled_when_syncState_is_not_result() async {
        // Given
        let locale = "en_US"
        let viewModel = BlazeTargetLanguagePickerViewModel(siteID: sampleSiteID,
                                                           locale: Locale(identifier: locale),
                                                           stores: stores,
                                                           storageManager: storageManager,
                                                           onSelection: { _ in })

        // When
        stores.whenReceivingAction(ofType: BlazeAction.self) { action in
            switch action {
            case let .synchronizeTargetLanguages(_, _, onCompletion):
                // Then
                XCTAssertTrue(viewModel.shouldDisableSaveButton)
                onCompletion(.failure(NSError(domain: "Test", code: 500)))
            default:
                break
            }
        }
        await viewModel.syncLanguages()

        // Then
        XCTAssertTrue(viewModel.shouldDisableSaveButton)
    }

    func test_confirmSelection_triggers_onSelection_correctly() {
        // Given
        let english = BlazeTargetLanguage(id: "en", name: "English", locale: "en")
        var selectedItems: Set<BlazeTargetLanguage>?
        let viewModel = BlazeTargetLanguagePickerViewModel(siteID: sampleSiteID, storageManager: storageManager, onSelection: { items in
            selectedItems = items
        })

        // When
        let expectedItems = Set([english])
        viewModel.selectedLanguages = expectedItems
        viewModel.confirmSelection()

        // Then
        XCTAssertEqual(selectedItems, expectedItems)
    }

    // MARK: Analytics

    func test_confirmSelection_tracks_event() throws {
        // Given
        let viewModel = BlazeTargetLanguagePickerViewModel(siteID: sampleSiteID,
                                                           storageManager: storageManager,
                                                           analytics: analytics,
                                                           onSelection: { _ in })

        // When
        viewModel.confirmSelection()

        // Then
        XCTAssertTrue(analyticsProvider.receivedEvents.contains("blaze_creation_edit_language_save_tapped"))
    }
}

private extension BlazeTargetLanguagePickerViewModelTests {
    func insertLanguage(_ readOnlyLanguage: BlazeTargetLanguage) {
        let newLanguage = storage.insertNewObject(ofType: StorageBlazeTargetLanguage.self)
        newLanguage.update(with: readOnlyLanguage)
        storage.saveIfNeeded()
    }
}
