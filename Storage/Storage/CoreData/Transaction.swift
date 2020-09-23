import CoreData

final class Transaction: TransactionType {

    private let context: NSManagedObjectContext

    init(_ context: NSManagedObjectContext) {
        self.context = context
    }

    func allObjects<T: Object>(ofType type: T.Type, matching predicate: NSPredicate?,
                       sortedBy descriptors: [NSSortDescriptor]?) -> [T] {
        context.allObjects(ofType: type, matching: predicate, sortedBy: descriptors)
    }

    func countObjects<T: Object>(ofType type: T.Type) -> Int {
        context.countObjects(ofType: type)
    }

    func countObjects<T: Object>(ofType type: T.Type, matching predicate: NSPredicate?) -> Int {
        context.countObjects(ofType: type, matching: predicate)
    }

    func deleteObject<T: Object>(_ object: T) {
        context.deleteObject(object)
    }

    func deleteAllObjects<T: Object>(ofType type: T.Type) {
        context.deleteAllObjects(ofType: type)
    }

    func firstObject<T: Object>(ofType type: T.Type) -> T? {
        context.firstObject(ofType: type)
    }

    func firstObject<T: Object>(ofType type: T.Type, matching predicate: NSPredicate?) -> T? {
        context.firstObject(ofType: type, matching: predicate)
    }

    func insertNewObject<T: Object>(ofType type: T.Type) -> T {
        context.insertNewObject(ofType: type)
    }

    func loadObject<T: Object>(ofType type: T.Type, with objectID: T.ObjectID) -> T? {
        context.loadObject(ofType: type, with: objectID)
    }

    func obtainPermanentIDs(for objects: [NSManagedObject]) throws {
        try context.obtainPermanentIDs(for: objects)
    }
}
