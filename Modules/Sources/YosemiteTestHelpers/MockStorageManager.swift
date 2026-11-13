import Foundation
import CoreData
@testable import Storage


/// MockStorageManager: InMemory CoreData Stack.
///
public final class MockStorageManager: StorageManagerType, Sendable {

    /// DataModel Name
    ///
    private static let name = "WooCommerce"

    /// Persistent Container: Holds the full CoreData Stack
    ///
    public let persistentContainer: NSPersistentContainer

    /// Returns a shared derived storage instance dedicated for write operations in the background.
    ///
    public let writerDerivedStorage: StorageType

    public init() {
        let container = NSPersistentContainer(name: Self.name, managedObjectModel: Self.managedModel)
        container.persistentStoreDescriptions = [Self.storeDescription]

        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("CoreData Fatal Error: \(error) [\(error.userInfo)]")
            }
        }

        let childManagedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        childManagedObjectContext.parent = container.viewContext
        childManagedObjectContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump

        self.persistentContainer = container
        self.writerDerivedStorage = childManagedObjectContext
    }

    /// Returns the Storage associated with the View Thread.
    ///
    public var viewStorage: StorageType {
        return persistentContainer.viewContext
    }

    /// Persists the Derived Storage's Changes.
    ///
    public func saveDerivedType(derivedStorage: StorageType, _ closure: @escaping () -> Void) {
        let viewStorage = self.viewStorage
        derivedStorage.perform {
            Self.saveChanges(in: derivedStorage)

            viewStorage.perform {
                Self.saveChanges(in: viewStorage)
                closure()
            }
        }
    }

    /// This method effectively destroys all of the stored data, and generates a blank Persistent Store from scratch.
    ///
    public func reset(onCompletion: (@Sendable () -> Void)?) {
        let storeCoordinator = persistentContainer.persistentStoreCoordinator
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

            storeCoordinator.addPersistentStore(with: Self.storeDescription) { _, error in
                guard let error else {
                    onCompletion?()
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
    public func performAndSave(_ operation: @escaping @Sendable (StorageType) -> Void,
                               completion: (@Sendable () -> Void)?,
                               on queue: DispatchQueue) {
        let context = persistentContainer.viewContext
        context.performAndWait {
            operation(context)
            Self.saveChanges(in: context)
            queue.async {
                completion?()
            }
        }
    }

    /// Handles a write operation using the background context and saves changes and returns result when done.
    /// Using view storage to write for simplicity in tests.
    ///
    public func performAndSave<T: Sendable>(_ operation: @escaping @Sendable (StorageType) throws -> T,
                                            completion: @escaping @Sendable (Result<T, Error>) -> Void,
                                            on queue: DispatchQueue) {
        let context = persistentContainer.viewContext
        context.performAndWait {
            let result = Result(catching: { try operation(context) })
            if case .success = result {
                Self.saveChanges(in: context)
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
    static var managedModel: NSManagedObjectModel {
        guard let mom = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Could not load model")
        }

        return mom
    }

    /// Returns the PersistentStore Descriptor
    ///
    static var storeDescription: NSPersistentStoreDescription {
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
    static var modelURL: URL {
        let bundle = Bundle.storage
        guard let url = bundle.url(forResource: name, withExtension: "momd") else {
            fatalError("Missing Model Resource")
        }

        return url
    }
}

private extension MockStorageManager {
    /// Saves the given storage's pending changes. Internal counterpart of the deprecated `saveIfNeeded()` below.
    ///
    static func saveChanges(in storage: StorageType) {
        let context = storage as! NSManagedObjectContext
        if context.hasChanges {
            try? context.save()
        }
    }
}

public extension StorageType {
    @available(*, deprecated, message: "Use `MockStorageManager`'s `performAndSave` to handle write operations instead of writing directly.")
    func saveIfNeeded() {
        let context = self as! NSManagedObjectContext
        if context.hasChanges {
            try? context.save()
        }
    }
}
