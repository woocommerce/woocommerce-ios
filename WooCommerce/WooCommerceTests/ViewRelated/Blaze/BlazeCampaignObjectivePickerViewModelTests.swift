import XCTest
import Yosemite
import protocol Storage.StorageType
@testable import WooCommerce

final class BlazeCampaignObjectivePickerViewModelTests: XCTestCase {

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

    func test_fetchedData_contains_only_objectives_matching_given_locale() {
        // Given
        let sales = BlazeCampaignObjective(id: "sales", title: "Sales", description: "", suitableForDescription: "", locale: locale.identifier)
        let salesVi = BlazeCampaignObjective(id: "sales", title: "Sales", description: "", suitableForDescription: "", locale: "vi")
        insertObjective(sales)
        insertObjective(salesVi)
        let viewModel = BlazeCampaignObjectivePickerViewModel(siteID: sampleSiteID,
                                                              locale: locale,
                                                              storageManager: storageManager,
                                                              onSelection: { _ in })

        // Then
        XCTAssertEqual(viewModel.fetchedData, [sales])
    }

    @MainActor
    func test_state_is_correct_when_no_cached_data_is_found() async {
        // Given
        let viewModel = BlazeCampaignObjectivePickerViewModel(siteID: sampleSiteID,
                                                              locale: locale,
                                                              stores: stores,
                                                              storageManager: storageManager,
                                                              onSelection: { _ in })

        // When
        let expectedError = NSError(domain: "Test", code: 500)
        stores.whenReceivingAction(ofType: BlazeAction.self) { action in
            switch action {
            case let .synchronizeCampaignObjectives(_, _, onCompletion):
                // Then
                XCTAssertTrue(viewModel.isSyncingData)
                XCTAssertNil(viewModel.syncError)
                onCompletion(.failure(expectedError))
            default:
                break
            }
        }
        await viewModel.syncData()

        // Then
        XCTAssertEqual(viewModel.syncError as? NSError, expectedError)
        XCTAssertFalse(viewModel.isSyncingData)
    }

    @MainActor
    func test_fetchedData_is_not_empty_when_there_is_cached_data() async {
        // Given
        let sales = BlazeCampaignObjective(id: "sales", title: "Sales", description: "", suitableForDescription: "", locale: locale.identifier)
        insertObjective(sales)
        let viewModel = BlazeCampaignObjectivePickerViewModel(siteID: sampleSiteID,
                                                              locale: locale,
                                                              stores: stores,
                                                              storageManager: storageManager,
                                                              onSelection: { _ in })

        // When
        stores.whenReceivingAction(ofType: BlazeAction.self) { action in
            switch action {
            case let .synchronizeCampaignObjectives(_, _, onCompletion):
                XCTAssertEqual(viewModel.fetchedData, [sales])
                onCompletion(.failure(NSError(domain: "Test", code: 500)))
            default:
                break
            }
        }
        await viewModel.syncData()

        // Then
        XCTAssertEqual(viewModel.fetchedData, [sales])
    }

    func test_save_button_is_enabled_when_selectedObjective_is_not_empty_and_fetched_data_is_not_empty() {
        // Given
        let sales = BlazeCampaignObjective(id: "sales", title: "Sales", description: "", suitableForDescription: "", locale: locale.identifier)
        insertObjective(sales)
        let viewModel = BlazeCampaignObjectivePickerViewModel(siteID: sampleSiteID,
                                                              locale: locale,
                                                              storageManager: storageManager,
                                                              onSelection: { _ in })
        XCTAssertEqual(viewModel.fetchedData, [sales])

        // When
        viewModel.selectedObjective = nil

        // Then
        XCTAssertTrue(viewModel.shouldDisableSaveButton)

        // When
        viewModel.selectedObjective = sales

        // Then
        XCTAssertFalse(viewModel.shouldDisableSaveButton)
    }

    @MainActor
    func test_save_button_is_disabled_when_syncing_fails() async {
        // Given
        let viewModel = BlazeCampaignObjectivePickerViewModel(siteID: sampleSiteID,
                                                              locale: locale,
                                                              stores: stores,
                                                              storageManager: storageManager,
                                                              onSelection: { _ in })

        // When
        stores.whenReceivingAction(ofType: BlazeAction.self) { action in
            switch action {
            case let .synchronizeCampaignObjectives(_, _, onCompletion):
                // Then
                XCTAssertTrue(viewModel.shouldDisableSaveButton)
                onCompletion(.failure(NSError(domain: "Test", code: 500)))
            default:
                break
            }
        }
        await viewModel.syncData()

        // Then
        XCTAssertTrue(viewModel.shouldDisableSaveButton)
    }

    func test_confirmSelection_triggers_onSelection_correctly() {
        // Given
        let sales = BlazeCampaignObjective(id: "sales", title: "Sales", description: "", suitableForDescription: "", locale: locale.identifier)
        var selectedItem: BlazeCampaignObjective?
        let viewModel = BlazeCampaignObjectivePickerViewModel(siteID: sampleSiteID,
                                                              locale: locale,
                                                              storageManager: storageManager,
                                                              onSelection: { item in
            selectedItem = item
        })

        // When
        let expectedItem = sales
        viewModel.selectedObjective = expectedItem
        viewModel.confirmSelection()

        // Then
        XCTAssertEqual(selectedItem, expectedItem)
    }

    func test_confirmSelection_does_not_save_selected_objective_if_saveSelectionForFutureCampaigns_is_false() throws {
        // Given
        let uuid = UUID().uuidString
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        let viewModel = BlazeCampaignObjectivePickerViewModel(siteID: sampleSiteID,
                                                              locale: locale,
                                                              storageManager: storageManager,
                                                              userDefaults: userDefaults,
                                                              onSelection: { _ in })
        XCTAssertNil(userDefaults[.blazeSelectedCampaignObjective])

        // When
        viewModel.saveSelectionForFutureCampaigns = false
        viewModel.selectedObjective = BlazeCampaignObjective(id: "sales", title: "Sales", description: "", suitableForDescription: "", locale: locale.identifier)
        viewModel.confirmSelection()

        // Then
        XCTAssertNil(userDefaults[.blazeSelectedCampaignObjective])
    }

    func test_confirmSelection_saves_selected_objective_if_saveSelectionForFutureCampaigns_is_true() throws {
        // Given
        let uuid = UUID().uuidString
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        let viewModel = BlazeCampaignObjectivePickerViewModel(siteID: sampleSiteID,
                                                              locale: locale,
                                                              storageManager: storageManager,
                                                              userDefaults: userDefaults,
                                                              onSelection: { _ in })
        XCTAssertNil(userDefaults[.blazeSelectedCampaignObjective])

        // When
        viewModel.saveSelectionForFutureCampaigns = true
        viewModel.selectedObjective = BlazeCampaignObjective(id: "sales", title: "Sales", description: "", suitableForDescription: "", locale: locale.identifier)
        viewModel.confirmSelection()

        // Then
        XCTAssertEqual(userDefaults[.blazeSelectedCampaignObjective], ["\(sampleSiteID)": "sales"])
    }
}

private extension BlazeCampaignObjectivePickerViewModelTests {
    func insertObjective(_ readOnlyObjective: BlazeCampaignObjective) {
        let newObjective = storage.insertNewObject(ofType: StorageBlazeCampaignObjective.self)
        newObjective.update(with: readOnlyObjective)
        storage.saveIfNeeded()
    }
}
