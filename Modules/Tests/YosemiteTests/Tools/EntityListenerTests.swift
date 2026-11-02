import XCTest
import CoreData
import TestKit
import Yosemite
import YosemiteTestHelpers

// MARK: - EntityListener Unit Tests
//
@MainActor
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

    override func setUp() async throws {
        try await super.setUp()
        storageManager = MockStorageManager()
    }



    /// Verifies that onUpsert is called everytime the associated Storage.Entity is Updated.
    ///
    func testOnUpsertGetsCalledWheneverTargetEntityIsEffectivelyUpdated() async {
        /// Step 1: Insert
        ///
        let storageAccount = storageManager.insertSampleAccount()
        storageManager.performAndSave({ _ in }, completion: nil, on: .main)

        /// Step 2: Setup the Listener
        ///
        let listener = EntityListener(viewContext: viewContext, readOnlyEntity: storageAccount.toReadOnly())
        let updatedDisplayName = "Updated Display Name"
        let expectation = self.expectation(description: "onUpsert")

        listener.onUpsert = { updated in
            XCTAssertEqual(updated.displayName, updatedDisplayName)
            expectation.fulfill()
        }

        listener.onReplace = { _ in
            XCTFail()
        }

        /// Step 3: Update!
        ///
        storageAccount.displayName = updatedDisplayName
        storageManager.performAndSave({ _ in }, completion: nil, on: .main)

        await fulfillment(of: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that no closure is called when the associated Storage.Entity is deleted
    /// without a replacement.
    ///
    func test_no_closure_gets_called_when_target_entity_is_deleted_without_replacement() async {
        // Given
        let storageAccount = storageManager.insertSampleAccount()
        storageManager.performAndSave({ _ in }, completion: nil, on: .main)
        let listener = EntityListener(viewContext: viewContext, readOnlyEntity: storageAccount.toReadOnly())

        listener.onUpsert = { _ in
            XCTFail("A deleted entity should not be reported as upserted")
        }
        listener.onReplace = { _ in
            XCTFail("A deleted entity without replacement should not be reported as replaced")
        }

        // When
        // The listener reacts to the context's ObjectsDidChange notification: waiting for the same
        // notification proves the deletion was processed while the listener stayed silent.
        let notification = expectation(forNotification: .NSManagedObjectContextObjectsDidChange,
                                       object: viewContext)
        // Only the first notification matters, as with the observer this expectation replaces.
        notification.assertForOverFulfill = false
        viewContext.deleteObject(storageAccount)
        storageManager.performAndSave({ _ in }, completion: nil, on: .main)
        await fulfillment(of: [notification], timeout: Constants.expectationTimeout)
        // Keep the listener observing until the deletion notification has been delivered.
        withExtendedLifetime(listener) {}

        // Then
        // Neither `onUpsert` nor `onReplace` was executed (either would have failed the test above).
    }

    /// Verifies that onReplace is called when the associated Storage.Entity is deleted and
    /// re-inserted within a single save, receiving the replacement entity.
    ///
    func test_onReplace_gets_called_when_target_entity_is_deleted_and_reinserted_in_a_single_save() async {
        // Given
        let storageAccount = storageManager.insertSampleAccount()
        storageManager.performAndSave({ _ in }, completion: nil, on: .main)
        let readOnlyAccount = storageAccount.toReadOnly()
        let listener = EntityListener(viewContext: viewContext, readOnlyEntity: readOnlyAccount)

        // When
        // The entity is replaced: deleted and re-inserted within a single save.
        let replacement: Account = await waitForAsync { promise in
            listener.onReplace = { replacement in
                promise(replacement)
            }

            self.viewContext.deleteObject(storageAccount)
            let replacementAccount = self.viewContext.insertNewObject(ofType: StorageAccount.self)
            replacementAccount.update(with: readOnlyAccount)
            self.storageManager.performAndSave({ _ in }, completion: nil, on: .main)
        }

        // Then
        XCTAssertEqual(replacement.userID, readOnlyAccount.userID)
    }

    /// Verifies that onUpsert is called everytime the associated Storage.Entity is Refreshed.
    ///
    func testOnUpsertGetsCalledWheneverTheAssociatedContextRefreshesAllObjects() async {
        /// Step 1: Insert
        ///
        let storageAccount = storageManager.insertSampleAccount()
        storageManager.performAndSave({ _ in }, completion: nil, on: .main)

        /// Step 2: Setup the Listener
        ///
        let listener = EntityListener(viewContext: viewContext, readOnlyEntity: storageAccount.toReadOnly())
        let expectation = self.expectation(description: "onUpsert")

        listener.onUpsert = { _ in
            expectation.fulfill()
        }

        listener.onReplace = { _ in
            XCTFail()
        }

        /// Step 3: Refresh
        ///
        viewContext.refreshAllObjects()

        await fulfillment(of: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that onUpsert is called whenever the ReadOnly Entity is actually *inserted* into the associated Context.
    ///
    /// Normally, this scenario wouldn't happen: EntityListener *USERS* would never have access to ReadOnly instances
    /// before they're effectively persisted. *But* we're supporting this, as a safety measure.
    ///
    func testOnUpsertGetsCalledWheneverTheAssociatedEntityGetsInsertedInContext() async {
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

        listener.onReplace = { _ in
            XCTFail()
        }

        /// Step 3: Save and effectively insert into the mainMOC
        ///
        storageManager.performAndSave({ _ in }, completion: nil, on: .main)

        await fulfillment(of: [expectation], timeout: Constants.expectationTimeout)
    }
}
