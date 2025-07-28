import Foundation
import CoreData


extension TaxRate {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TaxRate> {
        return NSFetchRequest<TaxRate>(entityName: "TaxRate")
    }

    @NSManaged public var siteID: Int64
    @NSManaged public var id: Int64
    @NSManaged public var country: String?
    @NSManaged public var state: String?
    @NSManaged public var postcode: String?
    @NSManaged public var postcodes: [String]?
    @NSManaged public var priority: Int64
    @NSManaged public var rate: String?
    @NSManaged public var name: String?
    @NSManaged public var order: Int64
    @NSManaged public var taxRateClass: String?
    @NSManaged public var shipping: Bool
    @NSManaged public var compound: Bool
    @NSManaged public var city: String?
    @NSManaged public var cities: [String]?

}
