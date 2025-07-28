import Foundation
import CoreData


extension ShippingLabelAddress {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ShippingLabelAddress> {
        return NSFetchRequest<ShippingLabelAddress>(entityName: "ShippingLabelAddress")
    }

    @NSManaged public var company: String
    @NSManaged public var name: String
    @NSManaged public var phone: String
    @NSManaged public var country: String
    @NSManaged public var state: String
    @NSManaged public var address1: String
    @NSManaged public var address2: String
    @NSManaged public var city: String
    @NSManaged public var postcode: String
    @NSManaged public var destinationShippingLabel: ShippingLabel?
    @NSManaged public var originShippingLabel: ShippingLabel?

}
