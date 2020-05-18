
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
        // Use the Sqlite-based StorageManagerType to be closer to the production operations
        storageManager = CoreDataManager(name: "WooCommerce")
        storageManager.reset()
    }

    override func tearDown() {
        storageManager.reset()
        storageManager = nil
        super.tearDown()
    }

    func testWhenSequentiallySavingItCanAllowSavingOfDuplicates() {
        // Given
        let firstDerivedStorage = storageManager.newDerivedStorage()
        let secondDerivedStorage = storageManager.newDerivedStorage()

        let orderStatus = Networking.OrderStatus(name: "In Space", siteID: 1_998, slug: "in-space", total: 9)

        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.OrderStatus.self), 0)

        // When
        [firstDerivedStorage, secondDerivedStorage].forEach { derivedStorage in
            derivedStorage.perform {
                self.upsert(orderStatus: orderStatus, using: derivedStorage)
            }
        }

        [firstDerivedStorage, secondDerivedStorage].forEach { derivedStorage in
            waitForExpectation { exp in
                storageManager.saveDerivedType(derivedStorage: derivedStorage) {
                    exp.fulfill()
                }
            }
        }

        // Then
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.OrderStatus.self), 2)
    }

    func testWhenConcurrentlySavingItCanAllowSavingOfDuplicates() {
        // Given
        let firstDerivedStorage = storageManager.newDerivedStorage()
        let secondDerivedStorage = storageManager.newDerivedStorage()

        let orderStatus = Networking.OrderStatus(name: "In Space", siteID: 1_998, slug: "in-space", total: 9)

        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.OrderStatus.self), 0)

        // When
        let exp = expectation(description: "concurrent-saving")
        exp.expectedFulfillmentCount = 2

        [firstDerivedStorage, secondDerivedStorage].forEach { derivedStorage in
            derivedStorage.perform {
                self.upsert(orderStatus: orderStatus, using: derivedStorage)
            }

            derivedStorage.perform {
                self.storageManager.saveDerivedType(derivedStorage: derivedStorage) {
                    exp.fulfill()
                }
            }
        }

        wait(for: [exp], timeout: Constants.expectationTimeout)

        // Then
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.OrderStatus.self), 2)
    }

    func testWhenConcurrentlySavingUsingASinglePerformBlockItCanAllowSavingOfDuplicates() {
        // Given
        let firstDerivedStorage = storageManager.newDerivedStorage()
        let secondDerivedStorage = storageManager.newDerivedStorage()

        let orderStatus = Networking.OrderStatus(name: "In Space", siteID: 1_998, slug: "in-space", total: 9)

        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.OrderStatus.self), 0)

        // When
        let exp = expectation(description: "concurrent-saving")
        exp.expectedFulfillmentCount = 2

        [firstDerivedStorage, secondDerivedStorage].forEach { derivedStorage in
            derivedStorage.perform {
                self.upsert(orderStatus: orderStatus, using: derivedStorage)

                self.storageManager.saveDerivedType(derivedStorage: derivedStorage) {
                    exp.fulfill()
                }
            }
        }

        wait(for: [exp], timeout: Constants.expectationTimeout)

        // Then
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.OrderStatus.self), 2)
    }

    func testWhenSequentiallySavingAndWaitingThenNoDuplicatesAreSaved() {
        // Given
        let firstDerivedStorage = storageManager.newDerivedStorage()
        let secondDerivedStorage = storageManager.newDerivedStorage()

        let orderStatus = Networking.OrderStatus(name: "In Space", siteID: 1_998, slug: "in-space", total: 9)

        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.OrderStatus.self), 0)

        // When
        [firstDerivedStorage, secondDerivedStorage].forEach { derivedStorage in
            waitForExpectation { exp in
                derivedStorage.perform {
                    self.upsert(orderStatus: orderStatus, using: derivedStorage)

                    self.storageManager.saveDerivedType(derivedStorage: derivedStorage) {
                        exp.fulfill()
                    }
                }
            }
        }

        // Then
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.OrderStatus.self), 1)
    }

    func testWhenNotSavingThenADerivedStorageWillNotShareDataToItsSiblings() {
        // Given
        let firstDerivedStorage = storageManager.newDerivedStorage()
        let secondDerivedStorage = storageManager.newDerivedStorage()

        let orderStatus = Networking.OrderStatus(name: "In Space", siteID: 1_998, slug: "in-space", total: 9)

        XCTAssertEqual(firstDerivedStorage.countObjects(ofType: Storage.OrderStatus.self), 0)

        // When
        waitForExpectation { exp in
            firstDerivedStorage.perform {
                self.upsert(orderStatus: orderStatus, using: firstDerivedStorage)

                exp.fulfill()
            }
        }

        // Then
        XCTAssertEqual(secondDerivedStorage.countObjects(ofType: Storage.OrderStatus.self), 0)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.OrderStatus.self), 0)

        XCTAssertEqual(firstDerivedStorage.countObjects(ofType: Storage.OrderStatus.self), 1)
    }

    func testWhenSavedThenADerivedStorageWillShareDataToItsSiblings() {
        // Given
        let firstDerivedStorage = storageManager.newDerivedStorage()
        let secondDerivedStorage = storageManager.newDerivedStorage()

        let orderStatus = Networking.OrderStatus(name: "In Space", siteID: 1_998, slug: "in-space", total: 9)

        XCTAssertEqual(firstDerivedStorage.countObjects(ofType: Storage.OrderStatus.self), 0)

        // When
        waitForExpectation { exp in
            firstDerivedStorage.perform {
                self.upsert(orderStatus: orderStatus, using: firstDerivedStorage)

                firstDerivedStorage.saveIfNeeded()

                exp.fulfill()
            }
        }

        // Then
        XCTAssertEqual(secondDerivedStorage.countObjects(ofType: Storage.OrderStatus.self), 1)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.OrderStatus.self), 1)

        XCTAssertEqual(firstDerivedStorage.countObjects(ofType: Storage.OrderStatus.self), 1)
    }

}

// MARK: - Utils

private extension StorageManagerConcurrencyTests {
    func upsert(orderStatus: Networking.OrderStatus, using storage: StorageType) {
        let storageOrderStatus = storage.loadOrderStatus(siteID: orderStatus.siteID, slug: orderStatus.slug) ??
            storage.insertNewObject(ofType: Storage.OrderStatus.self)
        storageOrderStatus.update(with: orderStatus)
    }
}

