import Foundation


///
///
public protocol Storage {

    ///
    ///
    func allObjects<T: Object>(ofType type: T.Type, matching predicate: NSPredicate?, sortedBy descriptors: [NSSortDescriptor]?) -> [T]

    ///
    ///
    func countObjects<T: Object>(ofType type: T.Type, matching predicate: NSPredicate?) -> Int

    ///
    ///
    func deleteObject<T: Object>(_ object: T)

    ///
    ///
    func deleteAllObjects<T: Object>(ofType type: T.Type)

    ///
    ///
    func firstObject<T: Object>(ofType type: T.Type, matching predicate: NSPredicate) -> T?

    ///
    ///
    func insertNewObject<T: Object>(ofType type: T.Type) -> T

    ///
    ///
    func loadObject<T: Object>(ofType type: T.Type, with objectID: T.ObjectID) -> T?

    ///
    ///
    func saveIfNeeded()
}
