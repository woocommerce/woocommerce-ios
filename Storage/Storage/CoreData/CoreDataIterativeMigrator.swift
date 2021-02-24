import Foundation
import CoreData

/// CoreDataIterativeMigrator: Migrates through a series of models to allow for users to skip app versions without risk.
/// This was derived from ALIterativeMigrator originally used in the WordPress app.
///
final class CoreDataIterativeMigrator {

    /// The `NSPersistentStoreCoordinator` instance that will be used for replacing or destroying
    /// persistent stores.
    private let persistentStoreCoordinator: PersistentStoreCoordinatorProtocol

    /// The model versions that will be used for migration.
    private let modelsInventory: ManagedObjectModelsInventory

    /// Used to determine if a given store URL exists in the file system.
    private let fileManager: FileManagerProtocol

    init(coordinator: PersistentStoreCoordinatorProtocol,
         modelsInventory: ManagedObjectModelsInventory,
         fileManager: FileManagerProtocol = FileManager.default) {
        self.persistentStoreCoordinator = coordinator
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
    func iterativeMigrate(sourceStore sourceStoreURL: URL,
                          storeType: String,
                          to targetModel: NSManagedObjectModel) throws -> (success: Bool, debugMessages: [String]) {
        // If the persistent store does not exist at the given URL,
        // assume that it hasn't yet been created and return success immediately.
        guard fileManager.fileExists(atPath: sourceStoreURL.path) == true else {
            return (true, ["No store exists at URL \(sourceStoreURL).  Skipping migration."])
        }

        // Get the persistent store's metadata.  The metadata is used to
        // get information about the store's managed object model.
        let sourceMetadata =
            try NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: storeType, at: sourceStoreURL, options: nil)

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
            // Abort because there is nothing to migrate. And also to avoid accidentally deleting
            // `sourceStoreURL` during the routine below.
            return (false, ["Skipping migration. Found no steps for migration."])
        }

        var debugMessages = [String]()

        do {
            // Perform all the migration steps and acquire the last _migrated_ destination URL.
            let lastTempDestinationURL = try steps.reduce(sourceStoreURL) { currentSourceStoreURL, step in
                // Log a message
                let migrationAttemptMessage = makeMigrationAttemptLogMessage(step: step)
                debugMessages.append(migrationAttemptMessage)
                DDLogWarn(migrationAttemptMessage)

                // Migrate to temporary URL
                let tempDestinationURL = try migrate(step: step,
                                                     sourceStoreURL: currentSourceStoreURL,
                                                     storeType: storeType)

                // To keep disk space usage to a minimum, destroy the `currentSourceStoreURL`
                // if it is a temporary migrated store URL since we will no longer need it. It's
                // been replaced by the store at `tempDestinationURL`.
                if currentSourceStoreURL != sourceStoreURL {
                    try persistentStoreCoordinator.destroyPersistentStore(at: currentSourceStoreURL,
                                                                          ofType: storeType,
                                                                          options: nil)
                }

                return tempDestinationURL
            }

            // Now that the migration steps have been performed, replace the store that the
            // app will use with the _migrated_ store located at the `lastTempDestinationURL`.
            //
            // This completes the iterative migration. After this step, the store located
            // in `sourceStoreURL` should be fully migrated and useable.
            try persistentStoreCoordinator.replacePersistentStore(at: sourceStoreURL,
                                                                  destinationOptions: nil,
                                                                  withPersistentStoreFrom: lastTempDestinationURL,
                                                                  sourceOptions: nil,
                                                                  ofType: storeType)

            // Final clean-up. Destroy the store at `lastTempDestinationURL` since it should have
            // been copied over to `sourceStoreURL` during `replacePersistentStore` (above).
            try persistentStoreCoordinator.destroyPersistentStore(at: lastTempDestinationURL,
                                                                  ofType: storeType,
                                                                  options: nil)

            return (true, debugMessages)
        } catch {
            let errorInfo = (error as NSError?)?.userInfo ?? [:]
            debugMessages.append("Migration error: \(error) [\(errorInfo)]")
            return (false, debugMessages)
        }
    }
}

// MARK: - Private helper functions
//
private extension CoreDataIterativeMigrator {

    /// Migrate the store at `sourceStoreURL` using the source and target models defined in `step`.
    ///
    /// - Returns: A `URL` in the temporary directory where the migrated store is located.
    func migrate(step: MigrationStep, sourceStoreURL: URL, storeType: String) throws -> URL {
        let mappingModel = try self.mappingModel(from: step.sourceModel, to: step.targetModel)
        let tempDestinationURL = makeTemporaryMigrationDestinationURL()

        // Migrate from the source model to the target model using the mapping,
        // and store the resulting data at the temporary URL.
        let migrator = NSMigrationManager(sourceModel: step.sourceModel, destinationModel: step.targetModel)
        try migrator.migrateStore(from: sourceStoreURL,
                                  sourceType: storeType,
                                  options: nil,
                                  with: mappingModel,
                                  toDestinationURL: tempDestinationURL,
                                  destinationType: storeType,
                                  destinationOptions: nil)

        return tempDestinationURL
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

    func makeMigrationAttemptLogMessage(step: MigrationStep) -> String {
        "⚠️ Attempting migration from \(step.sourceVersion.name) to \(step.targetVersion.name)"
    }

    /// Returns a temporary SQLite **file URL** to be used as the destination when performing a
    /// migration.
    func makeTemporaryMigrationDestinationURL() -> URL {
        URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent("migration_\(UUID().uuidString)")
            .appendingPathExtension("sqlite")
    }
}
