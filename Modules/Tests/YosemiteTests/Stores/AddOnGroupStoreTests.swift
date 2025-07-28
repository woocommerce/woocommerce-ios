import XCTest
import Fakes

@testable import Yosemite
@testable import Networking
@testable import Storage

final class AddOnGroupStoreTests: XCTestCase {
    /// Mock Dispatcher
    ///
    private var dispatcher: Dispatcher!

    /// Mock Storage: InMemory
    ///
    private var storageManager: MockStorageManager!

    /// Mock Network: Allows us to inject predefined responses!
    ///
    private var network: MockNetwork!

    /// Convenience Property: Returns the StorageType associated with the main thread.
    ///
    private var viewStorage: StorageType {
        return storageManager.viewStorage
    }

    /// Testing SiteID
    ///
    private let sampleSiteID: Int64 = 123

    override func setUp() {
        super.setUp()
        dispatcher = Dispatcher()
        storageManager = MockStorageManager()
        network = MockNetwork()
    }

    func test_syncAddOnGroups_stores_groups_correctly() throws {
        // Given
        network.simulateResponse(requestUrlSuffix: "product-add-ons", filename: "add-on-groups")
        let store = AddOnGroupStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        // When
        let result: Result<Void, Error> = waitFor { promise in
            let action = AddOnGroupAction.synchronizeAddOnGroups(siteID: self.sampleSiteID) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(viewStorage.countObjects(ofType: StorageAddOnGroup.self), 2) // 2 groups in the "add-on-groups" json
        XCTAssertEqual(viewStorage.countObjects(ofType: StorageProductAddOn.self), 3) // 2 add-ons in the 1st group and 1 add-on in the 2nd group
        XCTAssertEqual(viewStorage.countObjects(ofType: StorageProductAddOnOption.self), 6) // 2 options in the 1st add-on, 1 in the 2nd, and 3 in the 3rd
    }

    func test_syncAddOnGroups_deletes_stale_groups() throws {
        // Given
        let oldGroup = AddOnGroup.fake().copy(siteID: sampleSiteID, groupID: 123)
        let oldStoredGroup = viewStorage.insertNewObject(ofType: AddOnGroup.self)
        oldStoredGroup.update(with: oldGroup)
        XCTAssertEqual(viewStorage.countObjects(ofType: StorageAddOnGroup.self), 1)

        network.simulateResponse(requestUrlSuffix: "product-add-ons", filename: "add-on-groups")
        let store = AddOnGroupStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        // When
        let result: Result<Void, Error> = waitFor { promise in
            let action = AddOnGroupAction.synchronizeAddOnGroups(siteID: self.sampleSiteID) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(viewStorage.countObjects(ofType: StorageAddOnGroup.self), 2) // 2 groups in the "add-on-groups" json
        XCTAssertNil(viewStorage.loadAddOnGroup(siteID: oldGroup.siteID, groupID: oldGroup.groupID)) // Stored old group
    }
}
