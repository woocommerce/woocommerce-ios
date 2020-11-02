import XCTest
import CoreData
@testable import Storage


/// CoreDataManager Unit Tests
///
final class CoreDataManagerTests: XCTestCase {

    /// Verifies that the Store URL contains the ContextIdentifier string.
    ///
    func test_storeUrl_maps_to_sqlite_file_with_context_identifier() {
        let manager = CoreDataManager(name: "WooCommerce", crashLogger: MockCrashLogger())
        XCTAssertEqual(manager.storeURL.lastPathComponent, "WooCommerce.sqlite")
        XCTAssertEqual(manager.storeDescription.url?.lastPathComponent, "WooCommerce.sqlite")
    }

    /// Verifies that the PersistentContainer properly loads the sqlite database.
    ///
    func test_persistentContainer_loads_expected_data_model_and_sqlite_database() throws {
        // Given
        let modelsInventory = try ManagedObjectModelsInventory.from(packageName: "WooCommerce",
                                                                    bundle: Bundle(for: CoreDataManager.self))

        let manager = CoreDataManager(name: "WooCommerce", crashLogger: MockCrashLogger())

        // When
        let container = manager.persistentContainer

        // Then
        XCTAssertEqual(container.managedObjectModel, modelsInventory.currentModel)
        XCTAssertEqual(container.persistentStoreCoordinator.persistentStores.first?.url?.lastPathComponent, "WooCommerce.sqlite")
    }

    /// Verifies that the ContextManager's viewContext matches the PersistenContainer.viewContext
    ///
    func test_viewContext_property_returns_persistentContainer_main_context() {
        let manager = CoreDataManager(name: "WooCommerce", crashLogger: MockCrashLogger())
        XCTAssertEqual(manager.viewStorage as? NSManagedObjectContext, manager.persistentContainer.viewContext)
    }

    /// Verifies that performBackgroundTask effectively runs received closure in BG.
    ///
    func test_performBackgroundTask_effectively_runs_received_closure_in_background_thread() {
        let manager = CoreDataManager(name: "WooCommerce", crashLogger: MockCrashLogger())
        let expectation = self.expectation(description: "Background")

        manager.performBackgroundTask { (_) in
            XCTAssertFalse(Thread.isMainThread)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that derived context is instantiated correctly.
    ///
    func test_derived_storage_is_instantiated_correctly() {
        let manager = CoreDataManager(name: "WooCommerce", crashLogger: MockCrashLogger())
        let viewContext = (manager.viewStorage as? NSManagedObjectContext)
        let derivedContext = (manager.newDerivedStorage() as? NSManagedObjectContext)

        XCTAssertNotNil(viewContext)
        XCTAssertNotNil(derivedContext)
        XCTAssertNotEqual(derivedContext, viewContext)
        XCTAssertEqual(derivedContext?.parent, viewContext)
    }

    func test_resetting_CoreData_deletes_preexisting_objects() throws {
        // Arrange
        let manager = CoreDataManager(name: "WooCommerce", crashLogger: MockCrashLogger())
        manager.reset()
        let viewContext = try XCTUnwrap(manager.viewStorage as? NSManagedObjectContext)
        _ = viewContext.insertNewObject(ofType: ShippingLine.self)
        viewContext.saveIfNeeded()
        XCTAssertEqual(viewContext.countObjects(ofType: ShippingLine.self), 1)

        // Action
        manager.reset()

        // Assert
        XCTAssertEqual(viewContext.countObjects(ofType: ShippingLine.self), 0)
    }

    func test_saving_derived_storage_while_resetting_CoreData_still_saves_data() throws {
        // Arrange
        let manager = CoreDataManager(name: "WooCommerce", crashLogger: MockCrashLogger())
        manager.reset()
        let viewContext = try XCTUnwrap(manager.viewStorage as? NSManagedObjectContext)
        let derivedContext = try XCTUnwrap(manager.newDerivedStorage() as? NSManagedObjectContext)

        // Action
        waitForExpectation(count: 2) { expectation in
            derivedContext.perform {
                _ = derivedContext.insertNewObject(ofType: ShippingLine.self)
            }
            manager.saveDerivedType(derivedStorage: derivedContext, {
                expectation.fulfill()
            })
            manager.reset()
            expectation.fulfill()
        }

        // Assert
        XCTAssertEqual(viewContext.countObjects(ofType: ShippingLine.self), 1)
    }

    func test_when_the_model_is_incompatible_then_it_recovers_and_recreates_the_database() throws {
        // Given
        let packageName = "WooCommerce"

        var manager = CoreDataManager(name: packageName, crashLogger: MockCrashLogger())
        try deleteStoreFiles(at: manager.storeURL)

        insertAccount(to: manager.viewStorage)
        manager.viewStorage.saveIfNeeded()

        XCTAssertEqual(manager.viewStorage.countObjects(ofType: Account.self), 1)
        XCTAssertNotNil(NSEntityDescription.entity(forEntityName: Note.entityName,
                                                   in: manager.viewStorage as! NSManagedObjectContext))

        // When
        // Use a models inventory with an old model. this will cause a loading error and make the
        // `CoreDataManager` recover and recreate the database.
        let olderModelsInventory: ManagedObjectModelsInventory = try {
            let inventory =
                try ManagedObjectModelsInventory.from(packageName: packageName, bundle: .init(for: CoreDataManager.self))

            return ManagedObjectModelsInventory(
                packageURL: inventory.packageURL,
                currentModel: try XCTUnwrap(inventory.model(for: .init(name: "Model 2"))),
                versions: [.init(name: "Model 2")]
            )
        }()

        manager = CoreDataManager(name: packageName,
                                  crashLogger: MockCrashLogger(),
                                  modelsInventory: olderModelsInventory)

        // Then
        // The rows should have been deleted during the recovery.
        XCTAssertEqual(manager.viewStorage.countObjects(ofType: Account.self), 0)
        // We should still be able to use the storage
        insertAccount(to: manager.viewStorage)
        insertAccount(to: manager.viewStorage)
        XCTAssertEqual(manager.viewStorage.countObjects(ofType: Account.self), 2)

        // The Note entity does not exist in Model 2. This proves that the store was reset to Model 2.
        XCTAssertNil(NSEntityDescription.entity(forEntityName: Note.entityName,
                                                in: manager.viewStorage as! NSManagedObjectContext))
    }
}

// MARK: - Helpers

private extension CoreDataManagerTests {
    @discardableResult
    func insertAccount(to storage: StorageType) -> Account {
        let account = storage.insertNewObject(ofType: Account.self)
        account.userID = 0
        account.username = ""
        return account
    }

    func deleteStoreFiles(at storeURL: URL) throws {
        let fileManager = FileManager.default
        let expectedExtensions = ["sqlite", "sqlite-wal", "sqlite-shm"]

        try expectedExtensions.forEach { ext in
            let fileURL = storeURL.deletingPathExtension().appendingPathExtension(ext)
            if fileManager.fileExists(atPath: fileURL.path) {
                try fileManager.removeItem(at: fileURL)
            }
        }
    }
}
