import CoreData

final class DeleteEntityMigrationPolicy: NSEntityMigrationPolicy {
    override func createDestinationInstances(forSource sInstance: NSManagedObject,
                                             in mapping: NSEntityMapping,
                                             manager: NSMigrationManager) throws {
        // This is intentionally empty because we want to _delete_ `sInstance`.
    }
}
