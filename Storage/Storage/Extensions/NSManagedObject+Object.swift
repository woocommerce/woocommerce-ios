import Foundation
import CoreData


/// NSManagedObject: Object Conformance
///
extension NSManagedObject: Object {

    /// Returns the Entity Name, if available, as specified in the NSEntityDescription. Otherwise, will return
    /// the subclass name.
    ///
    /// Note: entity().name returns nil as per iOS 10, in Unit Testing Targets. Awesome.
    ///
    public class var entityName: String {
        return entity().name ?? classNameWithoutNamespaces()
    }
}
