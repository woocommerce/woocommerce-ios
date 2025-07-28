import Foundation
import CoreData


// MARK: - Represents a NSManagedObjectsDidChangeNotification
//
struct ManagedObjectsDidChangeNotification {

    /// Returns the collection of Inserted Objects.
    ///
    let insertedObjects: Set<NSManagedObject>

    /// Returns the collection of Updated Objects.
    ///
    let updatedObjects: Set<NSManagedObject>

    /// Returns the collection of Refreshed Objects.
    ///
    let refreshedObjects: Set<NSManagedObject>

    /// Returns the collection of Deleted Objects.
    ///
    let deletedObjects: Set<NSManagedObject>

    /// Returns the Inserted + Updated + Refreshed Objects
    ///
    var upsertedObjects: Set<NSManagedObject> {
        return insertedObjects
            .union(updatedObjects)
            .union(refreshedObjects)
    }


    /// Designated Initializer
    ///
    init?(notification: Notification) {
        guard notification.name == .NSManagedObjectContextObjectsDidChange else {
            return nil
        }

        insertedObjects = notification.userInfo?[NSInsertedObjectsKey]      as? Set<NSManagedObject>    ?? Set()
        updatedObjects = notification.userInfo?[NSUpdatedObjectsKey]        as? Set<NSManagedObject>    ?? Set()
        refreshedObjects = notification.userInfo?[NSRefreshedObjectsKey]    as? Set<NSManagedObject>    ?? Set()
        deletedObjects = notification.userInfo?[NSDeletedObjectsKey]        as? Set<NSManagedObject>    ?? Set()
    }
}
