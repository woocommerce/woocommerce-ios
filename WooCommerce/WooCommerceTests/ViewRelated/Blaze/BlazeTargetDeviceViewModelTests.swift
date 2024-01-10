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

    func test_devices_contains_only_devices_matching_given_locale() async {
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
        XCTAssertEqual(viewModel.devices, [mobile])
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
        viewModel.confirmSelection(expectedItems)

        // Then
        XCTAssertEqual(selectedItems, expectedItems)
    }
}

private extension BlazeTargetDeviceViewModelTests {
    func insertDevice(_ readOnlyDevice: BlazeTargetDevice) {
        let newDevice = storage.insertNewObject(ofType: StorageBlazeTargetDevice.self)
        newDevice.update(with: readOnlyDevice)
        storage.saveIfNeeded()
    }
}
