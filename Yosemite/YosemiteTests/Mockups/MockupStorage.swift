import Foundation
import CoreData
@testable import Storage


/// MockupStorageManager: InMemory CoreData Stack.
///
public class MockupStorageManager: StorageManagerType {

    /// DataModel Name
    ///
    private let name = "WooCommerce"

    /// Returns the Storage associated with the View Thread.
    ///
    public var viewStorage: StorageType {
        return persistentContainer.viewContext
    }

    /// Returns the NSManagedObjectContext associated with the Main Thread. Convenience helper!!
    ///
    public var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    /// Persistent Container: Holds the full CoreData Stack
    ///
    public lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: name, managedObjectModel: managedModel)
        container.persistentStoreDescriptions = [storeDescription]

        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("CoreData Fatal Error: \(error) [\(error.userInfo)]")
            }
        }

        return container
    }()

    /// Performs the received closure in Background. Note that you should use the received Storage instance (BG friendly!).
    ///
    public func performBackgroundTask(_ closure: @escaping (StorageType) -> Void) {
        persistentContainer.performBackgroundTask { context in
            closure(context as StorageType)
        }
    }
}


// MARK: - Descriptors
//
extension MockupStorageManager {

    /// Returns the Application's ManagedObjectModel
    ///
    var managedModel: NSManagedObjectModel {
        guard let mom = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Could not load model")
        }

        return mom
    }

    /// Returns the PersistentStore Descriptor
    ///
    var storeDescription: NSPersistentStoreDescription {
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        return description
    }
}


// MARK: - Stack URL's
//
extension MockupStorageManager {

    /// Returns the ManagedObjectModel's URL: Pick this up from the Storage bundle. OKAY?
    ///
    var modelURL: URL  {
        let bundle = Bundle(for: CoreDataManager.self)
        guard let url = bundle.url(forResource: name, withExtension: "momd") else {
            fatalError("Missing Model Resource")
        }

        return url
    }
}
