import CocoaLumberjackSwift
import CoreData
import Foundation
import Storage

/// In-memory `StorageManagerType` scoped to a single `WooAssistantHeadless`
/// instance. Mirrors the slice of `MockStorageManager`'s setup that the
/// harness providers actually use - `viewStorage` for synchronous reads
/// and `performAndSave` for upserts after dispatched actions.
///
/// The harness ships in the production binary, so we cannot reach the
/// Storage module's internal `Bundle.module`. We resolve the data model by
/// asking for the bundle that owns a public `Storage.Account` symbol; SPM
/// places the model resource alongside that bundle.
final class HeadlessInMemoryStorageManager: StorageManagerType {

    let viewStorage: StorageType

    private let persistentContainer: NSPersistentContainer

    init() {
        let bundle = Bundle(for: Storage.Account.self)
        guard let modelURL = bundle.url(forResource: "WooCommerce", withExtension: "momd"),
              let model = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("HeadlessInMemoryStorageManager could not locate WooCommerce.momd")
        }
        let container = NSPersistentContainer(name: "WooCommerce", managedObjectModel: model)
        let description = NSPersistentStoreDescription()
        description.type = NSSQLiteStoreType
        description.url = URL(fileURLWithPath: "/dev/null")
        description.shouldAddStoreAsynchronously = false
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { _, error in
            if let error {
                fatalError("HeadlessInMemoryStorageManager failed to load persistent store: \(error)")
            }
        }
        self.persistentContainer = container
        self.viewStorage = container.viewContext
    }

    func performAndSave(_ operation: @escaping (StorageType) -> Void,
                        completion: (() -> Void)?,
                        on queue: DispatchQueue) {
        let context = persistentContainer.viewContext
        context.performAndWait {
            operation(context)
            saveIfNeeded(context)
            queue.async { completion?() }
        }
    }

    func performAndSave<T>(_ operation: @escaping (StorageType) throws -> T,
                           completion: @escaping (Result<T, Error>) -> Void,
                           on queue: DispatchQueue) {
        let context = persistentContainer.viewContext
        context.performAndWait {
            let result = Result(catching: { try operation(context) })
            if case .success = result {
                saveIfNeeded(context)
            }
            queue.async { completion(result) }
        }
    }

    func reset(onCompletion: (() -> Void)?) {
        // Harness instances are short-lived and discarded; no caller resets storage.
        onCompletion?()
    }

    private func saveIfNeeded(_ storage: StorageType) {
        guard let context = storage as? NSManagedObjectContext, context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            DDLogError("HeadlessInMemoryStorageManager save failed: \(error)")
        }
    }
}
