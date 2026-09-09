import XCTest
import CoreData
import TestKit
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

        listener.onReplace = { _ in
            XCTFail()
        }

        /// Step 3: Update!
        ///
        storageAccount.displayName = updatedDisplayName
        viewContext.saveIfNeeded()

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that no closure is called when the associated Storage.Entity is deleted
    /// without a replacement.
    ///
    func test_no_closure_gets_called_when_target_entity_is_deleted_without_replacement() {
        // Given
        let storageAccount = storageManager.insertSampleAccount()
        viewContext.saveIfNeeded()
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
        let _: Void = waitFor { promise in
            var token: NSObjectProtocol?
            token = NotificationCenter.default.addObserver(forName: .NSManagedObjectContextObjectsDidChange,
                                                           object: self.viewContext,
                                                           queue: nil) { _ in
                if let token {
                    NotificationCenter.default.removeObserver(token)
                }
                token = nil
                promise(())
            }

            self.viewContext.deleteObject(storageAccount)
            self.viewContext.saveIfNeeded()
        }

        // Then
        // Neither `onUpsert` nor `onReplace` was executed (either would have failed the test above).
    }

    /// Verifies that onReplace is called when the associated Storage.Entity is deleted and
    /// re-inserted within a single save, receiving the replacement entity.
    ///
    func test_onReplace_gets_called_when_target_entity_is_deleted_and_reinserted_in_a_single_save() {
        // Given
        let storageAccount = storageManager.insertSampleAccount()
        viewContext.saveIfNeeded()
        let readOnlyAccount = storageAccount.toReadOnly()
        let listener = EntityListener(viewContext: viewContext, readOnlyEntity: readOnlyAccount)

        // When
        // The entity is replaced: deleted and re-inserted within a single save.
        let replacement: Account = waitFor { promise in
            listener.onReplace = { replacement in
                promise(replacement)
            }

            self.viewContext.deleteObject(storageAccount)
            let replacementAccount = self.viewContext.insertNewObject(ofType: StorageAccount.self)
            replacementAccount.update(with: readOnlyAccount)
            self.viewContext.saveIfNeeded()
        }

        // Then
        XCTAssertEqual(replacement.userID, readOnlyAccount.userID)
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

        listener.onReplace = { _ in
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

        listener.onReplace = { _ in
            XCTFail()
        }

        /// Step 3: Save and effectively insert into the mainMOC
        ///
        viewContext.saveIfNeeded()

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }
}
