import CoreData

extension NSManagedObjectContext {
    func count(entityName: String) throws -> Int {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        return try count(for: fetchRequest)
    }
}
