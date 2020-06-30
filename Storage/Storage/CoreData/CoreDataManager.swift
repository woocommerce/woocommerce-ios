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

            /// Backup the old Store
            ///
            var persistentStoreBackupError: Error?
            do {
                let sourceURL = self.storeURL
                let backupURL = sourceURL.appendingPathExtension("~")
                try FileManager.default.copyItem(at: sourceURL, to: backupURL)
            } catch {
                persistentStoreBackupError = error
            }

            /// Remove the old Store
            ///
            var persistentStoreRemovalError: Error?
            do {
                try FileManager.default.removeItem(at: self.storeURL)
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
                                                     "persistentStoreBackupError": persistentStoreBackupError,
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
                                                 "persistentStoreBackupError": persistentStoreBackupError,
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

        guard let metadata = try? NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: NSSQLiteStoreType, at: storeURL, options: nil) else {
            debugMessages.append("Cannot get metadata for persistent store at URL \(storeURL)")
            return debugMessages
        }

        guard modelsInventory.currentModel.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata) == false else {
            // Configuration is compatible, no migration necessary.
            return debugMessages
        }

        let migrationRequiredMessage = "⚠️ [CoreDataManager] Migration required for persistent store"
        debugMessages.append(migrationRequiredMessage)
        DDLogWarn(migrationRequiredMessage)

        // Extract model names
        let versionPath = modelURL.appendingPathComponent(Constants.versionInfoPlist).path
        guard let versionInfo = NSDictionary(contentsOfFile: versionPath),
            let modelNames = versionInfo[Constants.versionHashesKey] as? NSDictionary,
            let allKeys = modelNames.allKeys as? [String],
            let objectModel = NSManagedObjectModel(contentsOf: modelURL) else {
                debugMessages.append("Cannot get all model version names and/or the destination model")
                return debugMessages
        }

        let sortedKeys = allKeys.sorted { (string1, string2) -> Bool in
            return string1.compare(string2, options: [.numeric], range: nil, locale: nil) == .orderedAscending
        }

        do {
            let iterativeMigrator = CoreDataIterativeMigrator()
            let (migrateResult, migrationDebugMessages) = try iterativeMigrator.iterativeMigrate(sourceStore: storeURL,
                                                                                                 storeType: NSSQLiteStoreType,
                                                                                                 to: objectModel,
                                                                                                 using: sortedKeys)
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


// MARK: - Constants!
//
private extension CoreDataManager {

    enum Constants {
        static let versionInfoPlist = "VersionInfo.plist"
        static let versionHashesKey = "NSManagedObjectModel_VersionHashes"
    }
}
