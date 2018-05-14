import XCTest
import CoreData
@testable import Storage


/// CoreDataManager Unit Tests
///
class CoreDataManagerTests: XCTestCase {

    /// Verifies that the Data Model URL contains the ContextIdentifier String.
    ///
    func testModelUrlMapsToDataModelWithContextIdentifier() {
        let context = CoreDataManager(name: "WooCommerce")
        XCTAssertEqual(context.modelURL.lastPathComponent, "WooCommerce.momd")
        XCTAssertNoThrow(context.managedModel)
    }

    /// Verifies that the Store URL contains the ContextIdentifier string.
    ///
    func testStorageUrlMapsToSqliteFileWithContextIdentifier() {
        let context = CoreDataManager(name: "WooCommerce")
        XCTAssertEqual(context.storeURL.lastPathComponent, "WooCommerce.sqlite")
        XCTAssertEqual(context.storeDescription.url?.lastPathComponent, "WooCommerce.sqlite")
    }

    /// Verifies that the PersistentContainer properly loads the sqlite database.
    ///
    func testPersistentContainerLoadsExpectedDataModelAndSqliteDatabase() {
        let context = CoreDataManager(name: "WooCommerce")

        let container = context.persistentContainer
        XCTAssertEqual(container.managedObjectModel, context.managedModel)

        let expectation = self.expectation(description: "Async Load")
        container.loadPersistentStores { (_, _) in
            XCTAssertEqual(container.persistentStoreCoordinator.persistentStores.first?.url?.lastPathComponent, "WooCommerce.sqlite")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies taht the ContextManager's viewContext matches the PersistenContainer.viewContext
    ///
    func testViewContextPropertyReturnsPersistentContainerMainContext() {
        let context = CoreDataManager(name: "WooCommerce")
        XCTAssertEqual(context.viewStorage as? NSManagedObjectContext, context.persistentContainer.viewContext)
    }
}
