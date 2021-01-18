import CoreData

extension CoreDataIterativeMigrator {
    /// A step in the iterative migration loop executed by `CoreDataIterativeMigrator.iterativeMigrate`.
    struct MigrationStep {
        let sourceModel: NSManagedObjectModel
        let targetModel: NSManagedObjectModel
    }
}
