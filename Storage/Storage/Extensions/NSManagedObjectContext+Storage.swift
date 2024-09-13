import Foundation
import CoreData
import WooFoundation

/// NSManagedObjectContext Storage Conformance
///
extension NSManagedObjectContext: StorageType {

    public var parentStorage: StorageType? {
        return parent
    }

    /// Returns all of the entities that match with a given predicate.
    ///
    /// - Parameters:
    ///     - type: Defines the `kind` of objects to be retrieved.
    ///     - predicate: Defines the conditions that any given object should meet.
    ///     - sortedBy: Sort Descriptors to be applied.
    ///
    public func allObjects<T: Object>(ofType type: T.Type, matching predicate: NSPredicate? = nil, sortedBy descriptors: [NSSortDescriptor]? = nil) -> [T] {
        let request = fetchRequest(forType: type)
        request.predicate = predicate
        request.sortDescriptors = descriptors

        return loadObjects(ofType: type, with: request)
    }

    /// Returns the count of all of the available objects, of a given Type.
    ///
    /// - Note: This is a Convenience method. As of Swift 4.1, you can't declare optionals with default values within Protocols.
    ///
    public func countObjects<T: Object>(ofType type: T.Type) -> Int {
        return countObjects(ofType: type, matching: nil)
    }

    /// Returns the number of entities found that match with a given predicate.
    ///
    /// - Parameters:
    ///     - type: Defines the `kind` of objects to be counted.
    ///     - predicate: Defines the conditions that any given object should meet.
    ///
    public func countObjects<T: Object>(ofType type: T.Type, matching predicate: NSPredicate?) -> Int {
        let request = fetchRequest(forType: type)
        request.includesSubentities = false
        request.predicate = predicate
        request.resultType = .countResultType

        var result = 0

        do {
            result = try count(for: request)
        } catch {
            DDLogError("countObjects failed. Error counting objects [\(T.entityName)]: \(error)")
        }

        return result
    }

    /// Deletes the specified Object Instance
    ///
    public func deleteObject<T: Object>(_ object: T) {
        guard let object = object as? NSManagedObject else {
            let errorMessage = "deleteObject failed. Invalid Object Kind \(type(of: object)) " +
                               "for object type: \(T.self). This error is related to NSManagedObject " +
                               "and CoreData."
            DDLogError(errorMessage)
            return
        }

        delete(object)
    }

    /// Deletes all of the NSMO instances associated to the specified kind
    ///
    public func deleteAllObjects<T: Object>(ofType type: T.Type) {
        let request = fetchRequest(forType: type)
        request.includesPropertyValues = false
        request.includesSubentities = false

        for object in loadObjects(ofType: type, with: request) {
            deleteObject(object)
        }
    }

    /// Retrieves the first entity of a given Type.
    ///
    /// - Note: This is a Convenience method. As of Swift 4.1, you can't declare optionals with default values within Protocols.
    ///
    public func firstObject<T: Object>(ofType type: T.Type) -> T? {
        return firstObject(ofType: type, matching: nil)
    }

    /// Retrieves the first entity that matches with a given predicate
    ///
    /// - Parameters:
    ///     - type: Defines the `kind` of object to be retrieved.
    ///     - predicate: Defines the conditions that any given object should meet.
    ///
    public func firstObject<T: Object>(ofType type: T.Type, matching predicate: NSPredicate?) -> T? {
        let request = fetchRequest(forType: type)
        request.predicate = predicate
        request.fetchLimit = 1

        return loadObjects(ofType: type, with: request).first
    }

    /// Inserts a new Entity. For performance reasons, this helper *DOES NOT* persists the context.
    ///
    public func insertNewObject<T: Object>(ofType type: T.Type) -> T {
        return NSEntityDescription.insertNewObject(forEntityName: T.entityName, into: self) as! T
    }

    /// Loads a single NSManagedObject instance, given its ObjectID, if available.
    ///
    /// - Parameters:
    ///     - type: Defines the `kind` of objects to be loaded.
    ///     - objectID: Unique Identifier of the entity to retrieve, if available.
    ///
    public func loadObject<T: Object>(ofType type: T.Type, with objectID: T.ObjectID) -> T? {
        guard let objectID = objectID as? NSManagedObjectID else {
            let errorMessage = "loadObject failed. Invalid ObjectID Kind: \(objectID), " +
                               "for object type: \(T.self). This error is related to " +
                               "NSManagedObject and CoreData."
            DDLogError(errorMessage)
            return nil
        }

        do {
            return try existingObject(with: objectID) as? T
        } catch {
            let errorMessage = "loadObject failed. Error loading Object [\(T.entityName)] in context: " +
                               "\(self). This error is related to NSManagedObject and CoreData."
            DDLogError(errorMessage)
        }

        return nil
    }

    /// Persists the changes (if any) to disk.
    ///
    public func saveIfNeeded() {
        guard hasChanges else {
            return
        }

        do {
            try save()
        } catch {
            let nserror = error as NSError
            let errorMessage = "saveIfNeeded failed. Error \(nserror), " +
                               "\(nserror.userInfo) in context: \(self). " +
                               "This error is related to NSManagedObject and CoreData."
            DDLogError(errorMessage)
        }
    }

    /// Create an `NSFetchedResultsController` using this `NSManagedObjectContext`.
    ///
    public func createFetchedResultsController<ResultType>(fetchRequest: NSFetchRequest<ResultType>,
                                                           sectionNameKeyPath: String?,
                                                           cacheName: String?) -> NSFetchedResultsController<ResultType> {
        NSFetchedResultsController(
                fetchRequest: fetchRequest,
                managedObjectContext: self,
                sectionNameKeyPath: sectionNameKeyPath,
                cacheName: cacheName
        )
    }

    /// Loads the collection of entities that match with a given Fetch Request
    ///
    private func loadObjects<T: Object>(ofType type: T.Type, with request: NSFetchRequest<NSFetchRequestResult>) -> [T] {
        var objects: [T]?

        do {
            objects = try fetch(request) as? [T]
        } catch {
            let errorMessage = "loadObjects failed. Error loading Objects [\(T.entityName)] in context: " +
                               "\(self). This error is related to NSManagedObject and CoreData."
            DDLogError(errorMessage)
        }

        return objects ?? []
    }

    /// Returns a NSFetchRequest instance with its *Entity Name* always set, for the specified Object Type.
    ///
    private func fetchRequest<T: Object>(forType type: T.Type) -> NSFetchRequest<NSFetchRequestResult> {
        return NSFetchRequest<NSFetchRequestResult>(entityName: type.entityName)
    }
}
