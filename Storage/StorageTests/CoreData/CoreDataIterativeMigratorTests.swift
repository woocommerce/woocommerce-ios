import XCTest
import TestKit
import CocoaLumberjack
import CoreData
@testable import Storage

/// Test cases for `CoreDataIterativeMigrator`.
///
/// Test cases for migrating from a model version to another should be in `MigrationTests`.
///
final class CoreDataIterativeMigratorTests: XCTestCase {
    private var modelsInventory: ManagedObjectModelsInventory!

    override func setUpWithError() throws {
        try super.setUpWithError()
        DDLog.add(DDOSLogger.sharedInstance)
        modelsInventory = try .from(packageName: "WooCommerce", bundle: Bundle(for: CoreDataManager.self))
    }

    override func tearDown() {
        modelsInventory = nil
        DDLog.remove(DDOSLogger.sharedInstance)
        super.tearDown()
    }

    /// Tests that model versions are not compatible with each other.
    ///
    /// This protects us from mistakes like adding a new model version that has **no structural
    /// changes** and not setting the Hash Modifier. An example of that is creating a new model
    /// but only renaming the entity classes. If we forget to change the model's Hash Modifier,
    /// then the `CoreDataManager.migrateDataModelIfNecessary` will (correctly) **skip** the
    /// migration. See here for more information: https://tinyurl.com/yxzpwp7t.
    ///
    /// This loops through **all NSManagedObjectModels**, performs a migration, and checks for
    /// compatibility with all the other versions. For example, for "Model 3":
    ///
    /// 1. Migrate the store from previous model (Model 2) to Model 3.
    /// 2. Check that Model 3 is compatible with the _migrated_ store. This verifies the migration.
    /// 3. Check that Models 1, 2, 4, 5, 6, 7, and so on are **not** compatible with the _migrated_ store.
    ///
    /// ## Testing
    ///
    /// You can make this test fail by:
    ///
    /// 1. Creating a new model version for `WooCommerce.xcdatamodeld`, copying the latest version.
    /// 2. Running this test.
    ///
    /// And then make this pass again by setting a Hash Modifier value for the new model.
    ///
    func test_all_model_versions_are_not_compatible_with_each_other() throws {
        // Given
        // Use in-memory type or else this would be too slow.
        let storeType = NSInMemoryStoreType
        let storeURL = try XCTUnwrap(NSURL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)?
            .appendingPathExtension("sqlite"))

        // Cache the models to improve the performance of the loop below.
        let modelsByVersionName = try modelsInventory.versions.reduce(into: [String: NSManagedObjectModel]()) { result, version in
            result[version.name] = try XCTUnwrap(modelsInventory.model(for: version))
        }

        try modelsInventory.versions.forEach { currentVersion in
            // Given
            let currentModel = try XCTUnwrap(modelsByVersionName[currentVersion.name])

            let persistentContainer =
                makePersistentContainer(storeURL: storeURL, storeType: storeType, model: currentModel)

            // When
            // Migrate to the currentVersion if this is not the first version in the list.
            if modelsInventory.versions.first != currentVersion {
                let migrator = CoreDataIterativeMigrator(coordinator: persistentContainer.persistentStoreCoordinator,
                                                         modelsInventory: modelsInventory)
                let (isMigrationSuccessful, _) =
                    try migrator.iterativeMigrate(sourceStore: storeURL, storeType: storeType, to: currentModel)
                XCTAssertTrue(isMigrationSuccessful)
            }

            // Load the persistent container
            let loadingError: Error? = try waitFor { promise in
                persistentContainer.loadPersistentStores { _, error in
                    promise(error)
                }
            }
            XCTAssertNil(loadingError)

            let persistentStoreCoordinator = persistentContainer.persistentStoreCoordinator
            let persistentStore = try XCTUnwrap(persistentStoreCoordinator.persistentStores.first)

            // Then
            // The current model should be compatible with the current persistent store
            XCTAssertTrue(currentModel.isConfiguration(withName: nil, compatibleWithStoreMetadata: persistentStore.metadata),
                          "Current model “\(currentVersion.name)” should be compatible with the persistentStore.")

            // All other versions should not be compatible with the current persistentStore
            try modelsInventory.versions.filter {
                $0 != currentVersion
            }.forEach { version in
                let model = try XCTUnwrap(modelsByVersionName[version.name])
                XCTAssertFalse(model.isConfiguration(withName: nil, compatibleWithStoreMetadata: persistentStore.metadata),
                               "Model “\(version.name)” should not be compatible with the persistentStore whose version is “\(currentVersion.name)”.")
            }
        }
    }

    func test_it_will_not_migrate_if_the_database_file_does_not_exist() throws {
        // Given
        let targetModel = try managedObjectModel(for: "Model 28")
        let databaseURL = documentsDirectory.appendingPathComponent("database-file-that-does-not-exist")
        let fileManager = MockFileManager()

        fileManager.whenCheckingIfFileExists(atPath: databaseURL.path, thenReturn: false)

        // Using a fake `NSPersistentStoreCoordinator` is apparently inconsequential.
        let coordinator = NSPersistentStoreCoordinator()

        let migrator = CoreDataIterativeMigrator(coordinator: coordinator,
                                                 modelsInventory: modelsInventory,
                                                 fileManager: fileManager)

        // When
        let result = try migrator.iterativeMigrate(sourceStore: databaseURL,
                                                   storeType: NSSQLiteStoreType,
                                                   to: targetModel)

        // Then
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.debugMessages.count, 1)
        assertThat(try XCTUnwrap(result.debugMessages.first), contains: "Skipping migration.")
        XCTAssertEqual(fileManager.fileExistsInvocationCount, 1)
        XCTAssertEqual(fileManager.allMethodsInvocationCount, 1)
    }

    /// This is more like a confidence-check that Core Data does not allow us to open SQLite
    /// files using the wrong `NSManagedObjectModel`.
    func test_opening_a_store_with_a_different_model_fails() throws {
        // Given
        let model1 = try managedObjectModel(for: "Model")
        let model10 = try managedObjectModel(for: "Model 10")

        let storeURL = try urlForStore(withName: "Woo Test 10.sqlite", deleteIfExists: true)
        let options = [NSInferMappingModelAutomaticallyOption: false, NSMigratePersistentStoresAutomaticallyOption: false]

        // When
        var psc = NSPersistentStoreCoordinator(managedObjectModel: model1)
        var ps = try? psc.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: options)

        XCTAssertNotNil(ps)

        try psc.remove(ps!)

        // Load using a different model
        psc = NSPersistentStoreCoordinator(managedObjectModel: model10)
        ps = try? psc.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: options)

        // When
        XCTAssertNil(ps)
    }

    /// Test the IterativeMigrator can migrate iteratively between model 1 to 10.
    func test_iterativeMigrate_can_iteratively_migrate_from_model_1_to_model_10() throws {
        // Given
        let model1 = try managedObjectModel(for: "Model")
        let model10 = try managedObjectModel(for: "Model 10")

        let storeURL = try urlForStore(withName: "Woo Test 10.sqlite", deleteIfExists: true)
        let options = [NSInferMappingModelAutomaticallyOption: false, NSMigratePersistentStoresAutomaticallyOption: false]

        var psc = NSPersistentStoreCoordinator(managedObjectModel: model1)
        var ps = try? psc.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: options)
        XCTAssertNotNil(ps)

        try psc.remove(ps!)

        // When
        do {
            let iterativeMigrator = CoreDataIterativeMigrator(coordinator: try XCTUnwrap(psc),
                                                              modelsInventory: modelsInventory)
            let (result, _) = try iterativeMigrator.iterativeMigrate(sourceStore: storeURL,
                                                                     storeType: NSSQLiteStoreType,
                                                                     to: model10)
            XCTAssertTrue(result)
        } catch {
            XCTFail("Error when attempting to migrate: \(error)")
        }

        // Then
        psc = NSPersistentStoreCoordinator(managedObjectModel: model10)
        ps = try psc.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: options)
        XCTAssertNotNil(ps)
    }

    func test_iterativeMigrate_replaces_the_original_SQLite_files() throws {
        // Given
        let storeType = NSSQLiteStoreType
        let sourceModel = try managedObjectModel(for: "Model 30")
        let targetModel = try managedObjectModel(for: "Model 31")

        let storeFileName = "Woo_Migration_Replacement_Unit_Test.sqlite"
        let storeURL = try urlForStore(withName: storeFileName, deleteIfExists: true)
        // Start a container so the SQLite files will be created.
        let container = try startPersistentContainer(storeURL: storeURL, storeType: storeType, model: sourceModel)

        let spyCoordinator = SpyPersistentStoreCoordinator(container.persistentStoreCoordinator)

        let iterativeMigrator = CoreDataIterativeMigrator(coordinator: spyCoordinator,
                                                          modelsInventory: modelsInventory)

        // When
        let (result, _) = try iterativeMigrator.iterativeMigrate(sourceStore: storeURL,
                                                                 storeType: storeType,
                                                                 to: targetModel)
        // Then
        XCTAssertTrue(result)
        XCTAssertEqual(spyCoordinator.destroyedURLs.count, 1)
        XCTAssertEqual(spyCoordinator.replacements.count, 1)

        // The `storeURL` should have been the target of the replacement.
        let replacement = try XCTUnwrap(spyCoordinator.replacements.first)
        XCTAssertEqual(replacement.destinationURL, storeURL)
        // The sourceURL should have been from the temporary directory.
        XCTAssertEqual(replacement.sourceURL.deletingLastPathComponent(),
                       URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true))
    }

    func test_iterativeMigrate_moves_the_migrated_SQLite_files_to_the_original_store_location() throws {
        // Given
        let storeType = NSSQLiteStoreType
        let sourceModel = try managedObjectModel(for: "Model 30")
        let targetModel = try managedObjectModel(for: "Model 31")

        let storeFileName = "WooMigrationMoveUnitTest.sqlite"
        let storeURL = try urlForStore(withName: storeFileName, deleteIfExists: true)
        // Start a container so the SQLite files will be created.
        let container = try startPersistentContainer(storeURL: storeURL, storeType: storeType, model: sourceModel)

        let spyFileManager = SpyFileManager()
        let iterativeMigrator = CoreDataIterativeMigrator(coordinator: container.persistentStoreCoordinator,
                                                          modelsInventory: modelsInventory,
                                                          fileManager: spyFileManager)

        // When
        let (result, _) = try iterativeMigrator.iterativeMigrate(sourceStore: storeURL,
                                                                 storeType: storeType,
                                                                 to: targetModel)
        // Then
        XCTAssertTrue(result)

        let movedItems = spyFileManager.movedItems
        XCTAssertEqual(movedItems.count, 3)

        let storeFolderURL = storeURL.deletingLastPathComponent()
        let expectedMigrationFolderURL = storeURL.deletingLastPathComponent().appendingPathComponent("migration")
        let expectedFilesToBeMoved = [
            storeURL.lastPathComponent,
            "\(storeURL.lastPathComponent)-wal",
            "\(storeURL.lastPathComponent)-shm"
        ]

        expectedFilesToBeMoved.forEach { fileName in
            XCTAssertEqual(movedItems[expectedMigrationFolderURL.appendingPathComponent(fileName).path],
                           storeFolderURL.appendingPathComponent(fileName).path)
        }
    }

    func test_iterativeMigrate_will_not_migrate_if_the_database_and_the_model_are_compatible() throws {
        // Given
        let model = try managedObjectModel(for: "Model 28")

        // Start a container to create an existing database file.
        let storeURL = try urlForStore(withName: "Woo_Compatibility_Test.sqlite", deleteIfExists: true)
        let container = try startPersistentContainer(storeURL: storeURL, storeType: NSSQLiteStoreType, model: model)

        let spyFileManager = SpyFileManager()
        let migrator = CoreDataIterativeMigrator(coordinator: container.persistentStoreCoordinator,
                                                 modelsInventory: modelsInventory,
                                                 fileManager: spyFileManager)

        // When
        // Migrate up to the same model version.
        let (result, debugMessages) = try migrator.iterativeMigrate(sourceStore: storeURL,
                                                                    storeType: NSSQLiteStoreType,
                                                                    to: model)

        // Then
        XCTAssertTrue(result)

        XCTAssertEqual(debugMessages.count, 1)
        assertThat(try XCTUnwrap(debugMessages.first), contains: "No migration necessary.")

        // There should be no file operations.
        assertEmpty(spyFileManager.deletedItems)
        assertEmpty(spyFileManager.movedItems)
    }
}

/// Helpers for the Core Data migration tests
private extension CoreDataIterativeMigratorTests {

    var documentsDirectory: URL {
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last!
        return URL(fileURLWithPath: path)
    }

    func managedObjectModel(for modelName: String) throws -> NSManagedObjectModel {
        let modelVersion = ManagedObjectModelsInventory.ModelVersion(name: modelName)
        return try XCTUnwrap(modelsInventory.model(for: modelVersion))
    }

    /// Prefer using `managedObjectModel(for:)` directly. 
    func urlForModel(name: String) -> URL {

        let bundle = Bundle(for: CoreDataManager.self)
        guard let path = bundle.paths(forResourcesOfType: "momd", inDirectory: nil).first,
            let url = bundle.url(forResource: name, withExtension: "mom", subdirectory: URL(fileURLWithPath: path).lastPathComponent) else {
            fatalError("Missing Model Resource")
        }

        return url
    }

    func urlForStore(withName: String, deleteIfExists: Bool = false) throws -> URL {
        let storeURL = documentsDirectory.appendingPathComponent(withName)

        if deleteIfExists && FileManager.default.fileExists(atPath: storeURL.path) {
            try FileManager.default.removeItem(at: storeURL)
        }

        try FileManager.default.createDirectory(at: documentsDirectory, withIntermediateDirectories: true, attributes: nil)

        return storeURL
    }

    func makePersistentContainer(storeURL: URL, storeType: String, model: NSManagedObjectModel) -> NSPersistentContainer {
        let description: NSPersistentStoreDescription = {
            let description = NSPersistentStoreDescription(url: storeURL)
            description.shouldAddStoreAsynchronously = false
            description.shouldMigrateStoreAutomatically = false
            description.type = storeType
            return description
        }()

        let container = NSPersistentContainer(name: "ContainerName", managedObjectModel: model)
        container.persistentStoreDescriptions = [description]
        return container
    }

    /// Creates an `NSPersistentContainer` and load the store. Returns the loaded `NSPersistentContainer`.
    func startPersistentContainer(storeURL: URL, storeType: String, model: NSManagedObjectModel) throws -> NSPersistentContainer {
        let container = makePersistentContainer(storeURL: storeURL, storeType: storeType, model: model)

        let loadingError: Error? = try waitFor { promise in
            container.loadPersistentStores { _, error in
                promise(error)
            }
        }
        XCTAssertNil(loadingError)

        return container
    }
}
