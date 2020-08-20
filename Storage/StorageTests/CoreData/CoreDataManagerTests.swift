import XCTest
import CoreData
@testable import Storage


/// CoreDataManager Unit Tests
///
class CoreDataManagerTests: XCTestCase {

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
}
