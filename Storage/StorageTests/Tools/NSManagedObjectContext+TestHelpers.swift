import CoreData
import XCTest

/// Utilities for testing with CoreData.
extension NSManagedObjectContext {
    func count(entityName: String) throws -> Int {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        return try count(for: fetchRequest)
    }

    func allObjects(entityName: String) throws -> [NSManagedObject] {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        return try XCTUnwrap(fetch(fetchRequest) as? [NSManagedObject])
    }

    @discardableResult
    func insert(entityName: String, properties: [String: Any?]) -> NSManagedObject {
        let object = NSEntityDescription.insertNewObject(forEntityName: entityName, into: self)
        properties.forEach { key, value in
            object.setValue(value, forKey: key)
        }
        return object
    }
}
