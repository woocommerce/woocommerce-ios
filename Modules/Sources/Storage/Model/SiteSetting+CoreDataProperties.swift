import Foundation
import CoreData


extension SiteSetting {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SiteSetting> {
        return NSFetchRequest<SiteSetting>(entityName: "SiteSetting")
    }

    @NSManaged public var siteID: Int64
    @NSManaged public var settingID: String?
    @NSManaged public var label: String?
    @NSManaged public var settingDescription: String?
    @NSManaged public var value: String?
    @NSManaged public var settingGroupKey: String?
}
