import Foundation
import CoreData
import WooFoundation


/// CoreDataManager: Manages the entire CoreData Stack. Conforms to the StorageManager API.
///
public final class CoreDataManager: StorageManagerType {

    /// Storage Identifier.
    ///
    public let name: String

    private let crashLogger: CrashLogger

    private let modelsInventory: ManagedObjectModelsInventory

    /// A serial queue used to ensure there is only one writing operation at a time.
    private let writerQueue: OperationQueue

    /// Module-private designated Initializer.
    ///
    /// - Parameter name: Identifier to be used for: [database, data model, container].
    /// - Parameter crashLogger: allows logging a message of any severity level
    /// - Parameter modelsInventory: The models to load when spinning up the Core Data stack.
    ///     This is automatically generated if `nil`. You would probably only specify this for
    ///     unit tests to test migration and/or recovery scenarios.
    ///
    /// - Important: This should *match* with your actual Data Model file!.
    ///
    init(name: String,
         crashLogger: CrashLogger,
         modelsInventory: ManagedObjectModelsInventory?) {
        self.name = name
        self.crashLogger = crashLogger
        self.writerQueue = OperationQueue()
        self.writerQueue.name = "com.automattic.woocommerce.CoreDataManager.writer"
        self.writerQueue.maxConcurrentOperationCount = 1

        do {
            if let modelsInventory = modelsInventory {
                self.modelsInventory = modelsInventory
            } else {
                self.modelsInventory = try .from(packageName: name, bundle: Bundle(for: type(of: self)))
            }
        } catch {
            // We'll throw a fatalError() because we can't really proceed without a
            // ManagedObjectModel.
            let error = CoreDataManagerError.modelInventoryLoadingFailed(name, error)
            crashLogger.logFatalErrorAndExit(error, userInfo: nil)
        }
    }

    /// Public designated initializer.
    ///
    /// - Parameter name: Identifier to be used for: [database, data model, container].
    /// - Parameter crashLogger: allows logging a message of any severity level
    ///
    /// - Important: This should *match* with your actual Data Model file!.
    ///
    public convenience init(name: String, crashLogger: CrashLogger) {
        self.init(name: name, crashLogger: crashLogger, modelsInventory: nil)
    }

    /// Returns the Storage associated with the View Thread.
    ///
    public var viewStorage: StorageType {
        let context = persistentContainer.viewContext
        /// This simplifies the process of merging updates from persistent container to view context.
        /// When disable auto merge, we need to handle merging manually using `NSManagedObjectContextDidSave` notifications.
        context.automaticallyMergesChangesFromParent = true
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }

    /// Returns a shared derived storage instance dedicated for write operations.
    ///
    public lazy var writerDerivedStorage: StorageType = {
        let backgroundContext = persistentContainer.newBackgroundContext()
        backgroundContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return backgroundContext
    }()

    /// Persistent Container: Holds the full CoreData Stack
    ///
    public lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: name, managedObjectModel: modelsInventory.currentModel)
        container.persistentStoreDescriptions = [storeDescription]

        let migrationDebugMessages = migrateDataModelIfNecessary(using: container.persistentStoreCoordinator)

        container.loadPersistentStores { [weak self] (storeDescription, error) in
            guard let `self` = self, let persistentStoreLoadingError = error else {
                return
            }

            DDLogError("⛔️ [CoreDataManager] loadPersistentStore failed. Attempting to recover... \(persistentStoreLoadingError)")

            /// Remove the old Store which is either corrupted or has an invalid model we can't migrate from
            ///
            var persistentStoreRemovalError: Error?
            do {
                try container.persistentStoreCoordinator.destroyPersistentStore(at: self.storeURL,
                                                                                ofType: storeDescription.type,
                                                                                options: nil)
                NotificationCenter.default.post(name: .StorageManagerDidResetStorage, object: self)

            } catch {
                persistentStoreRemovalError = error
            }

            /// Retry!
            ///
            container.loadPersistentStores { [weak self] (storeDescription, underlyingError) in
                guard let underlyingError = underlyingError as NSError? else {
                    return
                }

                let error = CoreDataManagerError.recoveryFailed
                let logProperties: [String: Any?] = ["persistentStoreLoadingError": persistentStoreLoadingError,
                                                     "persistentStoreRemovalError": persistentStoreRemovalError,
                                                     "retryError": underlyingError,
                                                     "appState": UIApplication.shared.applicationState.rawValue,
                                                     "migrationMessages": migrationDebugMessages]
                self?.crashLogger.logFatalErrorAndExit(error,
                                                       userInfo: logProperties.compactMapValues { $0 })
            }

            let logProperties: [String: Any?] = ["persistentStoreLoadingError": persistentStoreLoadingError,
                                                 "persistentStoreRemovalError": persistentStoreRemovalError,
                                                 "appState": UIApplication.shared.applicationState.rawValue,
                                                 "migrationMessages": migrationDebugMessages]
            self.crashLogger.logMessage("[CoreDataManager] Recovered from persistent store loading error",
                                        properties: logProperties.compactMapValues { $0 },
                                        level: .info)
        }

        return container
    }()

    /// Saves the derived storage. Note: the closure may be called on a different thread
    ///
    public func saveDerivedType(derivedStorage: StorageType, _ closure: @escaping () -> Void) {
        derivedStorage.perform {
            derivedStorage.saveIfNeeded()
            closure()
        }
    }

    /// Execute the given operation with a background context and save the changes.
    ///
    /// This function _does not block_ its running thread. The operation is executed in background and its return value
    /// is passed onto the `completion` closure which is executed on the given `queue`.
    ///
    /// - Parameters:
    ///   - operation: A closure which uses the given `StorageType` to make data changes in background.
    ///   - completion: A closure which is called after the changed made by the `operation` is saved.
    ///   - queue: A queue on which to execute the completion closure.
    public func performAndSave(_ operation: @escaping (StorageType) -> Void,
                               completion: (() -> Void)?,
                               on queue: DispatchQueue) {
        let derivedStorage = writerDerivedStorage
        writerQueue.addOperation(AsyncBlockOperation { done in
            derivedStorage.perform {
                operation(derivedStorage)

                derivedStorage.saveIfNeeded()
                queue.async { completion?() }
                done()
            }
        })
    }

    /// Execute the given `operation` with a background context, save the changes, and return the result.
    ///
    /// This function _does not block_ its running thread. The operation is executed in background and its return value
    /// is passed onto the `completion` closure which is executed on the given `queue`.
    ///
    /// - Parameters:
    ///   - operation: A closure which uses the given `StorageType` to make data changes in background.
    ///   - completion: A closure which is called with the `operation`'s execution result,
    ///   which is either an error thrown by the `operation` or the return value of the `operation`.
    ///   - queue: A queue on which to execute the completion closure.
    public func performAndSave<T>(_ operation: @escaping (StorageType) throws -> T,
                                  completion: @escaping (Result<T, Error>) -> Void,
                                  on queue: DispatchQueue) {
        assert((T.self is NSManagedObject.Type) == false, "Managed objects should not be sent between different contexts to avoid threading issues.")
        let derivedStorage = writerDerivedStorage
        writerQueue.addOperation(AsyncBlockOperation { done in
            derivedStorage.perform {
                let result = Result(catching: { try operation(derivedStorage) })
                if case .success = result {
                    derivedStorage.saveIfNeeded()
                }
                queue.async { completion(result) }
                done()
            }
        })
    }

    /// This method effectively destroys all of the stored data, and generates a blank Persistent Store from scratch.
    ///
    public func reset() {
        /// Reset the view context first
        let viewContext = persistentContainer.viewContext
        viewContext.performAndWait {
            viewContext.reset()
            self.deleteAllStoredObjects(in: viewContext)
            viewContext.saveIfNeeded()
        }

        /// Delete all objects in the background context to avoid discrepancy with the view context
        performAndSave({ storage in
            guard let backgroundContext = storage as? NSManagedObjectContext else {
                DDLogError("⛔️ CoreDataManager failed to reset due to unexpected storage type!")
                return
            }
            /// persist self to complete deleting objects
            self.deleteAllStoredObjects(in: backgroundContext)
            backgroundContext.reset()
        }, completion: {
            DDLogVerbose("💣 [CoreDataManager] Stack Destroyed!")
            NotificationCenter.default.post(name: .StorageManagerDidResetStorage, object: self)
        }, on: .main)
    }

    private func deleteAllStoredObjects(in context: NSManagedObjectContext) {
        let storeCoordinator = persistentContainer.persistentStoreCoordinator
        do {
            let entities = storeCoordinator.managedObjectModel.entities
            for entity in entities {
                guard let entityName = entity.name else {
                    continue
                }
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
                let objects = try context.fetch(fetchRequest) as? [NSManagedObject]
                objects?.forEach { object in
                    context.delete(object)
                }
            }
        } catch {
            logErrorAndExit("☠️ [CoreDataManager] Cannot delete stored objects! \(error)")
        }
    }

    /// Migrates the current persistent store to the latest data model if needed.
    /// - Returns: an array of debug messages for logging. Please feel free to remove when #2371 is resolved.
    private func migrateDataModelIfNecessary(using coordinator: NSPersistentStoreCoordinator) -> [String] {
        var debugMessages = [String]()

        let migrationCheckMessage = "ℹ️ [CoreDataManager] Checking if migration is necessary."
        debugMessages.append(migrationCheckMessage)
        DDLogInfo(migrationCheckMessage)

        do {
            let iterativeMigrator = CoreDataIterativeMigrator(coordinator: coordinator, modelsInventory: modelsInventory)
            let (migrateResult, migrationDebugMessages) = try iterativeMigrator.iterativeMigrate(sourceStore: storeURL,
                                                                                                 storeType: NSSQLiteStoreType,
                                                                                                 to: modelsInventory.currentModel)
            debugMessages += migrationDebugMessages
            if migrateResult == false {
                let migrationFailureMessage = "☠️ [CoreDataManager] Unable to migrate store."
                debugMessages.append(migrationFailureMessage)
                DDLogError(migrationFailureMessage)
            }

            return debugMessages
        } catch {
            let migrationErrorMessage = "☠️ [CoreDataManager] Unable to migrate store with error: \(error)"
            debugMessages.append(migrationErrorMessage)
            DDLogError(migrationErrorMessage)
            return debugMessages
        }
    }
}


// MARK: - Descriptors
//
extension CoreDataManager {
    /// Returns the PersistentStore Descriptor
    ///
    var storeDescription: NSPersistentStoreDescription {
        let description = NSPersistentStoreDescription(url: storeURL)
        description.shouldAddStoreAsynchronously = false
        description.shouldMigrateStoreAutomatically = false
        return description
    }
}


// MARK: - Stack URL's
//
extension CoreDataManager {
    /// Returns the Store URL (the actual sqlite file!)
    ///
    var storeURL: URL {
        guard let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            logErrorAndExit("Okay: Missing Documents Folder?")
        }

        return url.appendingPathComponent(name + ".sqlite")
    }
}

// MARK: - Errors
//
enum CoreDataManagerError: Error {
    case modelInventoryLoadingFailed(String, Error)
    case recoveryFailed
}

extension CoreDataManagerError: CustomStringConvertible {
    var description: String {
        switch self {
        case .modelInventoryLoadingFailed(let name, let underlyingError):
            return "Failed to load models inventory using packageName \(name). Error: \(underlyingError)"
        case .recoveryFailed:
            return "☠️ [CoreDataManager] Recovery Failed!"
        }
    }
}

/// Helper types to support writing operations to be handled one by one.
/// This implementation follows WP/JP's work at
/// WordPress/Classes/Utility/ContextManager.swift#L131
///
extension CoreDataManager {
    /// Helper type to support handling async operations by keeping track of their states
    class AsyncOperation: Operation, @unchecked Sendable {
        enum State: String {
            case isReady, isExecuting, isFinished
        }

        override var isAsynchronous: Bool {
            return true
        }

        var state = State.isReady {
            willSet {
                willChangeValue(forKey: state.rawValue)
                willChangeValue(forKey: newValue.rawValue)
            }
            didSet {
                didChangeValue(forKey: oldValue.rawValue)
                didChangeValue(forKey: state.rawValue)
            }
        }

        override var isExecuting: Bool {
            return state == .isExecuting
        }

        override var isFinished: Bool {
            return state == .isFinished
        }

        override func start() {
            if isCancelled {
                state = .isFinished
                return
            }

            state = .isExecuting
            main()
        }
    }

    /// Helper type to handle async operations given a closure of code to be executed.
    final class AsyncBlockOperation: AsyncOperation, @unchecked Sendable {

        private let block: (@escaping () -> Void) -> Void

        init(block: @escaping (@escaping () -> Void) -> Void) {
            self.block = block
        }

        override func main() {
            self.block { [weak self] in
                self?.state = .isFinished
            }
        }

    }
}
