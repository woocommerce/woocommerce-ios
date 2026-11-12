import Foundation
import CoreData
@testable import Storage


/// MockStorageManager: SQLite CoreData Stack that is private to each instance.
///
public final class MockStorageManager: StorageManagerType, Sendable {

    /// DataModel Name
    ///
    private static let name = "WooCommerce"

    /// Persistent Container: Holds the full CoreData Stack. Loaded on first use, so tests that never touch storage skip it.
    ///
    public var persistentContainer: NSPersistentContainer {
        loadedStack.container
    }

    /// Returns a shared derived storage instance dedicated for write operations in the background.
    ///
    public var writerDerivedStorage: StorageType {
        loadedStack.writer
    }

    private let storeDirectory: URL

    /// Guarded by `stackLock`. Set once, on first use.
    nonisolated(unsafe) private var stack: (container: NSPersistentContainer, writer: StorageType)?
    private let stackLock = NSLock()

    public init() {
        storeDirectory = Self.templateDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    }

    private var loadedStack: (container: NSPersistentContainer, writer: StorageType) {
        stackLock.lock()
        defer { stackLock.unlock() }
        if let stack {
            return stack
        }

        let container = NSPersistentContainer(name: Self.name, managedObjectModel: Self.managedModel)
        container.persistentStoreDescriptions = [Self.makeStoreDescription(in: storeDirectory)]

        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("CoreData Fatal Error: \(error) [\(error.userInfo)]")
            }
        }

        let childManagedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        childManagedObjectContext.parent = container.viewContext
        childManagedObjectContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump

        // Contexts can outlive this manager and keep using the coordinator, so the files go away with the coordinator.
        objc_setAssociatedObject(container.persistentStoreCoordinator,
                                 &StoreFilesRemover.associationKey,
                                 StoreFilesRemover(directory: storeDirectory),
                                 .OBJC_ASSOCIATION_RETAIN)

        let created = (container: container, writer: childManagedObjectContext as StorageType)
        stack = created
        return created
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

            storeCoordinator.addPersistentStore(with: Self.makeStoreDescription(in: storeDirectory)) { _, error in
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

    /// Returns the Application's ManagedObjectModel. Decoding it takes milliseconds, and the model is immutable once used.
    ///
    nonisolated(unsafe) static let managedModel: NSManagedObjectModel = {
        guard let mom = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Could not load model")
        }

        return mom
    }()

    /// Returns a description for a new empty SQLite store.
    /// Creating the schema takes most of a stack's setup time, so each store starts as an APFS clone of one empty template.
    ///
    static func makeStoreDescription(in directory: URL) -> NSPersistentStoreDescription {
        let url = directory.appendingPathComponent("\(UUID().uuidString).sqlite")
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try FileManager.default.copyItem(at: templateStoreURL, to: url)
        } catch {
            // Tests cannot run without an isolated store, and a failed copy means the temporary directory is unusable.
            fatalError("Could not create the test store: \(error)")
        }
        let description = NSPersistentStoreDescription(url: url)
        description.type = NSSQLiteStoreType
        // Match the previous `/dev/null` store, which SQLite kept in memory. Only this instance opens the file, so an exclusive
        // lock is safe and keeps SQLite's page cache valid instead of rechecking the file on every fetch.
        description.setOption(["journal_mode": "MEMORY", "synchronous": "OFF", "locking_mode": "EXCLUSIVE"] as NSDictionary,
                              forKey: NSSQLitePragmasOption)
        return description
    }

    private static let directoryPrefix = "MockStorageManager-"

    private static let templateDirectory: URL = {
        removeDirectoriesOfEndedProcesses()
        let pid = ProcessInfo.processInfo.processIdentifier
        return FileManager.default.temporaryDirectory
            .appendingPathComponent("\(directoryPrefix)\(pid)-\(UUID().uuidString)", isDirectory: true)
    }()

    /// Stores whose contexts leak are never deallocated, so their files would otherwise accumulate across test runs.
    private static func removeDirectoriesOfEndedProcesses() {
        let fileManager = FileManager.default
        let names = (try? fileManager.contentsOfDirectory(atPath: fileManager.temporaryDirectory.path)) ?? []
        for name in names where name.hasPrefix(directoryPrefix) {
            let owner = name.dropFirst(directoryPrefix.count).split(separator: "-").first.flatMap { Int32($0) }
            // Directories without an owner process ID come from older versions of this helper.
            if let owner, kill(owner, 0) == 0 || errno != ESRCH {
                continue
            }
            try? fileManager.removeItem(at: fileManager.temporaryDirectory.appendingPathComponent(name))
        }
    }

    private static let templateStoreURL: URL = {
        let url = templateDirectory.appendingPathComponent("template.sqlite")
        let description = NSPersistentStoreDescription(url: url)
        description.type = NSSQLiteStoreType
        // Keep the template in one file so a single copy contains the full schema.
        description.setOption(["journal_mode": "DELETE"] as NSDictionary, forKey: NSSQLitePragmasOption)
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: managedModel)
        do {
            try FileManager.default.createDirectory(at: templateDirectory, withIntermediateDirectories: true)
            let store = try coordinator.addPersistentStore(type: .sqlite, at: url, options: description.options)
            try coordinator.remove(store)
        } catch {
            // Every storage-backed test depends on this template; without it no test store can be created.
            fatalError("Could not create the test store template: \(error)")
        }
        return url
    }()
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

/// Deletes a test store directory when its persistent store coordinator is deallocated.
private final class StoreFilesRemover {
    nonisolated(unsafe) static var associationKey: UInt8 = 0

    private let directory: URL

    init(directory: URL) {
        self.directory = directory
    }

    deinit {
        try? FileManager.default.removeItem(at: directory)
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
