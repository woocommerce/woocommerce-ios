import Foundation
import CoreData

/// CoreDataIterativeMigrator: Migrates through a series of models to allow for users to skip app versions without risk.
/// This was derived from ALIterativeMigrator originally used in the WordPress app.
///
final class CoreDataIterativeMigrator {

    private let fileManager: FileManagerProtocol

    private let modelsInventory: ManagedObjectModelsInventory

    init(modelsInventory: ManagedObjectModelsInventory, fileManager: FileManagerProtocol = FileManager.default) {
        self.modelsInventory = modelsInventory
        self.fileManager = fileManager
    }

    /// Migrates a store to a particular model using the list of models to do it iteratively, if required.
    ///
    /// - Parameters:
    ///     - sourceStore: URL of the store on disk.
    ///     - storeType: Type of store (usually NSSQLiteStoreType).
    ///     - to: The target/most current model the migrator should migrate to.
    ///     - using: List of models on disk, sorted in migration order, that should include the to: model.
    ///
    /// - Returns: True if the process succeeded and didn't run into any errors. False if there was any problem and the store was left untouched.
    ///
    /// - Throws: A whole bunch of crap is possible to be thrown between Core Data and FileManager.
    ///
    func iterativeMigrate(sourceStore: URL,
                          storeType: String,
                          to targetModel: NSManagedObjectModel) throws -> (success: Bool, debugMessages: [String]) {
        // If the persistent store does not exist at the given URL,
        // assume that it hasn't yet been created and return success immediately.
        guard fileManager.fileExists(atPath: sourceStore.path) == true else {
            return (true, [])
        }

        // Get the persistent store's metadata.  The metadata is used to
        // get information about the store's managed object model.
        guard let sourceMetadata = try metadataForPersistentStore(storeType: storeType, at: sourceStore) else {
            return (false, [])
        }

        // Check whether the final model is already compatible with the store.
        // If it is, no migration is necessary.
        guard targetModel.isConfiguration(withName: nil, compatibleWithStoreMetadata: sourceMetadata) == false else {
            return (true, [])
        }

        // Find the current model used by the store.
        guard let sourceModel = try model(for: sourceMetadata) else {
            return (false, [])
        }

        // Get NSManagedObjectModels for each of the model names given.
        let objectModels = try models(for: modelsInventory.versions)

        // Build an inclusive list of models between the source and final models.
        var modelsToMigrate = [NSManagedObjectModel]()
        var firstFound = false, lastFound = false, reverse = false

        for model in objectModels {
            if model.isEqual(sourceModel) || model.isEqual(targetModel) {
                if firstFound {
                    lastFound = true
                    // In case a reverse migration is being performed (descending through the
                    // ordered array of models), check whether the source model is found
                    // after the final model.
                    reverse = model.isEqual(sourceModel)
                } else {
                    firstFound = true
                }
            }

            if firstFound {
                modelsToMigrate.append(model)
            }

            if lastFound {
                break
            }
        }

        // Ensure that the source model is at the start of the list.
        if reverse {
            modelsToMigrate = modelsToMigrate.reversed()
        }

        var debugMessages = [String]()

        guard modelsToMigrate.count > 1 else {
            return (false, ["Skipping migration. Unexpectedly found less than 2 models to perform a migration."])
        }

        // Migrate between each model. Count - 2 because of zero-based index and we want
        // to stop at the last pair (you can't migrate the last model to nothingness).
        let upperBound = modelsToMigrate.count - 2
        for index in 0...upperBound {
            let modelFrom = modelsToMigrate[index]
            let modelTo = modelsToMigrate[index + 1]

            // Check whether a custom mapping model exists.
            guard let migrateWithModel = NSMappingModel(from: nil, forSourceModel: modelFrom, destinationModel: modelTo) ??
                (try? NSMappingModel.inferredMappingModel(forSourceModel: modelFrom, destinationModel: modelTo)) else {
                    return (false, debugMessages)
            }

            // Migrate the model to the next step
            let migrationAttemptMessage = makeMigrationAttemptLogMessage(models: objectModels, from: modelFrom, to: modelTo)
            debugMessages.append(migrationAttemptMessage)
            DDLogWarn(migrationAttemptMessage)

            let (success, migrateStoreError) = migrateStore(at: sourceStore,
                                                            storeType: storeType,
                                                            fromModel: modelFrom,
                                                            toModel: modelTo,
                                                            with: migrateWithModel)
            guard success else {
                if let migrateStoreError = migrateStoreError {
                    let errorInfo = (migrateStoreError as NSError?)?.userInfo ?? [:]
                    debugMessages.append("Migration error: \(migrateStoreError) [\(errorInfo)]")
                }
                return (false, debugMessages)
            }
        }

        return (true, debugMessages)
    }
}


// MARK: - File helpers
//
private extension CoreDataIterativeMigrator {

    /// Build a temporary path to write the migrated store.
    ///
    func createTemporaryFolder(at storeURL: URL) -> URL {
        let tempDestinationURL = storeURL.deletingLastPathComponent().appendingPathComponent("migration").appendingPathComponent(storeURL.lastPathComponent)
        try? fileManager.removeItem(at: tempDestinationURL.deletingLastPathComponent())
        try? fileManager.createDirectory(at: tempDestinationURL.deletingLastPathComponent(), withIntermediateDirectories: false, attributes: nil)

        return tempDestinationURL
    }

    /// Deletes the SQLite files for the store at the given `storeURL`.
    ///
    /// The files that will be deleted are:
    ///
    /// - {store_filename}.sqlite
    /// - {store_filename}.sqlite-wal
    /// - {store_filename}.sqlite-shm
    ///
    /// Where {store_filename} is most probably "WooCommerce".
    ///
    /// TODO Possibly replace this with `NSPersistentStoreCoordinator.destroyStore` or use
    /// `replaceStore` directly.
    ///
    /// - Throws: `Error` if one of the deletion fails.
    ///
    func deleteStoreFiles(storeURL: URL) throws {
        let storeFolderURL = storeURL.deletingLastPathComponent()

        do {
            try fileManager.contentsOfDirectory(atPath: storeFolderURL.path).map { fileName in
                storeFolderURL.appendingPathComponent(fileName)
            }.filter { fileURL in
                // Only include files that have the same filename as the store (sqlite) filename.
                fileURL.deletingPathExtension() == storeURL.deletingPathExtension()
            }.forEach { fileURL in
                try fileManager.removeItem(at: fileURL)
            }
        } catch {
            DDLogError("⛔️ Error while deleting the store SQLite files: \(error)")
            throw error
        }
    }

    /// Copy the store files that were migrated (using `NSMigrationManager`) to where the
    /// store files should be loaded by `CoreDataManager` later.
    ///
    func copyMigratedOverOriginal(from tempDestinationURL: URL, to storeURL: URL) throws {
        do {
            let files = try fileManager.contentsOfDirectory(atPath: tempDestinationURL.deletingLastPathComponent().path)
            try files.forEach { (file) in
                if file.hasPrefix(tempDestinationURL.lastPathComponent) {
                    let sourceURL = tempDestinationURL.deletingLastPathComponent().appendingPathComponent(file)
                    let targetURL = storeURL.deletingLastPathComponent().appendingPathComponent(file)

                    // TODO This removeItem may not be necessary because we should have already
                    // deleted everything during `deleteStoreFiles`.
                    try? fileManager.removeItem(at: targetURL)

                    try fileManager.moveItem(at: sourceURL, to: targetURL)
                }
            }
        } catch {
            DDLogError("⛔️ Error while copying migrated over the original files: \(error)")
            throw error
        }
    }

    func makeMigrationAttemptLogMessage(models: [NSManagedObjectModel],
                                        from fromModel: NSManagedObjectModel,
                                        to toModel: NSManagedObjectModel) -> String {
        // This logic is a bit nasty. I'm just trying to keep the existing logic intact for now.

        let versions = modelsInventory.versions

        let fromName: String? = {
            if let index = models.firstIndex(of: fromModel) {
                return versions[safe: index]?.name
            } else {
                return nil
            }
        }()

        let toName: String? = {
            if let index = models.firstIndex(of: toModel) {
                return versions[safe: index]?.name
            } else {
                return nil
            }
        }()

        return "⚠️ Attempting migration from \(fromName ?? "unknown") to \(toName ?? "unknown")"
    }
}


// MARK: - Private helper functions
//
private extension CoreDataIterativeMigrator {

    func migrateStore(at url: URL,
                             storeType: String,
                             fromModel: NSManagedObjectModel,
                             toModel: NSManagedObjectModel,
                             with mappingModel: NSMappingModel) -> (success: Bool, error: Error?) {
        let tempDestinationURL = createTemporaryFolder(at: url)

        // Migrate from the source model to the target model using the mapping,
        // and store the resulting data at the temporary path.
        let migrator = NSMigrationManager(sourceModel: fromModel, destinationModel: toModel)
        do {
            try migrator.migrateStore(from: url,
                                      sourceType: storeType,
                                      options: nil,
                                      with: mappingModel,
                                      toDestinationURL: tempDestinationURL,
                                      destinationType: storeType,
                                      destinationOptions: nil)
        } catch {
            return (false, error)
        }

        do {
            // Delete the original store files.
            try deleteStoreFiles(storeURL: url)
            // Replace the (deleted) original store files with the migrated store files.
            try copyMigratedOverOriginal(from: tempDestinationURL, to: url)
        } catch {
            return (false, error)
        }

        return (true, nil)
    }

    func metadataForPersistentStore(storeType: String, at url: URL) throws -> [String: Any]? {

        guard let sourceMetadata = try? NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: storeType, at: url, options: nil) else {
            let description = "Failed to find source metadata for store: \(url)"
            throw NSError(domain: "IterativeMigrator", code: 102, userInfo: [NSLocalizedDescriptionKey: description])
        }

        return sourceMetadata
    }

    func model(for metadata: [String: Any]) throws -> NSManagedObjectModel? {
        let bundle = Bundle(for: CoreDataManager.self)
        guard let sourceModel = NSManagedObjectModel.mergedModel(from: [bundle], forStoreMetadata: metadata) else {
            let description = "Failed to find source model for metadata: \(metadata)"
            throw NSError(domain: "IterativeMigrator", code: 100, userInfo: [NSLocalizedDescriptionKey: description])
        }

        return sourceModel
    }

    func models(for modelVersions: [ManagedObjectModelsInventory.ModelVersion]) throws -> [NSManagedObjectModel] {
        let models = try modelVersions.map { version -> NSManagedObjectModel in
            guard let model = self.modelsInventory.model(for: version) else {
                let description = "No model found for \(version.name)"
                throw NSError(domain: "IterativeMigrator", code: 110, userInfo: [NSLocalizedDescriptionKey: description])
            }

            return model
        }

        return models
    }
}
