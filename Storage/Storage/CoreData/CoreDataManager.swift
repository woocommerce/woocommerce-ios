import Foundation
import CoreData
import CocoaLumberjack


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
        return persistentContainer.viewContext
    }

    /// Persistent Container: Holds the full CoreData Stack
    ///
    public lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: name, managedObjectModel: managedModel)
        container.persistentStoreDescriptions = [storeDescription]

        container.loadPersistentStores { [weak self] (storeDescription, error) in
            guard let `self` = self, let error = error else {
                return
            }

            DDLogError("⛔️ [CoreDataManager] loadPersistentStore failed. Attempting to recover... \(error)")

            /// Backup the old Store
            ///
            do {
                let sourceURL = self.storeURL
                let backupURL = sourceURL.appendingPathExtension("~")
                try FileManager.default.copyItem(at: sourceURL, to: backupURL)
                try FileManager.default.removeItem(at: sourceURL)
            } catch {
                fatalError("☠️ [CoreDataManager] Cannot backup Store: \(error)")
            }

            /// Retry!
            ///
            container.loadPersistentStores { [weak self] (storeDescription, error) in
                guard let error = error as NSError? else {
                    return
                }

                fatalError("☠️ [CoreDataManager] Recovery Failed! \(error) [\(error.userInfo)]")
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

    /// Creates a new child MOC (with a private dispatch queue) whose parent is `viewStorage`.
    ///
    public func newDerivedStorage() -> StorageType {
        let childManagedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        childManagedObjectContext.parent = persistentContainer.viewContext
        childManagedObjectContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return childManagedObjectContext
    }

    /// Saves the derived storage. Note: the closure may be called on a different thread
    ///
    public func saveDerivedType(derivedStorage: StorageType, _ closure: @escaping () -> Void) {
        derivedStorage.perform {
            derivedStorage.saveIfNeeded()

            self.viewStorage.perform {
                self.viewStorage.saveIfNeeded()
                closure()
            }
        }
    }

    /// This method effectively destroys all of the stored data, and generates a blank Persistent Store from scratch.
    ///
    public func reset() {
        let storeCoordinator = persistentContainer.persistentStoreCoordinator
        let storeDescriptor = self.storeDescription
        let viewContext = persistentContainer.viewContext

        viewContext.performAndWait {
            do {
                viewContext.reset()
                try storeCoordinator.destroyPersistentStore(at: self.storeURL, ofType: storeDescriptor.type, options: storeDescriptor.options)
            } catch {
                fatalError("☠️ [CoreDataManager] Cannot Destroy persistentStore! \(error)")
            }

            storeCoordinator.addPersistentStore(with: storeDescriptor) { (_, error) in
                guard let error = error else {
                    return
                }

                fatalError("☠️ [CoreDataManager] Unable to regenerate Persistent Store! \(error)")
            }

            NSLog("💣 [CoreDataManager] Stack Destroyed!")
            NotificationCenter.default.post(name: .StorageManagerDidResetStorage, object: self)
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
    var modelURL: URL {
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
