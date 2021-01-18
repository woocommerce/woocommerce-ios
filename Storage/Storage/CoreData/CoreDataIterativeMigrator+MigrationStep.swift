import CoreData

extension CoreDataIterativeMigrator {
    /// A step in the iterative migration loop executed by `CoreDataIterativeMigrator.iterativeMigrate`.
    struct MigrationStep {
        let sourceModel: NSManagedObjectModel
        let targetModel: NSManagedObjectModel

        /// Returns an inclusive list of models between the source and target models.
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
        /// - Returns: The list of models to be used for migration, including the `sourceModel` and
        ///            the `targetModel`.
        private static func modelsToMigrate(using allModels: [NSManagedObjectModel],
                                            source sourceModel: NSManagedObjectModel,
                                            target targetModel: NSManagedObjectModel) throws -> [NSManagedObjectModel] {
            var modelsToMigrate = [NSManagedObjectModel]()
            var firstFound = false, lastFound = false, reverse = false

            for model in allModels {
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

            return modelsToMigrate
        }
    }
}
