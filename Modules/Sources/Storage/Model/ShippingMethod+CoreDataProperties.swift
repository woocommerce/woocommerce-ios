import Foundation
import CoreData


extension ShippingMethod {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ShippingMethod> {
        return NSFetchRequest<ShippingMethod>(entityName: "ShippingMethod")
    }

    @NSManaged public var siteID: Int64
    @NSManaged public var methodID: String?
    @NSManaged public var title: String?

}

extension ShippingMethod: Identifiable {

}
