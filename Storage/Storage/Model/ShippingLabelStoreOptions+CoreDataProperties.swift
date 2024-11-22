import Foundation
import CoreData

extension ShippingLabelStoreOptions {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ShippingLabelStoreOptions> {
        return NSFetchRequest<ShippingLabelStoreOptions>(entityName: "ShippingLabelStoreOptions")
    }

    @NSManaged public var currencySymbol: String?
    @NSManaged public var dimensionUnit: String?
    @NSManaged public var weightUnit: String?
    @NSManaged public var originCountry: String?
    @NSManaged public var siteID: Int64
}
