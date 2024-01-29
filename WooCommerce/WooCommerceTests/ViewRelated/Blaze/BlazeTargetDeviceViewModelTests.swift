import XCTest
import Yosemite
import protocol Storage.StorageType
@testable import WooCommerce

@MainActor
final class BlazeTargetDeviceViewModelTests: XCTestCase {

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

    func test_result_state_contains_only_devices_matching_given_locale() {
        // Given
        let mobile = BlazeTargetDevice(id: "mobile", name: "Mobile", locale: locale.identifier)
        let mobileVi = BlazeTargetDevice(id: "mobile", name: "Mobile", locale: "vi")
        insertDevice(mobile)
        insertDevice(mobileVi)
        let viewModel = BlazeTargetDevicePickerViewModel(siteID: sampleSiteID,
                                                         locale: locale,
                                                         storageManager: storageManager,
                                                         onSelection: { _ in })

        // Then
        XCTAssertEqual(viewModel.syncState, .result(items: [mobile]))
    }

    func test_state_is_correct_when_no_cached_data_is_found() async {
        // Given
        let viewModel = BlazeTargetDevicePickerViewModel(siteID: sampleSiteID,
                                                         locale: locale,
                                                         stores: stores,
                                                         storageManager: storageManager,
                                                         onSelection: { _ in })

        // When
        stores.whenReceivingAction(ofType: BlazeAction.self) { action in
            switch action {
            case let .synchronizeTargetDevices(_, _, onCompletion):
                // Then
                XCTAssertEqual(viewModel.syncState, .syncing)
                onCompletion(.failure(NSError(domain: "Test", code: 500)))
            default:
                break
            }
        }
        await viewModel.syncDevices()

        // Then
        XCTAssertEqual(viewModel.syncState, .error)
    }

    func test_state_is_result_when_there_is_cached_data() async {
        // Given
        let mobile = BlazeTargetDevice(id: "mobile", name: "Mobile", locale: locale.identifier)
        insertDevice(mobile)
        let viewModel = BlazeTargetDevicePickerViewModel(siteID: sampleSiteID,
                                                         locale: locale,
                                                         stores: stores,
                                                         storageManager: storageManager,
                                                         onSelection: { _ in })

        // When
        stores.whenReceivingAction(ofType: BlazeAction.self) { action in
            switch action {
            case let .synchronizeTargetDevices(_, _, onCompletion):
                XCTAssertEqual(viewModel.syncState, .result(items: [mobile]))
                onCompletion(.failure(NSError(domain: "Test", code: 500)))
            default:
                break
            }
        }
        await viewModel.syncDevices()

        // Then
        XCTAssertEqual(viewModel.syncState, .result(items: [mobile]))
    }

    func test_save_button_is_enabled_when_selectedDevices_is_not_empty_and_syncState_is_result() {
        // Given
        let mobile = BlazeTargetDevice(id: "mobile", name: "Mobile", locale: locale.identifier)
        insertDevice(mobile)
        let viewModel = BlazeTargetDevicePickerViewModel(siteID: sampleSiteID,
                                                         locale: locale,
                                                         storageManager: storageManager,
                                                         onSelection: { _ in })
        XCTAssertEqual(viewModel.syncState, .result(items: [mobile]))

        // When
        viewModel.selectedDevices = []

        // Then
        XCTAssertTrue(viewModel.shouldDisableSaveButton)

        // When
        viewModel.selectedDevices = [mobile]

        // Then
        XCTAssertFalse(viewModel.shouldDisableSaveButton)
    }

    func test_save_button_is_disabled_when_syncState_is_not_result() async {
        // Given
        let viewModel = BlazeTargetDevicePickerViewModel(siteID: sampleSiteID,
                                                         locale: locale,
                                                         stores: stores,
                                                         storageManager: storageManager,
                                                         onSelection: { _ in })

        // When
        stores.whenReceivingAction(ofType: BlazeAction.self) { action in
            switch action {
            case let .synchronizeTargetDevices(_, _, onCompletion):
                // Then
                XCTAssertTrue(viewModel.shouldDisableSaveButton)
                onCompletion(.failure(NSError(domain: "Test", code: 500)))
            default:
                break
            }
        }
        await viewModel.syncDevices()

        // Then
        XCTAssertTrue(viewModel.shouldDisableSaveButton)
    }

    func test_confirmSelection_triggers_onSelection_correctly() {
        // Given
        let mobile = BlazeTargetDevice(id: "mobile", name: "Mobile", locale: locale.identifier)
        var selectedItems: Set<BlazeTargetDevice>?
        let viewModel = BlazeTargetDevicePickerViewModel(siteID: sampleSiteID,
                                                         locale: locale,
                                                         storageManager: storageManager,
                                                         onSelection: { items in
            selectedItems = items
        })

        // When
        let expectedItems = Set([mobile])
        viewModel.selectedDevices = expectedItems
        viewModel.confirmSelection()

        // Then
        XCTAssertEqual(selectedItems, expectedItems)
    }

    // MARK: Analytics

    func test_confirmSelection_tracks_event() throws {
        // Given
        let viewModel = BlazeTargetDevicePickerViewModel(siteID: sampleSiteID,
                                                         locale: locale,
                                                         storageManager: storageManager,
                                                         analytics: analytics,
                                                         onSelection: { _ in })

        // When
        viewModel.confirmSelection()

        // Then
        XCTAssertTrue(analyticsProvider.receivedEvents.contains("blaze_creation_edit_device_save_tapped"))
    }
}

private extension BlazeTargetDeviceViewModelTests {
    func insertDevice(_ readOnlyDevice: BlazeTargetDevice) {
        let newDevice = storage.insertNewObject(ofType: StorageBlazeTargetDevice.self)
        newDevice.update(with: readOnlyDevice)
        storage.saveIfNeeded()
    }
}
