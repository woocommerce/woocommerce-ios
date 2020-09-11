import Foundation

import CoreData.NSFetchedResultsController
import CoreData.NSFetchRequest

/// Defines all of the methods made available by the Storage.
///
public protocol StorageType: class {

    var parentStorage: StorageType? {get}

    /// Returns all of the available objects of a given Type, matching the specified Predicate (and sorted with a given collection of
    /// SortDescriptors).
    ///
    func allObjects<T: Object>(ofType type: T.Type, matching predicate: NSPredicate?, sortedBy descriptors: [NSSortDescriptor]?) -> [T]

    /// Returns the count of all of the available objects, of a given Type.
    ///
    func countObjects<T: Object>(ofType type: T.Type) -> Int

    /// Returns the count of objects, of a given Type, matching a specified Predicate.
    ///
    func countObjects<T: Object>(ofType type: T.Type, matching predicate: NSPredicate?) -> Int

    /// Nukes the specified Object.
    ///
    func deleteObject<T: Object>(_ object: T)

    /// Nukes all of the objects of the specified kind.
    ///
    func deleteAllObjects<T: Object>(ofType type: T.Type)

    /// Returns the first available object, of a given kind, matching the specified Predicate.
    ///
    func firstObject<T: Object>(ofType type: T.Type) -> T?

    /// Returns the first available object, of a given kind, matching the specified Predicate.
    ///
    func firstObject<T: Object>(ofType type: T.Type, matching predicate: NSPredicate?) -> T?

    /// Inserts a new object of the given Type.
    ///
    func insertNewObject<T: Object>(ofType type: T.Type) -> T

    /// Loads an object, of the specified Type, with a given ObjectID (if any).
    ///
    func loadObject<T: Object>(ofType type: T.Type, with objectID: T.ObjectID) -> T?

    /// Obtain permanent `ObjectID` for the given `NSManagedObjects`.
    ///
    /// This is temporarily exposed since `NSFetchedResultsController`'s `DiffableDataSource`
    /// support exposes temporary IDs in snapshots and immediately converts them to permanent IDs.
    /// This causes an undesirable confusing animation (dual refresh) when the subsequent
    /// snapshots are applied to the `UITableView`.
    ///
    /// We will find a better solution for this later. My current idea is to use a separate
    /// **read-only** `NSManagedObjectContext` to use for the `NSFetchedResultsController`.
    /// This will ensure that `NSFetchedResultsController` will not ever receive temporary IDs.
    func obtainPermanentIDs(for objects: [NSManagedObject]) throws

    /// Persists unsaved changes, if needed.
    ///
    func saveIfNeeded()

    /// Asynchronously performs a given block on the StorageType's queue.
    ///
    func perform(_ closure: @escaping () -> Void)

    /// Create an `NSFetchedResultsController` using this `StorageType`.
    ///
    /// We generally do not allow direct access to `NSManagedObjectContext` as that is hidden
    /// behind `StorageType`. However, `NSFetchedResultsController` requires an
    /// `NSManagedObjectContext` to be instantiated. This method solves that problem. Consumers can
    /// create an `NSFetchedResultsController` without illegally referencing an
    /// `NSManagedObjectContext`.
    ///
    func createFetchedResultsController<ResultType>(fetchRequest: NSFetchRequest<ResultType>,
                                                    sectionNameKeyPath: String?,
                                                    cacheName: String?) -> NSFetchedResultsController<ResultType>
}
