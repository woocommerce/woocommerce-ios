import CoreData

private typealias ModelVersion = ManagedObjectModelsInventory.ModelVersion

extension CoreDataIterativeMigrator {
    /// A single step in the iterative migration loop executed
    /// by `CoreDataIterativeMigrator.iterativeMigrate`.
    struct MigrationStep: Equatable {
        /// The source version. This is used for logging purposes.
        let sourceVersion: ManagedObjectModelsInventory.ModelVersion
        /// The source model in this single step. This will be used as the `sourceModel`
        /// when initializing `NSMigrationManager()` for migration.
        let sourceModel: NSManagedObjectModel

        /// The target version. This is used for logging purposes.
        let targetVersion: ManagedObjectModelsInventory.ModelVersion
        /// The target model in this single step. This will be used as the `destinationModel`
        /// when initializing `NSMigrationManager()` for migration.
        let targetModel: NSManagedObjectModel

        /// Returns the steps that `CoreDataIterativeMigrator` should use to migrate a store
        /// with a `source` model version to the desired `target` model version.
        ///
        ///  - Returns: An array of migration steps that should be performed in sequence.
        static func steps(using inventory: ManagedObjectModelsInventory,
                          source: NSManagedObjectModel,
                          target: NSManagedObjectModel) throws -> [MigrationStep] {

            // Retrieve an inclusive list of models between the source and target models.
            let versionsAndModels = try versionsAndModelsToMigrate(using: inventory, source: source, target: target)

            // If there are less than 2 models to migrate, then there's no source and target,
            // which means there's nothing to migrate. ¯\_(ツ)_/¯
            guard versionsAndModels.count > 1 else {
                return []
            }

            // Exclude the last one using `dropLast()`. It will be the `targetVersionAndModel` in the
            // last `MigrationStep` created.
            return versionsAndModels.dropLast().enumerated().map { index, sourceVersionAndModel -> MigrationStep in
                let targetVersionAndModel = versionsAndModels[index + 1]

                return MigrationStep(sourceVersion: sourceVersionAndModel.version,
                                     sourceModel: sourceVersionAndModel.model,
                                     targetVersion: targetVersionAndModel.version,
                                     targetModel: targetVersionAndModel.model)
            }

        }

        /// Returns an inclusive list of models between the source and target models. The response
        /// also includes the `ModelVersion`.
        ///
        /// For example, if `sourceModel` is `"Model 13"` and `targetModel` is `"Model 16"`, then this
        /// will return this list of `NSManagedObjectModels` in order:
        ///
        /// - Model 13
        /// - Model 14
        /// - Model 15
        /// - Model 16
        ///
        /// This also works if the `targetModel` is lower than the `sourceModel`. For example, if the
        /// `sourceModel` is `"Model 16"` and `targetModel` is `"Model 13"`, then this list will
        /// be returned:
        ///
        /// - Model 16
        /// - Model 15
        /// - Model 14
        /// - Model 13
        ///
        /// We don't really use the descending list at the moment. I'm just keeping this logic
        /// as is for now so I don't accidentally introduce regressions. Someday, one brave soul
        /// will refactor this and remove the descending logic.
        ///
        /// - Returns: The list of models and their corresponding `ModelVersion` to be used for
        ///            migration, including the `sourceModel` and the `targetModel`.
        private static func versionsAndModelsToMigrate(
            using inventory: ManagedObjectModelsInventory,
            source sourceModel: NSManagedObjectModel,
            target targetModel: NSManagedObjectModel
        ) throws -> [(version: ModelVersion, model: NSManagedObjectModel)] {

            let allModels = try inventory.models(for: inventory.versions)

            // Confidence check. We don't expect the method above to succeed if one of the models
            // are not loaded. It should `throw` in this case.
            guard allModels.count == inventory.versions.count else {
                return []
            }

            var modelsToMigrate = [(ModelVersion, NSManagedObjectModel)]()
            var firstFound = false, lastFound = false, reverse = false

            for (index, model) in allModels.enumerated() {
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
                    // We don't need to use a safe array access for `versions` here since we expect
                    // that `allModels.count` is equal to `inventory.versions.count`.
                    let version = inventory.versions[index]

                    modelsToMigrate.append((version: version, model: model))
                }

                if lastFound {
                    break
                }
            }

            // Ensure that the source model is at the start of the list.
            if reverse {
                modelsToMigrate = modelsToMigrate.reversed()
            }

            return modelsToMigrate
        }

    }
}
