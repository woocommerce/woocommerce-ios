import XCTest
import CoreData
import Yosemite
import YosemiteTestHelpers

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

        listener.onUpsert = { _ in
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

    /// Verifies that onReplace (and not onDelete) is called when the associated Storage.Entity is
    /// deleted and re-inserted within a single save, receiving the replacement entity.
    ///
    func test_onReplace_gets_called_when_target_entity_is_deleted_and_reinserted_in_a_single_save() {
        /// Step 1: Insert
        ///
        let storageAccount = storageManager.insertSampleAccount()
        viewContext.saveIfNeeded()
        let readOnlyAccount = storageAccount.toReadOnly()

        /// Step 2: Setup the Listener
        ///
        let listener = EntityListener(viewContext: viewContext, readOnlyEntity: readOnlyAccount)
        let expectation = self.expectation(description: "onReplace")

        listener.onDelete = {
            XCTFail("A replaced entity should not be reported as deleted")
        }

        listener.onReplace = { replacement in
            XCTAssertEqual(replacement.userID, readOnlyAccount.userID)
            expectation.fulfill()
        }

        /// Step 3: Replace (delete + re-insert within a single save)
        ///
        viewContext.deleteObject(storageAccount)
        let replacementAccount = viewContext.insertNewObject(ofType: StorageAccount.self)
        replacementAccount.update(with: readOnlyAccount)
        viewContext.saveIfNeeded()

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that onReplace is not called when the associated Storage.Entity is deleted
    /// without a replacement.
    ///
    func test_onReplace_does_not_get_called_when_target_entity_is_deleted_without_replacement() {
        /// Step 1: Insert
        ///
        let storageAccount = storageManager.insertSampleAccount()
        viewContext.saveIfNeeded()

        /// Step 2: Setup the Listener
        ///
        let listener = EntityListener(viewContext: viewContext, readOnlyEntity: storageAccount.toReadOnly())
        let expectation = self.expectation(description: "onDelete")

        listener.onReplace = { _ in
            XCTFail("A deleted entity without replacement should not be reported as replaced")
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

        listener.onUpsert = { _ in
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

        listener.onUpsert = { _ in
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
}
