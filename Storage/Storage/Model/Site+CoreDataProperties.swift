import Foundation
import CoreData


extension Site {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Site> {
        return NSFetchRequest<Site>(entityName: "Site")
    }

    @NSManaged public var siteID: Int64
    @NSManaged public var name: String?
    @NSManaged public var tagline: String?
    @NSManaged public var url: String?
    @NSManaged public var plan: String?
    @NSManaged public var isWooCommerceActive: NSNumber?
    @NSManaged public var isWordPressStore: NSNumber?
    @NSManaged public var timezone: String?
    @NSManaged public var gmtOffset: Double
}
