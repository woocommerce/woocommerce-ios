import Foundation
import CoreData


/// CoreDataManager: Manages the entire CoreData Stack. Conforms to the StorageManager API.
///
public final class CoreDataManager: StorageManagerType {

    /// Storage Identifier.
    ///
    public let name: String

    private let crashLogger: CrashLogger

    private let modelsInventory: ManagedObjectModelsInventory

    private lazy var mutableContext: NSManagedObjectContext = {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.parent = persistentContainer.viewContext
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }()

    private let writingSerialOperationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "serial.queue.for.mutableContext"
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .userInitiated
        return queue
    }()

    private let mutableContextTransactionSemaphore = DispatchSemaphore(value: 1)

    /// Designated Initializer.
    ///
    /// - Parameter name: Identifier to be used for: [database, data model, container].
    /// - Parameter crashLogger: allows logging a message of any severity level
    ///
    /// - Important: This should *match* with your actual Data Model file!.
    ///
    public init(name: String, crashLogger: CrashLogger) {
        self.name = name
        self.crashLogger = crashLogger

        do {
            self.modelsInventory = try .from(packageName: name, bundle: Bundle(for: type(of: self)))
        } catch {
            // We'll throw a fatalError() because we can't really proceed without a
            // ManagedObjectModel.
            let message = "Failed to load models inventory using packageName \(name). Error: \(error)"
            crashLogger.logMessageAndWait(message, properties: nil, level: .fatal)

            fatalError(message)
        }
    }

    /// Returns the Storage associated with the View Thread.
    ///
    public var viewStorage: StorageType {
        return persistentContainer.viewContext
    }

    /// Persistent Container: Holds the full CoreData Stack
    ///
    public lazy var persistentContainer: NSPersistentContainer = {
        let migrationDebugMessages = migrateDataModelIfNecessary()

        let container = NSPersistentContainer(name: name, managedObjectModel: self.modelsInventory.currentModel)
        container.persistentStoreDescriptions = [storeDescription]

        container.loadPersistentStores { [weak self] (storeDescription, error) in
            guard let `self` = self, let persistentStoreLoadingError = error else {
                return
            }

            DDLogError("⛔️ [CoreDataManager] loadPersistentStore failed. Attempting to recover... \(persistentStoreLoadingError)")

            /// Remove the old Store which is either corrupted or has an invalid model we can't migrate from
            ///
            var persistentStoreRemovalError: Error?
            do {
                let fileManager = FileManager.default
                let pathToStore = self.storeURL.deletingLastPathComponent().path
                let files = try fileManager.contentsOfDirectory(atPath: pathToStore)
                try files.forEach { (file) in
                    if file.hasPrefix(self.storeURL.lastPathComponent) {
                        let fullPath = URL(fileURLWithPath: pathToStore).appendingPathComponent(file).path
                        try fileManager.removeItem(atPath: fullPath)
                    }
                }
            } catch {
                persistentStoreRemovalError = error
            }

            /// Retry!
            ///
            container.loadPersistentStores { [weak self] (storeDescription, error) in
                guard let error = error as NSError? else {
                    return
                }

                let message = "☠️ [CoreDataManager] Recovery Failed!"

                let logProperties: [String: Any?] = ["persistentStoreLoadingError": persistentStoreLoadingError,
                                                     "persistentStoreRemovalError": persistentStoreRemovalError,
                                                     "retryError": error,
                                                     "appState": UIApplication.shared.applicationState.rawValue,
                                                     "migrationMessages": migrationDebugMessages]
                self?.crashLogger.logMessageAndWait(message,
                                                    properties: logProperties.compactMapValues { $0 },
                                                    level: .fatal)
                fatalError(message)
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

            DDLogVerbose("💣 [CoreDataManager] Stack Destroyed!")
            NotificationCenter.default.post(name: .StorageManagerDidResetStorage, object: self)
        }
    }

    /// Migrates the current persistent store to the latest data model if needed.
    /// - Returns: an array of debug messages for logging. Please feel free to remove when #2371 is resolved.
    private func migrateDataModelIfNecessary() -> [String] {
        var debugMessages = [String]()

        guard FileManager.default.fileExists(atPath: storeURL.path) else {
            let noStoreMessage = "No store exists at URL \(storeURL).  Skipping migration."
            debugMessages.append(noStoreMessage)
            DDLogInfo(noStoreMessage)
            return debugMessages
        }

        let metadata: [String: Any]
        do {
            metadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: NSSQLiteStoreType, at: storeURL, options: nil)
        } catch {
            debugMessages.append("Cannot get metadata for persistent store at URL \(storeURL): \(error)")
            return debugMessages
        }

        guard modelsInventory.currentModel.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata) == false else {
            // Configuration is compatible, no migration necessary.
            return debugMessages
        }

        let migrationRequiredMessage = "⚠️ [CoreDataManager] Migration required for persistent store"
        debugMessages.append(migrationRequiredMessage)
        DDLogWarn(migrationRequiredMessage)

        do {
            let iterativeMigrator = CoreDataIterativeMigrator(modelsInventory: modelsInventory)
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

    public func write(_ closure: @escaping (TransactionType) throws -> Void,
                      completion: ((Result<Void, Error>) -> Void)?) {
        let operation = TransactionOperation(mutableContext,
                                             viewContext: persistentContainer.viewContext,
                                             blockToExecute: closure)
        operation.completionBlock = {
            if let result = operation.result {
                completion?(result)
            }
        }
        writingSerialOperationQueue.addOperation(operation)
    }
}

private class TransactionOperation: Operation {
    private let mutableContext: NSManagedObjectContext
    private let viewContext: NSManagedObjectContext
    private let blockToExecute: (TransactionType) throws -> Void

    private(set) var result: Result<Void, Error>?

    init(_ context: NSManagedObjectContext,
         viewContext: NSManagedObjectContext,
         blockToExecute: @escaping (TransactionType) throws -> Void) {
        self.mutableContext = context
        self.viewContext = viewContext
        self.blockToExecute = blockToExecute
    }

    override func main() {
        guard !isCancelled else {
            return
        }

        mutableContext.performAndWait {
            guard !isCancelled else { return }

            let transaction = Transaction(self.mutableContext)

            do {
                try self.blockToExecute(transaction)

                guard !isCancelled else { return }

                // TODO can be replaced with a throwing saveIfNeeded version
                self.mutableContext.saveIfNeeded()

                guard !isCancelled else { return }

                self.viewContext.performAndWait {
                    guard !isCancelled else { return }

                    // TODO can be replaced with a throwing saveIfNeeded version
                    self.viewContext.saveIfNeeded()
                }

                guard !isCancelled else { return }

                self.result = .success(())
            } catch {
                self.mutableContext.rollback()
                self.result = .failure(error)
            }
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
            fatalError("Okay: Missing Documents Folder?")
        }

        return url.appendingPathComponent(name + ".sqlite")
    }
}
