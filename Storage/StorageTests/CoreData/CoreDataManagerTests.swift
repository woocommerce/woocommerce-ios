import XCTest
import CoreData
@testable import Storage


/// CoreDataManager Unit Tests
///
class CoreDataManagerTests: XCTestCase {

    /// Verifies that the Data Model URL contains the ContextIdentifier String.
    ///
    func testModelUrlMapsToDataModelWithContextIdentifier() {
        let manager = CoreDataManager(name: "WooCommerce", crashLogger: MockCrashLogger())
        XCTAssertEqual(manager.modelURL.lastPathComponent, "WooCommerce.momd")
        XCTAssertNoThrow(manager.managedModel)
    }

    /// Verifies that the Store URL contains the ContextIdentifier string.
    ///
    func testStorageUrlMapsToSqliteFileWithContextIdentifier() {
        let manager = CoreDataManager(name: "WooCommerce", crashLogger: MockCrashLogger())
        XCTAssertEqual(manager.storeURL.lastPathComponent, "WooCommerce.sqlite")
        XCTAssertEqual(manager.storeDescription.url?.lastPathComponent, "WooCommerce.sqlite")
    }

    /// Verifies that the PersistentContainer properly loads the sqlite database.
    ///
    func testPersistentContainerLoadsExpectedDataModelAndSqliteDatabase() {
        let manager = CoreDataManager(name: "WooCommerce", crashLogger: MockCrashLogger())
        let container = manager.persistentContainer

        XCTAssertEqual(container.managedObjectModel, manager.managedModel)
        XCTAssertEqual(container.persistentStoreCoordinator.persistentStores.first?.url?.lastPathComponent, "WooCommerce.sqlite")
    }

    /// Verifies that the ContextManager's viewContext matches the PersistenContainer.viewContext
    ///
    func testViewContextPropertyReturnsPersistentContainerMainContext() {
        let manager = CoreDataManager(name: "WooCommerce", crashLogger: MockCrashLogger())
        XCTAssertEqual(manager.viewStorage as? NSManagedObjectContext, manager.persistentContainer.viewContext)
    }

    /// Verifies that performBackgroundTask effectively runs received closure in BG.
    ///
    func testPerformTaskInBackgroundEffectivelyRunsReceivedClosureInBackgroundThread() {
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
    func testDerivedStorageIsInstantiatedCorrectly() {
        let manager = CoreDataManager(name: "WooCommerce", crashLogger: MockCrashLogger())
        let viewContext = (manager.viewStorage as? NSManagedObjectContext)
        let derivedContext = (manager.newDerivedStorage() as? NSManagedObjectContext)

        XCTAssertNotNil(viewContext)
        XCTAssertNotNil(derivedContext)
        XCTAssertNotEqual(derivedContext, viewContext)
        XCTAssertEqual(derivedContext?.parent, viewContext)
    }
}
