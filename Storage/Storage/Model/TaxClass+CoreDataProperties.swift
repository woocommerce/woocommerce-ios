import Foundation
import CoreData


extension TaxClass {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TaxClass> {
        return NSFetchRequest<TaxClass>(entityName: "TaxClass")
    }

    @NSManaged public var name: String?
    @NSManaged public var slug: String?
}
