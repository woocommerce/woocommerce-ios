import Foundation
import CoreData
@testable import Storage


/// MockStorageManager: InMemory CoreData Stack.
///
public class MockStorageManager: StorageManagerType {

    /// DataModel Name
    ///
    private let name = "WooCommerce"

    /// Returns the Storage associated with the View Thread.
    ///
    public var viewStorage: StorageType {
        return persistentContainer.viewContext
    }

    /// Returns a shared derived storage instance dedicated for write operations.
    ///
    public lazy var writerDerivedStorage: StorageType = {
        let childManagedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        childManagedObjectContext.parent = persistentContainer.viewContext
        childManagedObjectContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return childManagedObjectContext
    }()

    /// Persistent Container: Holds the full CoreData Stack
    ///
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: name, managedObjectModel: managedModel)
        container.persistentStoreDescriptions = [storeDescription]

        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("CoreData Fatal Error: \(error) [\(error.userInfo)]")
            }
        }

        return container
    }()

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

    /// Handles a write operation using the background context and saves changes when done.
    /// Using view storage to write for simplicity in tests
    ///
    public func performAndSave(_ closure: @escaping (StorageType) -> Void,
                               completion: (() -> Void)?,
                               on queue: DispatchQueue) {
        let context = persistentContainer.viewContext
        context.performAndWait {
            closure(context)
            context.saveIfNeeded()
            queue.async {
                completion?()
            }
        }
    }

    /// Handles a write operation using the background context and saves changes and returns result when done.
    /// Using view storage to write for simplicity in tests.
    ///
    public func performAndSave<T>(_ closure: @escaping (StorageType) throws -> T,
                                  completion: @escaping (Result<T, Error>) -> Void,
                                  on queue: DispatchQueue) {
        let context = persistentContainer.viewContext
        context.performAndWait {
            let result = Result(catching: { try closure(context) })
            if case .success = result {
                context.saveIfNeeded()
            }
            queue.async {
                completion(result)
            }
        }
    }
}


// MARK: - Descriptors
//
extension MockStorageManager {

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
extension MockStorageManager {

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
