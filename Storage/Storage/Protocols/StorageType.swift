import Foundation


/// Defines all of the methods made available by the Storage.
///
public protocol StorageType {

    /// Returns all of the available objects of a given Type, matching the specified Predicate (and sorted with a given collection of
    /// SortDescriptors).
    ///
    func allObjects<T: Object>(ofType type: T.Type, matching predicate: NSPredicate?, sortedBy descriptors: [NSSortDescriptor]?) -> [T]

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
    func firstObject<T: Object>(ofType type: T.Type, matching predicate: NSPredicate) -> T?

    /// Inserts a new object of the given Type.
    ///
    func insertNewObject<T: Object>(ofType type: T.Type) -> T

    /// Loads an object, of the specified Type, with a given ObjectID (if any).
    ///
    func loadObject<T: Object>(ofType type: T.Type, with objectID: T.ObjectID) -> T?

    /// Persists unsaved changes, if needed.
    ///
    func saveIfNeeded()
}
