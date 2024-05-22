import XCTest
import CoreData
import Yosemite



// MARK: - EntityListener Unit Tests
//
class EntityListenerTests: XCTestCase {

    /// InMemory Storage!
    ///
    private var storageManager: MockStorageManager!

    /// Returns the NSMOC associated to the Main Thread
    ///
    private var viewContext: NSManagedObjectContext {
        return storageManager.persistentContainer.viewContext
    }


    // MARK: - Overridden Methods

    override func setUp() {
        super.setUp()
        storageManager = MockStorageManager()
    }



    /// Verifies that onUpsert is called everytime the associated Storage.Entity is Updated.
    ///
    func testOnUpsertGetsCalledWheneverTargetEntityIsEffectivelyUpdated() {
        /// Step 1: Insert
        ///
        let storageAccount = storageManager.insertSampleAccount()
        viewContext.saveIfNeeded()

        /// Step 2: Setup the Listener
        ///
        let listener = EntityListener(viewContext: viewContext, readOnlyEntity: storageAccount.toReadOnly())
        let updatedDisplayName = "Updated Display Name"
        let expectation = self.expectation(description: "onUpsert")

        listener.onUpsert = { updated in
            XCTAssertEqual(updated.displayName, updatedDisplayName)
            expectation.fulfill()
        }

        listener.onDelete = {
            XCTFail()
        }

        /// Step 3: Update!
        ///
        storageAccount.displayName = updatedDisplayName
        viewContext.saveIfNeeded()

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that onDelete is called everytime the associated Storage Entity is nuked.
    ///
    func testOnDeleteGetsCalledWheneverTargetEntityIsEffectivelyNuked() {
        /// Step 1: Insert
        ///
        let storageAccount = storageManager.insertSampleAccount()
        viewContext.saveIfNeeded()

        /// Step 2: Setup the Listener
        ///
        let listener = EntityListener(viewContext: viewContext, readOnlyEntity: storageAccount.toReadOnly())
        let expectation = self.expectation(description: "onDelete")

        listener.onUpsert = { updated in
            XCTFail()
        }

        listener.onDelete = {
            expectation.fulfill()
        }

        /// Step 3: Nuke!
        ///
        viewContext.deleteObject(storageAccount)
        viewContext.saveIfNeeded()

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that onUpsert is called everytime the associated Storage.Entity is Refreshed.
    ///
    func testOnUpsertGetsCalledWheneverTheAssociatedContextRefreshesAllObjects() {
        /// Step 1: Insert
        ///
        let storageAccount = storageManager.insertSampleAccount()
        viewContext.saveIfNeeded()

        /// Step 2: Setup the Listener
        ///
        let listener = EntityListener(viewContext: viewContext, readOnlyEntity: storageAccount.toReadOnly())
        let expectation = self.expectation(description: "onUpsert")

        listener.onUpsert = { updated in
            expectation.fulfill()
        }

        listener.onDelete = {
            XCTFail()
        }

        /// Step 3: Refresh
        ///
        viewContext.refreshAllObjects()

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that onUpsert is called whenever the ReadOnly Entity is actually *inserted* into the associated Context.
    ///
    /// Normally, this scenario wouldn't happen: EntityListener *USERS* would never have access to ReadOnly instances
    /// before they're effectively persisted. *But* we're supporting this, as a safety measure.
    ///
    func testOnUpsertGetsCalledWheneverTheAssociatedEntityGetsInsertedInContext() {
        /// Step 1: Insert
        ///
        let storageAccount = storageManager.insertSampleAccount()

        /// Step 2: Setup the Listener
        ///
        let listener = EntityListener(viewContext: viewContext, readOnlyEntity: storageAccount.toReadOnly())
        let expectation = self.expectation(description: "onUpsert")

        listener.onUpsert = { updated in
            expectation.fulfill()
        }

        listener.onDelete = {
            XCTFail()
        }

        /// Step 3: Save and effectively insert into the mainMOC
        ///
        viewContext.saveIfNeeded()

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }


    /// Tests the thread safety of the readOnlyEntity property.
    ///
    func test_thread_safety_for_readOnlyEntity() {
        // Given: A sample storage account is inserted and saved.
        let storageAccount = storageManager.insertSampleAccount()
        viewContext.saveIfNeeded()

        // And: An EntityListener is set up with the readOnly entity being the inserted storage account.
        let listener = EntityListener(viewContext: viewContext, readOnlyEntity: storageAccount.toReadOnly())

        // And: Expectations for multiple threads.
        let expectation1 = self.expectation(description: "Thread 1")
        let expectation2 = self.expectation(description: "Thread 2")
        let expectation3 = self.expectation(description: "Thread 3")

        // When: Multiple threads access the readOnlyEntity property concurrently.
        DispatchQueue.global().async {
            for _ in 0..<1000 {
                _ = listener.readOnlyEntity
            }
            expectation1.fulfill()
        }

        DispatchQueue.global().async {
            for _ in 0..<1000 {
                _ = listener.readOnlyEntity
            }
            expectation2.fulfill()
        }

        DispatchQueue.global().async {
            for _ in 0..<1000 {
                _ = listener.readOnlyEntity
            }
            expectation3.fulfill()
        }

        // Then
        wait(for: [expectation1, expectation2, expectation3], timeout: 0.1)
    }

}
