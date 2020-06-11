import XCTest
import CocoaLumberjack
import CoreData
@testable import Storage

class CoreDataIterativeMigratorTests: XCTestCase {

    override func setUp() {
        DDLog.add(DDOSLogger.sharedInstance)
    }

    override func tearDown() {
        DDLog.remove(DDOSLogger.sharedInstance)
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

        model = NSManagedObjectModel(contentsOf: model10URL)
        XCTAssertNotNil(model)
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

        model = NSManagedObjectModel(contentsOf: model10URL)
        XCTAssertNotNil(model)

        do {
            let modelNames = ["Model", "Model 2", "Model 3", "Model 4", "Model 5", "Model 6", "Model 7", "Model 8", "Model 9", "Model 10"]
            let (result, _) = try CoreDataIterativeMigrator.iterativeMigrate(sourceStore: storeURL, storeType: NSSQLiteStoreType, to: model!, using: modelNames)
            XCTAssertTrue(result)
        } catch {
            XCTFail("Error when attempting to migrate: \(error)")
        }

        psc = NSPersistentStoreCoordinator(managedObjectModel: model!)

        ps = try psc.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: options)

        XCTAssertNotNil(ps)
    }

}

/// Helpers for the Core Data migration tests
extension CoreDataIterativeMigratorTests {
    private func urlForModel(name: String) -> URL {

        let bundle = Bundle(for: CoreDataManager.self)
        guard let path = bundle.paths(forResourcesOfType: "momd", inDirectory: nil).first,
            let url = bundle.url(forResource: name, withExtension: "mom", subdirectory: URL(fileURLWithPath: path).lastPathComponent) else {
            fatalError("Missing Model Resource")
        }

        return url
    }

    private func urlForStore(withName: String, deleteIfExists: Bool = false) -> URL {
        let documentsDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last!
        let storeURL = URL(fileURLWithPath: documentsDirectory).appendingPathComponent(withName)

        if deleteIfExists {
            try? FileManager.default.removeItem(at: storeURL)
        }

        try? FileManager.default.createDirectory(at: URL(fileURLWithPath: documentsDirectory), withIntermediateDirectories: true, attributes: nil)

        return storeURL
    }
}
