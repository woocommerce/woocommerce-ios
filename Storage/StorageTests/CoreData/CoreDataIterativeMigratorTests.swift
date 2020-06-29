import XCTest
import CocoaLumberjack
import CoreData
@testable import Storage

final class CoreDataIterativeMigratorTests: XCTestCase {
    private let allModelNames = ["Model", "Model 2", "Model 3", "Model 4", "Model 5", "Model 6", "Model 7", "Model 8", "Model 9", "Model 10",
                                 "Model 11", "Model 12", "Model 13", "Model 14", "Model 15", "Model 16", "Model 17", "Model 18", "Model 19", "Model 20",
                                 "Model 21", "Model 22", "Model 23", "Model 24", "Model 25", "Model 26", "Model 27", "Model 28"]

    override func setUp() {
        super.setUp()
        DDLog.add(DDOSLogger.sharedInstance)
    }

    override func tearDown() {
        DDLog.remove(DDOSLogger.sharedInstance)
        super.tearDown()
    }

    func testModel0to10MigrationFails() throws {
        let model0URL = urlForModel(name: "Model")
        let model10URL = urlForModel(name: "Model 10")
        let storeURL = urlForStore(withName: "Woo Test 10.sqlite", deleteIfExists: true)
        let options = [NSInferMappingModelAutomaticallyOption: false, NSMigratePersistentStoresAutomaticallyOption: false]

        var model = NSManagedObjectModel(contentsOf: model0URL)
        XCTAssertNotNil(model)
        var psc = NSPersistentStoreCoordinator(managedObjectModel: model!)
        var ps = try? psc.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: options)

        XCTAssertNotNil(ps)

        try psc.remove(ps!)

        model = try XCTUnwrap(NSManagedObjectModel(contentsOf: model10URL))
        psc = NSPersistentStoreCoordinator(managedObjectModel: model!)

        ps = try? psc.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: options)

        XCTAssertNil(ps)
    }

    func testModelMigrationPassed() throws {
        let model0URL = urlForModel(name: "Model")
        let model10URL = urlForModel(name: "Model 10")
        let storeURL = urlForStore(withName: "Woo Test 10.sqlite", deleteIfExists: true)
        let options = [NSInferMappingModelAutomaticallyOption: false, NSMigratePersistentStoresAutomaticallyOption: false]

        var model = NSManagedObjectModel(contentsOf: model0URL)
        XCTAssertNotNil(model)
        var psc = NSPersistentStoreCoordinator(managedObjectModel: model!)
        var ps = try? psc.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: options)

        XCTAssertNotNil(ps)

        try psc.remove(ps!)

        model = try XCTUnwrap(NSManagedObjectModel(contentsOf: model10URL))

        do {
            let iterativeMigrator = CoreDataIterativeMigrator()
            let (result, _) = try iterativeMigrator.iterativeMigrate(sourceStore: storeURL,
                                                                     storeType: NSSQLiteStoreType,
                                                                     to: model!,
                                                                     using: allModelNames)
            XCTAssertTrue(result)
        } catch {
            XCTFail("Error when attempting to migrate: \(error)")
        }

        psc = NSPersistentStoreCoordinator(managedObjectModel: model!)

        ps = try psc.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: options)

        XCTAssertNotNil(ps)
    }

    func testModel26To27MigrationPassed() throws {
        // Arrange
        let model26URL = urlForModel(name: "Model 26")
        let model26 = NSManagedObjectModel(contentsOf: model26URL)!
        let model27URL = urlForModel(name: "Model 27")
        let model27 = NSManagedObjectModel(contentsOf: model27URL)!
        let name = "WooCommerce"
        let crashLogger = MockCrashLogger()
        let coreDataManager = CoreDataManager(name: name, crashLogger: crashLogger)

        // Destroys any pre-existing persistence store.
        let psc = NSPersistentStoreCoordinator(managedObjectModel: coreDataManager.managedModel)
        try? psc.destroyPersistentStore(at: coreDataManager.storeURL, ofType: NSSQLiteStoreType, options: nil)

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
        _ = insertAccount(to: context)
        let product = insertProduct(to: context)
        let productCategory = insertProductCategory(to: context)
        product.addToCategories([productCategory])
        context.saveIfNeeded()

        XCTAssertEqual(context.countObjects(ofType: Account.self), 1)
        XCTAssertEqual(context.countObjects(ofType: Product.self), 1)
        XCTAssertEqual(context.countObjects(ofType: ProductCategory.self), 1)

        let model27Container = NSPersistentContainer(name: name, managedObjectModel: model27)
        model27Container.persistentStoreDescriptions = [coreDataManager.storeDescription]

        // Action - step 2
        let iterativeMigrator = CoreDataIterativeMigrator()
        let (migrateResult, migrationDebugMessages) = try iterativeMigrator.iterativeMigrate(sourceStore: coreDataManager.storeURL,
                                                                                             storeType: NSSQLiteStoreType,
                                                                                             to: model27,
                                                                                             using: allModelNames)
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
}

/// Helpers for generating data in migration tests
private extension CoreDataIterativeMigratorTests {
    func insertAccount(to context: NSManagedObjectContext) -> Account {
        let account = context.insertNewObject(ofType: Account.self)
        // Populates the required attributes.
        account.userID = 17
        account.username = "hi"
        return account
    }

    func insertProduct(to context: NSManagedObjectContext) -> Product {
        let product = context.insertNewObject(ofType: Product.self)
        // Populates the required attributes.
        product.price = ""
        product.permalink = ""
        product.productTypeKey = "simple"
        product.purchasable = true
        product.averageRating = ""
        product.backordered = true
        product.backordersAllowed = false
        product.backordersKey = ""
        product.catalogVisibilityKey = ""
        product.dateCreated = Date()
        product.downloadable = true
        product.featured = true
        product.manageStock = true
        product.name = "product"
        product.onSale = true
        product.soldIndividually = true
        product.slug = ""
        product.shippingRequired = false
        product.shippingTaxable = false
        product.reviewsAllowed = true
        product.groupedProducts = []
        product.virtual = true
        product.stockStatusKey = ""
        product.statusKey = ""
        product.taxStatusKey = ""
        return product
    }

    func insertProductCategory(to context: NSManagedObjectContext) -> ProductCategory {
        let productCategory = context.insertNewObject(ofType: ProductCategory.self)
        // Populates the required attributes.
        productCategory.name = "testing"
        productCategory.slug = ""
        return productCategory
    }
}

/// Helpers for the Core Data migration tests
private extension CoreDataIterativeMigratorTests {

    var documentsDirectory: URL {
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last!
        return URL(fileURLWithPath: path)
    }
    private func urlForModel(name: String) -> URL {

        let bundle = Bundle(for: CoreDataManager.self)
        guard let path = bundle.paths(forResourcesOfType: "momd", inDirectory: nil).first,
            let url = bundle.url(forResource: name, withExtension: "mom", subdirectory: URL(fileURLWithPath: path).lastPathComponent) else {
            fatalError("Missing Model Resource")
        }

        return url
    }

    private func urlForStore(withName: String, deleteIfExists: Bool = false) -> URL {
        let storeURL = documentsDirectory.appendingPathComponent(withName)

        if deleteIfExists {
            try? FileManager.default.removeItem(at: storeURL)
        }

        try? FileManager.default.createDirectory(at: documentsDirectory, withIntermediateDirectories: true, attributes: nil)

        return storeURL
    }
}
