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
            crashLogger.logFatalErrorAndExit(error, userInfo: ["storageUsage": Self.storageSizeLogProperties() as Any])
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
                                                     "migrationMessages": migrationDebugMessages,
                                                     "storageUsage": Self.storageSizeLogProperties()]
                self?.crashLogger.logFatalErrorAndExit(error,
                                                       userInfo: logProperties.compactMapValues { $0 })
            }

            let logProperties: [String: Any?] = ["persistentStoreLoadingError": persistentStoreLoadingError,
                                                 "persistentStoreRemovalError": persistentStoreRemovalError,
                                                 "appState": UIApplication.shared.applicationState.rawValue,
                                                 "migrationMessages": migrationDebugMessages,
                                                 "storageUsage": Self.storageSizeLogProperties()]
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
        let viewContext = persistentContainer.viewContext

        viewContext.performAndWait {
            viewContext.reset()
            self.deleteAllStoredObjects()

            DDLogVerbose("💣 [CoreDataManager] Stack Destroyed!")
            NotificationCenter.default.post(name: .StorageManagerDidResetStorage, object: self)
        }
    }

    private func deleteAllStoredObjects() {
        let storeCoordinator = persistentContainer.persistentStoreCoordinator
        let viewContext = persistentContainer.viewContext
        do {
            let entities = storeCoordinator.managedObjectModel.entities
            for entity in entities {
                guard let entityName = entity.name else {
                    continue
                }
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
                let objects = try viewContext.fetch(fetchRequest) as? [NSManagedObject]
                objects?.forEach { object in
                    viewContext.delete(object)
                }
                viewContext.saveIfNeeded()
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

    /// Note that we have to enumerate all the files in our sandbox to get these properties, so this takes some time.
    /// It is intended _only_ for use when logging a crash, or other high-value log which won't get in the user's way.
    private static func storageSizeLogProperties() -> [String: Int64]? {
        let directoryUrls: [String: URL] = [
            "Bundle": Bundle.main.bundleURL,
            "Documents": FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first,
            "Library": FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first,
            "Temp": FileManager.default.temporaryDirectory,
        ].compactMapValues { $0 }

        let directorySizes = directoryUrls.mapValues { url in
            getAllocatedStorageSize(for: url)
        }

        let totalSize = directorySizes.values.reduce(0) { partialResult, size in
            return partialResult + size
        }

        return directorySizes.merging(["Total": totalSize]) { first, _ in
            first
        }
    }

    /// Getting the size on disk isn't straightforward – this does not take into account all extended attributes, for example.
    /// Generally the value returned here is an underestimate, but within 10% of the value iOS settings reports.
    /// Using `fileAllocatedSize` as a fallback helps avoid counting some files as 0.
    private static func getAllocatedStorageSize(for url: URL) -> Int64 {
        let fileSizeKeys: [URLResourceKey] = [.totalFileAllocatedSizeKey, .fileAllocatedSizeKey]
        guard let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: fileSizeKeys) else {
            return 0
        }

        var totalSize: Int64 = 0

        for case let fileUrl as URL in enumerator {
            if let fileSizeResource = try? fileUrl.resourceValues(forKeys: Set(fileSizeKeys)),
               let fileSize = fileSizeResource.totalFileAllocatedSize ?? fileSizeResource.fileAllocatedSize {
                totalSize += Int64(fileSize)
            }
        }

        return totalSize
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
