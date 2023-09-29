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
    @NSManaged public var adminURL: String?
    @NSManaged public var loginURL: String?
    @NSManaged public var frameNonce: String?
    @NSManaged public var plan: String?
    @NSManaged public var isAIAssitantFeatureActive: Bool
    @NSManaged public var isWooCommerceActive: NSNumber?
    @NSManaged public var isWordPressStore: NSNumber?
    @NSManaged public var timezone: String?
    @NSManaged public var gmtOffset: Double
    @NSManaged public var isJetpackConnected: Bool
    @NSManaged public var isJetpackThePluginInstalled: Bool
    @NSManaged public var jetpackConnectionActivePlugins: [String]?
    @NSManaged public var isPublic: Bool
    @NSManaged public var isSiteOwner: Bool
    @NSManaged public var isAdmin: Bool
    @NSManaged public var canBlaze: Bool
    @NSManaged public var wasEcommerceTrial: Bool

}

extension Site: Identifiable {

}
