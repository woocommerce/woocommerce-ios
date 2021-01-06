import CoreData

/// A reusable migration policy that, when used as a custom policy for an entity, will delete
/// all the data (`NSManagedObjects`) for that entity.
///
final class DeleteEntityObjectsMigrationPolicy: NSEntityMigrationPolicy {
    override func createDestinationInstances(forSource sInstance: NSManagedObject,
                                             in mapping: NSEntityMapping,
                                             manager: NSMigrationManager) throws {
        // This is intentionally empty because we want to _delete_ `sInstance`.
    }
}
