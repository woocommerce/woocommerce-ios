
import XCTest
import Storage
import Networking

@testable import Yosemite

final class StorageManagerConcurrencyTests: XCTestCase {

    private var storageManager: StorageManagerType!

    private var viewStorage: StorageType {
        storageManager.viewStorage
    }

    override func setUp() {
        super.setUp()
        // Using the real Sqlite-based StorageManagerType to be closer to the production operations
        storageManager = CoreDataManager(name: "WooCommerce")
        storageManager.reset()
    }

    override func tearDown() {
        storageManager.reset()
        storageManager = nil
        super.tearDown()
    }

    func testTheConcurrencyArchitectureCanAllowSavingOfDuplicates() {
        // Given
        let firstDerivedStorage = storageManager.newDerivedStorage()
        let secondDerivedStorage = storageManager.newDerivedStorage()

        let orderStatus = Networking.OrderStatus(name: "In Space", siteID: 1_998, slug: "in-space", total: 9)

        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.OrderStatus.self), 0)

        // When
        [firstDerivedStorage, secondDerivedStorage].forEach { derivedContext in
            derivedContext.perform {
                let storageOrderStatus = derivedContext.loadOrderStatus(siteID: orderStatus.siteID, slug: orderStatus.slug) ??
                    derivedContext.insertNewObject(ofType: Storage.OrderStatus.self)
                storageOrderStatus.update(with: orderStatus)
            }
        }

        [firstDerivedStorage, secondDerivedStorage].forEach { derivedContext in
            waitForExpectation { exp in
                storageManager.saveDerivedType(derivedStorage: derivedContext) {
                    exp.fulfill()
                }
            }
        }

        // Then
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.OrderStatus.self), 2)
    }
}
