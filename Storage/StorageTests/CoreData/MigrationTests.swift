import XCTest
import CoreData

@testable import Storage

/// Tests for migrating from a specific model version to another.
///
/// Ideally, we should have a test for every new model version. There can also be more than
/// one test between 2 versions if there are many cases being tested.
///
/// ## Notes
///
/// In general, we should avoid using the entity classes like `Product` or `Order`. These classes
/// may **change** in the future. And if they do, the migration tests would have to be changed.
/// There's a risk that the migration tests would no longer be correct if this happens.
///
/// That said, it is understandable that we are sometimes under pressure to finish features that
/// this may not be economical.
///
final class MigrationTests: XCTestCase {
    private var modelsInventory: ManagedObjectModelsInventory!

    /// URLs of SQLite stores created using `makePersistentStore()`.
    ///
    /// These will be deleted during tear down.
    private var createdStoreURLs = Set<URL>()

    override func setUpWithError() throws {
        try super.setUpWithError()
        modelsInventory = try .from(packageName: "WooCommerce", bundle: Bundle(for: CoreDataManager.self))
    }

    override func tearDownWithError() throws {
        let fileManager = FileManager.default
        let knownExtensions = ["sqlite-shm", "sqlite-wal"]
        try createdStoreURLs.forEach { url in
            try fileManager.removeItem(at: url)

            try knownExtensions.forEach { ext in
                if fileManager.fileExists(atPath: url.appendingPathExtension(ext).path) {
                    try fileManager.removeItem(at: url.appendingPathExtension(ext))
                }
            }
        }

        modelsInventory = nil

        try super.tearDownWithError()
    }

    func test_migrating_from_26_to_27_migration_passes() throws {
        // Arrange
        let model26URL = urlForModel(name: "Model 26")
        let model26 = NSManagedObjectModel(contentsOf: model26URL)!
        let model27URL = urlForModel(name: "Model 27")
        let model27 = NSManagedObjectModel(contentsOf: model27URL)!
        let name = "WooCommerce"
        let crashLogger = MockCrashLogger()
        let coreDataManager = CoreDataManager(name: name, crashLogger: crashLogger)

        // Destroys any pre-existing persistence store.
        let psc = NSPersistentStoreCoordinator(managedObjectModel: modelsInventory.currentModel)
        try psc.destroyPersistentStore(at: coreDataManager.storeURL, ofType: NSSQLiteStoreType, options: nil)

        // Action - step 1: loading persistence store with model 26
        let model26Container = NSPersistentContainer(name: name, managedObjectModel: model26)
        model26Container.persistentStoreDescriptions = [coreDataManager.storeDescription]

        var model26LoadingError: Error?
        waitForExpectation { expectation in
            model26Container.loadPersistentStores { (storeDescription, error) in
                model26LoadingError = error
                expectation.fulfill()
            }
        }

        // Assert - step 1
        XCTAssertNil(model26LoadingError, "Migration error: \(String(describing: model26LoadingError?.localizedDescription))")

        guard let metadata = try? NSPersistentStoreCoordinator
            .metadataForPersistentStore(ofType: NSSQLiteStoreType,
                                        at: coreDataManager.storeURL,
                                        options: nil) else {
                                            XCTFail("Cannot get metadata for persistent store at URL \(coreDataManager.storeURL)")
                                            return
        }

        // The persistent store should be compatible with model 26 now and incompatible with model 27.
        XCTAssertTrue(model26.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata))
        XCTAssertFalse(model27.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata))

        // Arrange - step 2: populating data, migrating persistent store from model 26 to 27, then loading with model 27.
        let context = model26Container.viewContext
        _ = insertAccountWithRequiredProperties(to: context)
        let product = insertProductWithRequiredProperties(to: context)
        let productCategory = insertProductCategoryWithRequiredProperties(to: context)
        product.addToCategories([productCategory])
        context.saveIfNeeded()

        XCTAssertEqual(context.countObjects(ofType: Account.self), 1)
        XCTAssertEqual(context.countObjects(ofType: Product.self), 1)
        XCTAssertEqual(context.countObjects(ofType: ProductCategory.self), 1)

        let model27Container = NSPersistentContainer(name: name, managedObjectModel: model27)
        model27Container.persistentStoreDescriptions = [coreDataManager.storeDescription]

        // Action - step 2
        let iterativeMigrator = CoreDataIterativeMigrator(modelsInventory: modelsInventory)
        let (migrateResult, migrationDebugMessages) = try iterativeMigrator.iterativeMigrate(sourceStore: coreDataManager.storeURL,
                                                                                             storeType: NSSQLiteStoreType,
                                                                                             to: model27)
        XCTAssertTrue(migrateResult, "Failed to migrate to model version 27: \(migrationDebugMessages)")

        var model27LoadingError: Error?
        waitForExpectation { expectation in
            model27Container.loadPersistentStores { (storeDescription, error) in
                model27LoadingError = error
                expectation.fulfill()
            }
        }

        // Assert - step 2
        XCTAssertNil(model27LoadingError, "Migration error: \(String(describing: model27LoadingError?.localizedDescription))")

        XCTAssertEqual(model27Container.viewContext.countObjects(ofType: Account.self), 1)
        XCTAssertEqual(model27Container.viewContext.countObjects(ofType: Product.self), 1)
        // Product categories should be deleted.
        XCTAssertEqual(model27Container.viewContext.countObjects(ofType: ProductCategory.self), 0)
    }

    func test_migrating_from_31_to_32_renames_Attribute_to_GenericAttribute() throws {
        // Given
        let container = try startPersistentContainer("Model 31")

        let attribute = container.viewContext.insert(entityName: "Attribute", properties: [
            "id": 9_753_134,
            "key": "voluptatem",
            "value": "veritatis"
        ])
        let variation = insertProductVariation(to: container.viewContext)
        variation.mutableOrderedSetValue(forKey: "attributes").add(attribute)

        try container.viewContext.save()

        XCTAssertEqual(try container.viewContext.count(entityName: "Attribute"), 1)
        XCTAssertEqual(try container.viewContext.count(entityName: "ProductVariation"), 1)

        // When
        let migratedContainer = try migrate(container, to: "Model 32")

        // Then
        XCTAssertNil(NSEntityDescription.entity(forEntityName: "Attribute", in: migratedContainer.viewContext))
        XCTAssertEqual(try migratedContainer.viewContext.count(entityName: "GenericAttribute"), 1)
        XCTAssertEqual(try migratedContainer.viewContext.count(entityName: "ProductVariation"), 1)

        let migratedAttribute = try XCTUnwrap(migratedContainer.viewContext.allObjects(entityName: "GenericAttribute").first)
        XCTAssertEqual(migratedAttribute.value(forKey: "id") as? Int, 9_753_134)
        XCTAssertEqual(migratedAttribute.value(forKey: "key") as? String, "voluptatem")
        XCTAssertEqual(migratedAttribute.value(forKey: "value") as? String, "veritatis")

        // The "attributes" relationship should have been migrated too
        let migratedVariation = try XCTUnwrap(migratedContainer.viewContext.allObjects(entityName: "ProductVariation").first)
        let migratedVariationAttributes = migratedVariation.mutableOrderedSetValue(forKey: "attributes")
        XCTAssertEqual(migratedVariationAttributes.count, 1)
        XCTAssertEqual(migratedVariationAttributes.firstObject as? NSManagedObject, migratedAttribute)

        // The migrated attribute can be accessed using the newly renamed `GenericAttribute` class.
        let genericAttribute = try XCTUnwrap(migratedContainer.viewContext.firstObject(ofType: GenericAttribute.self))
        XCTAssertEqual(genericAttribute.id, 9_753_134)
        XCTAssertEqual(genericAttribute.key, "voluptatem")
        XCTAssertEqual(genericAttribute.value, "veritatis")
    }
}

// MARK: - Persistent Store Setup and Migrations

private extension MigrationTests {
    /// Create a new Sqlite file and load it. Returns the loaded `NSPersistentContainer`.
    func startPersistentContainer(_ versionName: String) throws -> NSPersistentContainer {
        let storeURL = try XCTUnwrap(NSURL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)?
            .appendingPathExtension("sqlite"))
        let model = try XCTUnwrap(modelsInventory.model(for: .init(name: versionName)))
        let container = makePersistentContainer(storeURL: storeURL, model: model)

        let loadingError: Error? = try waitFor { promise in
            container.loadPersistentStores { _, error in
                promise(error)
            }
        }
        XCTAssertNil(loadingError)

        return container
    }

    /// Migrate the existing `container` to the model with name `versionName`.
    ///
    /// This disconnects the given `container` from the `NSPersistentStore` (SQLite) to avoid
    /// warnings pertaining to having two `NSPersistentContainer` using the same SQLite file.
    /// The `container.viewContext` and any created `NSManagedObjects` can still be used but
    /// they will not be attached to the SQLite database so watch out for that. XD
    ///
    /// - Returns: A new `NSPersistentContainer` instance using the new `NSManagedObjectModel`
    ///            pointed to by `versionName`.
    ///
    func migrate(_ container: NSPersistentContainer, to versionName: String) throws -> NSPersistentContainer {
        let storeDescription = try XCTUnwrap(container.persistentStoreDescriptions.first)
        let storeURL = try XCTUnwrap(storeDescription.url)
        let targetModel = try XCTUnwrap(modelsInventory.model(for: .init(name: versionName)))

        // Unload the currently loaded persistent store to avoid Sqlite warnings when we create
        // another NSPersistentContainer later after the upgrade.
        let persistentStore = try XCTUnwrap(container.persistentStoreCoordinator.persistentStore(for: storeURL))
        try container.persistentStoreCoordinator.remove(persistentStore)

        // Migrate the store
        let migrator = CoreDataIterativeMigrator(modelsInventory: modelsInventory)
        let (isMigrationSuccessful, _) =
            try migrator.iterativeMigrate(sourceStore: storeURL, storeType: storeDescription.type, to: targetModel)
        XCTAssertTrue(isMigrationSuccessful)

        // Load a new container
        let migratedContainer = makePersistentContainer(storeURL: storeURL, model: targetModel)
        let loadingError: Error? = try waitFor { promise in
            migratedContainer.loadPersistentStores { _, error in
                promise(error)
            }
        }
        XCTAssertNil(loadingError)

        return migratedContainer
    }

    func makePersistentContainer(storeURL: URL, model: NSManagedObjectModel) -> NSPersistentContainer {
        let description: NSPersistentStoreDescription = {
            let description = NSPersistentStoreDescription(url: storeURL)
            description.shouldAddStoreAsynchronously = false
            description.shouldMigrateStoreAutomatically = false
            description.type = NSSQLiteStoreType
            return description
        }()

        let container = NSPersistentContainer(name: "ContainerName", managedObjectModel: model)
        container.persistentStoreDescriptions = [description]

        createdStoreURLs.insert(storeURL)

        return container
    }
}

// MARK: - Entity Helpers
//

private extension MigrationTests {
    /// Inserts a `ProductVariation` entity, providing default values for the required properties.
    @discardableResult
    func insertProductVariation(to context: NSManagedObjectContext) -> NSManagedObject {
        context.insert(entityName: "ProductVariation", properties: [
            "dateCreated": Date(),
            "backordered": false,
            "backordersAllowed": false,
            "backordersKey": "",
            "permalink": "",
            "price": "",
            "statusKey": "",
            "stockStatusKey": "",
            "taxStatusKey": ""
        ])
    }

    func insertAccount(to context: NSManagedObjectContext) -> NSManagedObject {
        context.insert(entityName: "Account", properties: [
            "userID": 0,
            "username": ""
        ])
    }

    @discardableResult
    func insertProduct(to context: NSManagedObjectContext) -> NSManagedObject {
        context.insert(entityName: "Product", properties: [
            "price": "",
            "permalink": "",
            "productTypeKey": "simple",
            "purchasable": true,
            "averageRating": "",
            "backordered": true,
            "backordersAllowed": false,
            "backordersKey": "",
            "catalogVisibilityKey": "",
            "dateCreated": Date(),
            "downloadable": true,
            "featured": true,
            "manageStock": true,
            "name": "product",
            "onSale": true,
            "soldIndividually": true,
            "slug": "",
            "shippingRequired": false,
            "shippingTaxable": false,
            "reviewsAllowed": true,
            "groupedProducts": [],
            "virtual": true,
            "stockStatusKey": "",
            "statusKey": "",
            "taxStatusKey": ""
        ])
    }
}
