
import XCTest
import Storage
import Networking

@testable import Yosemite

/// Proofs and documentation for **possible** concurrency issues that we may run into in the future.
///
/// Currently, every Yosemite `Store` creates their own `StorageType` for background saving.
/// For example, in `OrderStore` and `ProductStore`, we declare them like this:
///
/// ```
/// private lazy var sharedDerivedStorage: StorageType = {
///     return storageManager.newDerivedStorage()
/// }()
/// ```
///
/// The `newDerivedStorage()` method typically creates a child `StorageType`
/// (`NSManagedObjectContext`). These children:
///
/// - Have no idea they have siblings (derived `StorageType` in other `Stores`)
/// - Do not see a siblings' data until a `saveIfNeeded()` is executed on that sibling.
///
/// This can mean that if two or more derived `StorageTypes` do similar things, it may be
/// possible to upsert the same records, leading to duplicate data. For example, in `OrderStore`, we
/// upsert records like this:
///
/// ```
/// // Fetch an existing record. If it doesn't exist, create a new one.
/// let storageOrder = storage.loadOrder(orderID: readOnlyOrder.orderID)
///             ?? storage.insertNewObject(ofType: Storage.Order.self)
///
/// // Update the new or existing record with the newly fetched data from the API
/// storageOrder.update(with: readOnlyOrder)
/// ```
///
/// If by coincidence, the same operation happens **at the same time** with the same order on a
/// **different** derived `StorageType`, we could be inserting the same order twice. And because we
/// currently don't have unique key constraints, two records would be saved in Core Data.
///
/// ## Is it a Problem?
///
/// This is probably not a problem at the moment. We are careful with using a single `StorageType`
/// for every `Store`. It would be a problem if:
///
/// - We have `Store` instances that are not deallocated, still running and doing something
///   in the background while another newly created `Store` is doing the same thing.
/// - The app grows and we need to do complex cross-feature operations. For example, saving
///   Products and Product Categories simultaneously as a single transaction.
///
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

    /// Simulate what will happen if `perform()` happens at the same time but the `saveDerivedType`
    /// happens in sequence. We end up with the same record inserted twice.
    ///
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

    /// Simulate what will happen if both the `perform()` and `saveDerivedType` happens at the
    /// same time. We end up with the same record inserted twice.
    ///
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

            self.storageManager.saveDerivedType(derivedStorage: derivedStorage) {
                exp.fulfill()
            }
        }

        wait(for: [exp], timeout: Constants.expectationTimeout)

        // Then
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.OrderStatus.self), 2)
    }

    /// Simulate what will happen if `perform()` and `saveDerivedType` called under a single
    /// `perform()` block happens at the same time on two `StorageTypes`. We end up with the same
    /// record inserted twice.
    ///
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

    /// Simulate what will happen if we wait for the `perform()` and `saveDerivedType` to finish
    /// before saving the same record on a sibling `StorageType`. The record is correctly
    /// inserted only once.
    ///
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

    /// Prove that siblings will not be able to access any upserted record from a modified
    /// sibling (Sibling-X) if Sibling-X never calls `saveIfNeeded()`.
    ///
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
        // No records are accessible from siblings and the `viewStorage`
        XCTAssertEqual(secondDerivedStorage.countObjects(ofType: Storage.OrderStatus.self), 0)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.OrderStatus.self), 0)

        XCTAssertEqual(firstDerivedStorage.countObjects(ofType: Storage.OrderStatus.self), 1)
    }

    /// Prove that siblings will be able to access the upserted record from a modified sibling
    /// (Sibling-X) if Sibling-X calls `saveIfNeeded()`.
    ///
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
        // The record is accessible from siblings and `viewStorage` even if we never persisted
        // the change by calling `saveIfNeeded` on the `viewStorage`.
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
