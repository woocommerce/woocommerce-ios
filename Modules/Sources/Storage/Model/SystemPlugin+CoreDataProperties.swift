import Foundation
import CoreData


extension SystemPlugin {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SystemPlugin> {
        return NSFetchRequest<SystemPlugin>(entityName: "SystemPlugin")
    }

    @NSManaged public var siteID: Int64
    @NSManaged public var plugin: String
    @NSManaged public var name: String
    @NSManaged public var version: String
    @NSManaged public var versionLatest: String
    @NSManaged public var url: String
    @NSManaged public var authorName: String
    @NSManaged public var authorUrl: String
    @NSManaged public var networkActivated: Bool
    @NSManaged public var active: Bool
}
