import Foundation
import CoreData


extension SitePlugin {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SitePlugin> {
        return NSFetchRequest<SitePlugin>(entityName: "SitePlugin")
    }

    @NSManaged public var siteID: Int64
    @NSManaged public var plugin: String
    @NSManaged public var status: String
    @NSManaged public var name: String
    @NSManaged public var pluginUri: String
    @NSManaged public var author: String
    @NSManaged public var authorUri: String
    @NSManaged public var descriptionRaw: String
    @NSManaged public var descriptionRendered: String
    @NSManaged public var version: String
    @NSManaged public var networkOnly: Bool
    @NSManaged public var requiresWPVersion: String
    @NSManaged public var requiresPHPVersion: String
    @NSManaged public var textDomain: String

}
