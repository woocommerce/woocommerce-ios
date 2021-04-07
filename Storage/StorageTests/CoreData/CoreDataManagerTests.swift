import XCTest
import CoreData
@testable import Storage


/// CoreDataManager Unit Tests
///
final class CoreDataManagerTests: XCTestCase {

    private let storageIdentifier = "WooCommerce"

    /// Verifies that the Store URL contains the ContextIdentifier string.
    ///
    func test_storeUrl_maps_to_sqlite_file_with_context_identifier() {
        let manager = CoreDataManager(name: storageIdentifier, crashLogger: MockCrashLogger())
        XCTAssertEqual(manager.storeURL.lastPathComponent, "WooCommerce.sqlite")
        XCTAssertEqual(manager.storeDescription.url?.lastPathComponent, "WooCommerce.sqlite")
    }

    /// Verifies that the PersistentContainer properly loads the sqlite database.
    ///
    func test_persistentContainer_loads_expected_data_model_and_sqlite_database() throws {
        // Given
        let modelsInventory = try makeModelsInventory()

        let manager = CoreDataManager(name: storageIdentifier, crashLogger: MockCrashLogger())

        // When
        let container = manager.persistentContainer

        // Then
        XCTAssertEqual(container.managedObjectModel, modelsInventory.currentModel)
        XCTAssertEqual(container.persistentStoreCoordinator.persistentStores.first?.url?.lastPathComponent, "WooCommerce.sqlite")
    }

    /// Verifies that the ContextManager's viewContext matches the PersistenContainer.viewContext
    ///
    func test_viewContext_property_returns_persistentContainer_main_context() {
        let manager = CoreDataManager(name: storageIdentifier, crashLogger: MockCrashLogger())
        XCTAssertEqual(manager.viewStorage as? NSManagedObjectContext, manager.persistentContainer.viewContext)
    }

    /// Verifies that performBackgroundTask effectively runs received closure in BG.
    ///
    func test_performBackgroundTask_effectively_runs_received_closure_in_background_thread() {
        let manager = CoreDataManager(name: storageIdentifier, crashLogger: MockCrashLogger())
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
        let manager = CoreDataManager(name: storageIdentifier, crashLogger: MockCrashLogger())
        let viewContext = (manager.viewStorage as? NSManagedObjectContext)
        let derivedContext = (manager.writerDerivedStorage as? NSManagedObjectContext)

        XCTAssertNotNil(viewContext)
        XCTAssertNotNil(derivedContext)
        XCTAssertNotEqual(derivedContext, viewContext)
        XCTAssertEqual(derivedContext?.parent, viewContext)
    }

    func test_resetting_CoreData_deletes_preexisting_objects() throws {
        // Arrange
        let manager = CoreDataManager(name: storageIdentifier, crashLogger: MockCrashLogger())
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
        let manager = CoreDataManager(name: storageIdentifier, crashLogger: MockCrashLogger())
        manager.reset()
        let viewContext = try XCTUnwrap(manager.viewStorage as? NSManagedObjectContext)
        let derivedContext = try XCTUnwrap(manager.writerDerivedStorage as? NSManagedObjectContext)

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
        let modelsInventory = try makeModelsInventory()
        var manager = try makeManager(using: modelsInventory, deletingExistingStoreFiles: true)

        insertAccount(to: manager.viewStorage)
        manager.viewStorage.saveIfNeeded()

        XCTAssertEqual(manager.viewStorage.countObjects(ofType: Account.self), 1)
        XCTAssertNotNil(NSEntityDescription.entity(forEntityName: Note.entityName,
                                                   in: manager.viewStorage as! NSManagedObjectContext))

        // When
        // Use a models inventory with an old and only one model. This will cause a loading error
        // because it is not compatible. This will then make `CoreDataManager` recover and
        // recreate the database.
        let invalidModelsInventory = ManagedObjectModelsInventory(
            packageURL: modelsInventory.packageURL,
            currentModel: try XCTUnwrap(modelsInventory.model(for: .init(name: "Model 2"))),
            versions: [.init(name: "Model 2")]
        )

        manager = try makeManager(using: invalidModelsInventory, deletingExistingStoreFiles: false)
        // Access persistentContainer to start the stack.
        _ = manager.persistentContainer

        // Then
        try assertThat(manager, isCompatibleWith: invalidModelsInventory.currentModel)

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

    func test_accessing_persistentContainer_will_automatically_migrate_the_database() throws {
        // Given
        let modelsInventory = try makeModelsInventory()
        // Create an inventory with up to Model 33 only. This is what we'll load first.
        let olderModelsInventory: ManagedObjectModelsInventory = try {
            let model33Index = try XCTUnwrap(modelsInventory.versions.firstIndex(of: .init(name: "Model 33")))
            let versions = Array(modelsInventory.versions.prefix(through: model33Index))

            return ManagedObjectModelsInventory(
                packageURL: modelsInventory.packageURL,
                currentModel: try XCTUnwrap(modelsInventory.model(for: try XCTUnwrap(versions.last))),
                versions: versions
            )
        }()

        var manager = try makeManager(using: olderModelsInventory, deletingExistingStoreFiles: true)

        insertAccount(to: manager.viewStorage)
        manager.viewStorage.saveIfNeeded()

        XCTAssertEqual(manager.viewStorage.countObjects(ofType: Account.self), 1)
        // The ShippineLineTax entity does not exist in Model 33.
        XCTAssertNil(NSEntityDescription.entity(forEntityName: ShippingLineTax.entityName,
                                                in: manager.viewStorage as! NSManagedObjectContext))

        try assertThat(manager, isCompatibleWith: olderModelsInventory.currentModel)

        // When
        manager = try makeManager(using: modelsInventory, deletingExistingStoreFiles: false)
        // Access persistentContainer to run the migration.
        _ = manager.persistentContainer

        // Then
        try assertThat(manager, isCompatibleWith: modelsInventory.currentModel)

        // The rows should have been kept.
        XCTAssertEqual(manager.viewStorage.countObjects(ofType: Account.self), 1)
        // We should still be able to use the storage
        insertAccount(to: manager.viewStorage)
        insertAccount(to: manager.viewStorage)
        XCTAssertEqual(manager.viewStorage.countObjects(ofType: Account.self), 3)

        // The ShippineLineTax entity should now be available. This proves that a migration happened.
        XCTAssertNotNil(NSEntityDescription.entity(forEntityName: ShippingLineTax.entityName,
                                                   in: manager.viewStorage as! NSManagedObjectContext))
    }

    func test_accessing_persistentContainer_will_not_migrate_the_database_if_the_model_is_up_to_date() throws {
        // Given
        let modelsInventory = try makeModelsInventory()

        var manager = try makeManager(using: modelsInventory, deletingExistingStoreFiles: true)

        insertAccount(to: manager.viewStorage)
        manager.viewStorage.saveIfNeeded()

        XCTAssertEqual(manager.viewStorage.countObjects(ofType: Account.self), 1)
        try assertThat(manager, isCompatibleWith: modelsInventory.currentModel)

        // When
        manager = try makeManager(using: modelsInventory, deletingExistingStoreFiles: false)
        // Access persistentContainer to initialize the stack.
        _ = manager.persistentContainer

        // Then
        // The store should still be compatible with the model we used the first time.
        try assertThat(manager, isCompatibleWith: modelsInventory.currentModel)

        // The rows should have been kept.
        XCTAssertEqual(manager.viewStorage.countObjects(ofType: Account.self), 1)
        // We should still be able to use the storage
        insertAccount(to: manager.viewStorage)
        insertAccount(to: manager.viewStorage)
        XCTAssertEqual(manager.viewStorage.countObjects(ofType: Account.self), 3)
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

    func makeManager(using modelsInventory: ManagedObjectModelsInventory,
                     deletingExistingStoreFiles deleteStoreFiles: Bool) throws -> CoreDataManager {
        let manager = CoreDataManager(name: storageIdentifier,
                                      crashLogger: MockCrashLogger(),
                                      modelsInventory: modelsInventory)
        if deleteStoreFiles {
            try self.deleteStoreFiles(at: manager.storeURL)
        }
        return manager
    }

    func makeModelsInventory() throws -> ManagedObjectModelsInventory {
        try ManagedObjectModelsInventory.from(packageName: storageIdentifier, bundle: .init(for: CoreDataManager.self))
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

// Assertions

private extension CoreDataManagerTests {
    func assertThat(_ manager: CoreDataManager,
                    isCompatibleWith model: NSManagedObjectModel,
                    file: StaticString = #file,
                    line: UInt = #line) throws {
        let coordinator = manager.persistentContainer.persistentStoreCoordinator

        // We assume that there is only 1 store loaded.
        XCTAssertEqual(coordinator.persistentStores.count, 1)

        let store = try XCTUnwrap(coordinator.persistentStores.first)
        let isCompatible = model.isConfiguration(withName: nil,
                                                 compatibleWithStoreMetadata: store.metadata)
        XCTAssertTrue(isCompatible,
                      "Expected store at \(String(describing: store.url)) to be compatible with model \(model).",
                      file: file,
                      line: line)
    }
}
