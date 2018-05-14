import Foundation
import CoreData


/// CoreData Context Manager
///
public class ContextManager {

    /// ContextManager Identifier.
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


    /// Returns the Main Thread MOC
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


    /// Persists the specified NSManagedObjectContext instance
    ///
    public func saveContext(context: NSManagedObjectContext) {
        guard context.hasChanges else {
            return
        }

        do {
            try context.save()
        } catch {
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }
}


// MARK: - Descriptors
//
extension ContextManager {

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
        description.shouldAddStoreAsynchronously = true
        description.shouldMigrateStoreAutomatically = true
        return description
    }
}


// MARK: - Stack URL's
//
extension ContextManager {

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
