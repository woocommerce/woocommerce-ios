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

    /// Persistent Container: Holds the full CoreData Stack
    ///
    /// TODO This should be private. It is not part of the `StorageManagerType` spec.
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

    /// Returns a new Derived Storage instance.
    ///
    public func newDerivedStorage() -> StorageType {
        let childManagedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        childManagedObjectContext.parent = persistentContainer.viewContext
        childManagedObjectContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return childManagedObjectContext
    }

    /// Persists the Derived Storage's Changes.
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

    /// Performs the received closure in Background. Note that you should use the received Storage instance (BG friendly!).
    ///
    public func performBackgroundTask(_ closure: @escaping (StorageType) -> Void) {
        persistentContainer.performBackgroundTask { context in
            closure(context as StorageType)
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
                for store in storeCoordinator.persistentStores {
                    try storeCoordinator.remove(store)
                }
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
        description.type = NSSQLiteStoreType
        description.url = URL(fileURLWithPath: "/dev/null")
        return description
    }
}


// MARK: - Stack URL's
//
extension MockupStorageManager {

    /// Returns the ManagedObjectModel's URL: Pick this up from the Storage bundle. OKAY?
    ///
    var modelURL: URL {
        let bundle = Bundle(for: CoreDataManager.self)
        guard let url = bundle.url(forResource: name, withExtension: "momd") else {
            fatalError("Missing Model Resource")
        }

        return url
    }
}
