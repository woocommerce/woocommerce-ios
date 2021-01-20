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
            return (true, ["No store exists at URL \(sourceStore).  Skipping migration."])
        }

        // Get the persistent store's metadata.  The metadata is used to
        // get information about the store's managed object model.
        let sourceMetadata =
            try NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: storeType, at: sourceStore, options: nil)

        // Check whether the final model is already compatible with the store.
        // If it is, no migration is necessary.
        guard targetModel.isConfiguration(withName: nil, compatibleWithStoreMetadata: sourceMetadata) == false else {
            return (true, ["Target model is compatible with the store. No migration necessary."])
        }

        // Find the current model used by the store.
        let sourceModel = try model(for: sourceMetadata)

        // Get the steps to perform the migration.
        let steps = try MigrationStep.steps(using: modelsInventory, source: sourceModel, target: targetModel)
        guard !steps.isEmpty else {
            return (false, ["Skipping migration. Found no steps for migration."])
        }

        var debugMessages = [String]()

        do {
            try steps.forEach { step in
                let mappingModel = try self.mappingModel(from: step.sourceModel, to: step.targetModel)

                // Migrate the model to the next step
                let migrationAttemptMessage = makeMigrationAttemptLogMessage(step: step)
                debugMessages.append(migrationAttemptMessage)
                DDLogWarn(migrationAttemptMessage)

                try migrateStore(at: sourceStore,
                                 storeType: storeType,
                                 fromModel: step.sourceModel,
                                 toModel: step.targetModel,
                                 with: mappingModel)
            }

            return (true, debugMessages)
        } catch {
            let errorInfo = (error as NSError?)?.userInfo ?? [:]
            debugMessages.append("Migration error: \(error) [\(errorInfo)]")
            return (false, debugMessages)
        }
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

    func makeMigrationAttemptLogMessage(step: MigrationStep) -> String {
        "⚠️ Attempting migration from \(step.sourceVersion.name) to \(step.targetVersion.name)"
    }
}


// MARK: - Private helper functions
//
private extension CoreDataIterativeMigrator {

    func migrateStore(at url: URL,
                             storeType: String,
                             fromModel: NSManagedObjectModel,
                             toModel: NSManagedObjectModel,
                             with mappingModel: NSMappingModel) throws {
        let tempDestinationURL = createTemporaryFolder(at: url)

        // Migrate from the source model to the target model using the mapping,
        // and store the resulting data at the temporary path.
        let migrator = NSMigrationManager(sourceModel: fromModel, destinationModel: toModel)
        try migrator.migrateStore(from: url,
                                  sourceType: storeType,
                                  options: nil,
                                  with: mappingModel,
                                  toDestinationURL: tempDestinationURL,
                                  destinationType: storeType,
                                  destinationOptions: nil)

        // Delete the original store files.
        try deleteStoreFiles(storeURL: url)
        // Replace the (deleted) original store files with the migrated store files.
        try copyMigratedOverOriginal(from: tempDestinationURL, to: url)
    }

    func model(for metadata: [String: Any]) throws -> NSManagedObjectModel {
        let bundle = Bundle(for: CoreDataManager.self)
        guard let sourceModel = NSManagedObjectModel.mergedModel(from: [bundle], forStoreMetadata: metadata) else {
            let description = "Failed to find source model for metadata: \(metadata)"
            throw NSError(domain: "IterativeMigrator", code: 100, userInfo: [NSLocalizedDescriptionKey: description])
        }

        return sourceModel
    }

    /// Load a developer-defined `NSMappingModel` (`*.xcmappingmodel` file) or infer it.
    func mappingModel(from sourceModel: NSManagedObjectModel,
                      to targetModel: NSManagedObjectModel) throws -> NSMappingModel {
        if let mappingModel = NSMappingModel(from: nil, forSourceModel: sourceModel, destinationModel: targetModel) {
            return mappingModel
        }

        return try NSMappingModel.inferredMappingModel(forSourceModel: sourceModel, destinationModel: targetModel)
    }
}
