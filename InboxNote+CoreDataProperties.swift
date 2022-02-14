import Foundation
import CoreData


extension InboxNote {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<InboxNote> {
        return NSFetchRequest<InboxNote>(entityName: "InboxNote")
    }

    @NSManaged public var content: String?
    @NSManaged public var isRemoved: Bool
    @NSManaged public var id: Int64
    @NSManaged public var name: String?
    @NSManaged public var isRead: Bool
    @NSManaged public var siteID: Int64
    @NSManaged public var status: String?
    @NSManaged public var title: String?
    @NSManaged public var type: String?
    @NSManaged public var dateCreated: Date?
    @NSManaged public var actions: Set<InboxAction>?

}

// MARK: Generated accessors for actions
extension InboxNote {

    @objc(addActionsObject:)
    @NSManaged public func addToActions(_ value: InboxAction)

    @objc(removeActionsObject:)
    @NSManaged public func removeFromActions(_ value: InboxAction)

    @objc(addActions:)
    @NSManaged public func addToActions(_ values: NSSet)

    @objc(removeActions:)
    @NSManaged public func removeFromActions(_ values: NSSet)

}

extension InboxNote: Identifiable {

}
