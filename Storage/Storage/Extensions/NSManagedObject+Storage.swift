import Foundation
import CoreData


/// NSManagedObject Helpers
///
extension NSManagedObject {

    /// Returns the Entity Name, if available, as specified in the NSEntityDescription. Otherwise, will return
    /// the subclass name.
    ///
    /// Note: entity().name returns nil as per iOS 10, in Unit Testing Targets. Awesome.
    ///
    class func entityName() -> String {
        return entity().name ?? classNameWithoutNamespaces()
    }

    /// Returns a NSFetchRequest instance with its *Entity Name* always set.
    ///
    /// Note: entity().name returns nil as per iOS 10, in Unit Testing Targets. Awesome.
    ///
    class func safeFetchRequest() -> NSFetchRequest<NSFetchRequestResult> {
        guard entity().name == nil else {
            return fetchRequest()
        }

        return NSFetchRequest(entityName: entityName())
    }
}
