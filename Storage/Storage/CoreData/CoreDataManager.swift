import Foundation
import CoreData


/// CoreDataManager: Manages the entire CoreData Stack. Conforms to the StorageManager API.
///
public class CoreDataManager: StorageManagerType {

    /// Storage Identifier.
    ///
    public let name: String


    /// Designated Initializer.
    ///
    /// - Parameter name: Identifier to be used for: [database, data model, container].
    ///
    /// - Important: This should *match* with your actual Data Model file!.
    ///
    public init(name: String) {
        self.name = name
    }


    /// Returns the Storage associated with the View Thread.
    ///
    public var viewStorage: StorageType {
        return viewContext
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

        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("CoreData Fatal Error: \(error) [\(error.userInfo)]")
            }
        })

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
extension CoreDataManager {

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
        let description = NSPersistentStoreDescription(url: storeURL)
        description.shouldAddStoreAsynchronously = false
        description.shouldMigrateStoreAutomatically = true
        return description
    }
}


// MARK: - Stack URL's
//
extension CoreDataManager {

    /// Returns the ManagedObjectModel's URL
    ///
    var modelURL: URL  {
        let bundle = Bundle(for: type(of: self))
        guard let url = bundle.url(forResource: name, withExtension: "momd") else {
            fatalError("Missing Model Resource")
        }

        return url
    }

    /// Returns the Store URL (the actual sqlite file!)
    ///
    var storeURL: URL {
        guard let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError("Okay: Missing Documents Folder?")
        }

        return url.appendingPathComponent(name + ".sqlite")
    }
}
