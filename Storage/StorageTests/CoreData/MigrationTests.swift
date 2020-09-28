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

    override func setUpWithError() throws {
        try super.setUpWithError()
        modelsInventory = try .from(packageName: "WooCommerce", bundle: Bundle(for: CoreDataManager.self))
    }

    override func tearDown() {
        modelsInventory = nil
        super.tearDown()
    }

    func test_migrating_from_31_to_32_renames_Attribute_to_GenericAttribute() throws {
        // Given
        let container = try startPersistentContainer("Model 31")
        container.viewContext.insert(entityName: "Attribute", properties: [
            "id": 9_753_134,
            "key": "voluptatem",
            "value": "veritatis"
        ]);
        try container.viewContext.save()

        XCTAssertEqual(try container.viewContext.count(entityName: "Attribute"), 1)

        // When
        let upgradedContainer = try migrate(container, to: "Model 32")

        // Then
        XCTAssertNil(NSEntityDescription.entity(forEntityName: "Attribute", in: upgradedContainer.viewContext))

        XCTAssertEqual(try upgradedContainer.viewContext.count(entityName: "GenericAttribute"), 1)

        let migratedAttribute = try XCTUnwrap(upgradedContainer.viewContext.allObjects(entityName: "GenericAttribute").first)
        XCTAssertEqual(migratedAttribute.value(forKey: "id") as? Int, 9_753_134)
        XCTAssertEqual(migratedAttribute.value(forKey: "key") as? String, "voluptatem")
        XCTAssertEqual(migratedAttribute.value(forKey: "value") as? String, "veritatis")
    }
}

private extension MigrationTests {
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
        let upgradedContainer = makePersistentContainer(storeURL: storeURL, model: targetModel)
        let loadingError: Error? = try waitFor { promise in
            upgradedContainer.loadPersistentStores { _, error in
                promise(error)
            }
        }
        XCTAssertNil(loadingError)

        return upgradedContainer
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
        return container
    }
}
