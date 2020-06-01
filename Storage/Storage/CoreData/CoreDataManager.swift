import Foundation
import CoreData


/// CoreDataManager: Manages the entire CoreData Stack. Conforms to the StorageManager API.
///
public class CoreDataManager: StorageManagerType {

    /// Storage Identifier.
    ///
    public let name: String

    private let crashLogger: CrashLogger

    /// Designated Initializer.
    ///
    /// - Parameter name: Identifier to be used for: [database, data model, container].
    ///
    /// - Important: This should *match* with your actual Data Model file!.
    ///
    public init(name: String, crashLogger: CrashLogger) {
        self.name = name
        self.crashLogger = crashLogger
    }


    /// Returns the Storage associated with the View Thread.
    ///
    public var viewStorage: StorageType {
        return persistentContainer.viewContext
    }

    /// Persistent Container: Holds the full CoreData Stack
    ///
    public lazy var persistentContainer: NSPersistentContainer = {
        migrateDataModelIfNecessary()

        let container = NSPersistentContainer(name: name, managedObjectModel: managedModel)
        container.persistentStoreDescriptions = [storeDescription]

        container.loadPersistentStores { [weak self] (storeDescription, error) in
            guard let `self` = self, let persistentStoreLoadingError = error else {
                return
            }

            DDLogError("⛔️ [CoreDataManager] loadPersistentStore failed. Attempting to recover... \(persistentStoreLoadingError)")

            /// Backup the old Store
            ///
            do {
                let sourceURL = self.storeURL
                let backupURL = sourceURL.appendingPathExtension("~")
                try FileManager.default.copyItem(at: sourceURL, to: backupURL)
            } catch {
                let message = "☠️ [CoreDataManager] Cannot backup Store: \(error)"
                self.crashLogger.logMessage(message,
                                            properties: ["persistentStoreLoadingError": persistentStoreLoadingError,
                                                         "backupError": error],
                                            level: .fatal)
                fatalError(message)
            }

            /// Remove the old Store
            ///
            do {
                try FileManager.default.removeItem(at: self.storeURL)
            } catch {
                let message = "☠️ [CoreDataManager] Cannot remove Store: \(error)"
                self.crashLogger.logMessage(message,
                                            properties: ["persistentStoreLoadingError": persistentStoreLoadingError,
                                                         "removeStoreError": error],
                                            level: .fatal)
                fatalError(message)
            }

            /// Retry!
            ///
            container.loadPersistentStores { [weak self] (storeDescription, error) in
                guard let error = error as NSError? else {
                    return
                }

                let message = "☠️ [CoreDataManager] Recovery Failed! \(error) [\(error.userInfo)]"
                self?.crashLogger.logMessage(message,
                                             properties: ["persistentStoreLoadingError": persistentStoreLoadingError,
                                                          "retryError": error],
                                             level: .fatal)
                fatalError(message)
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

            DDLogVerbose("💣 [CoreDataManager] Stack Destroyed!")
            NotificationCenter.default.post(name: .StorageManagerDidResetStorage, object: self)
        }
    }

    private func migrateDataModelIfNecessary() {
        guard FileManager.default.fileExists(atPath: storeURL.path) else {
            DDLogInfo("No store exists at URL \(storeURL).  Skipping migration.")
            return
        }

        guard let metadata = try? NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: NSSQLiteStoreType, at: storeURL, options: nil) else {
            return
        }

        guard managedModel.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata) == false else {
            // Configuration is compatible, no migration necessary.
            return
        }

        DDLogWarn("⚠️ [CoreDataManager] Migration required for persistent store")

        // Extract model names
        let versionPath = modelURL.appendingPathComponent(Constants.versionInfoPlist).path
        guard let versionInfo = NSDictionary(contentsOfFile: versionPath),
            let modelNames = versionInfo[Constants.versionHashesKey] as? NSDictionary,
            let allKeys = modelNames.allKeys as? [String],
            let objectModel = NSManagedObjectModel(contentsOf: modelURL) else {
            return
        }

        let sortedKeys = allKeys.sorted { (string1, string2) -> Bool in
            return string1.compare(string2, options: [.numeric], range: nil, locale: nil) == .orderedAscending
        }

        do {
            let migrateResult = try CoreDataIterativeMigrator.iterativeMigrate(sourceStore: storeURL,
                                                                               storeType: NSSQLiteStoreType,
                                                                               to: objectModel,
                                                                               using: sortedKeys)
            if migrateResult == false {
                DDLogError("☠️ [CoreDataManager] Unable to migrate store.")
            }
        } catch {
            DDLogError("☠️ [CoreDataManager] Unable to migrate store with error: \(error)")
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
