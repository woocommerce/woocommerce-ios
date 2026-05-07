import Foundation
import CoreData


extension StoredSupportChat {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<StoredSupportChat> {
        return NSFetchRequest<StoredSupportChat>(entityName: "StoredSupportChat")
    }

    @NSManaged public var chatID: Int64
    @NSManaged public var siteID: Int64
    @NSManaged public var wpcomUserID: Int64
    @NSManaged public var botSlug: String?
    @NSManaged public var hasCreatedTicket: Bool
    @NSManaged public var title: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?

}
