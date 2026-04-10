import CoreData
import XCTest

/// Utilities for testing with CoreData.
extension NSManagedObjectContext {
    /// Returns the total number of objects for the given `entityName`.
    func count(entityName: String) throws -> Int {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        return try count(for: fetchRequest)
    }

    /// Returns all the `NSManagedObject` for the given `entityName`.
    func allObjects(entityName: String) throws -> [NSManagedObject] {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        return try XCTUnwrap(fetch(fetchRequest) as? [NSManagedObject])
    }

    /// Returns the first `NSManagedObject` for the given `entityName`.
    func first(entityName: String) throws -> NSManagedObject? {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        fetchRequest.fetchLimit = 1

        let result = try XCTUnwrap(fetch(fetchRequest) as? [NSManagedObject])
        return result.first
    }

    /// Inserts a new `NSManagedObject` for the given `entityName` and sets its properties
    /// and values based on the `properties` dictionary.
    @discardableResult
    func insert(entityName: String, properties: [String: Any?]) -> NSManagedObject {
        let object = NSEntityDescription.insertNewObject(forEntityName: entityName, into: self)
        properties.forEach { key, value in
            object.setValue(value, forKey: key)
        }
        return object
    }
}
