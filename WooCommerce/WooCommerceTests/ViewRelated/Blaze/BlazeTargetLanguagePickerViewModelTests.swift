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

    func test_languages_include_all_fetchedLanguages_if_searchQuery_is_empty() {
        // Given
        let english = BlazeTargetLanguage(id: "en", name: "English", locale: "en")
        let vietnamese = BlazeTargetLanguage(id: "vi", name: "Vietnamese", locale: "en")
        insertLanguage(english)
        insertLanguage(vietnamese)
        let viewModel = BlazeTargetLanguagePickerViewModel(siteID: sampleSiteID, storageManager: storageManager, onSelection: { _ in })

        // When
        viewModel.searchQuery = ""

        // Then
        waitUntil {
            viewModel.languages == [english, vietnamese]
        }
    }

    func test_languages_filters_matching_languages_if_searchQuery_is_empty() {
        // Given
        let english = BlazeTargetLanguage(id: "en", name: "English", locale: "en")
        let vietnamese = BlazeTargetLanguage(id: "vi", name: "Vietnamese", locale: "en")
        insertLanguage(english)
        insertLanguage(vietnamese)
        let viewModel = BlazeTargetLanguagePickerViewModel(siteID: sampleSiteID, storageManager: storageManager, onSelection: { _ in })

        // When
        viewModel.searchQuery = "vi"

        // Then
        waitUntil {
            viewModel.languages == [vietnamese]
        }
    }

    func test_confirmSelection_triggers_onSelection_correctly() {
        // Given
        let english = BlazeTargetLanguage(id: "en", name: "English", locale: "en")
        let vietnamese = BlazeTargetLanguage(id: "vi", name: "Vietnamese", locale: "en")
        var selectedItems: Set<BlazeTargetLanguage>?
        let viewModel = BlazeTargetLanguagePickerViewModel(siteID: sampleSiteID, storageManager: storageManager, onSelection: { items in
            selectedItems = items
        })

        // When
        let expectedItems = Set([english])
        viewModel.confirmSelection(expectedItems)

        // Then
        XCTAssertEqual(selectedItems, expectedItems)
    }
}

private extension BlazeTargetLanguagePickerViewModelTests {
    func insertLanguage(_ readOnlyLanguage: BlazeTargetLanguage) {
        let newLanguage = storage.insertNewObject(ofType: StorageBlazeTargetLanguage.self)
        newLanguage.update(with: readOnlyLanguage)
        storage.saveIfNeeded()
    }
}
