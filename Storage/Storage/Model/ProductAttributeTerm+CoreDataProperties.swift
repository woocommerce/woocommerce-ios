import Foundation
import CoreData


extension ProductAttributeTerm {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ProductAttributeTerm> {
        return NSFetchRequest<ProductAttributeTerm>(entityName: "ProductAttributeTerm")
    }

    @NSManaged public var termID: Int64
    @NSManaged public var name: String?
    @NSManaged public var slug: String?
    @NSManaged public var count: Int32
    @NSManaged public var siteID: Int64
    @NSManaged public var attribute: ProductAttribute?
}
