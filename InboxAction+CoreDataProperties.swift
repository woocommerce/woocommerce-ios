import Foundation
import CoreData


extension InboxAction {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<InboxAction> {
        return NSFetchRequest<InboxAction>(entityName: "InboxAction")
    }

    @NSManaged public var id: Int64
    @NSManaged public var label: String?
    @NSManaged public var name: String?
    @NSManaged public var status: String?
    @NSManaged public var url: String?
    @NSManaged public var inboxNote: InboxNote

}

extension InboxAction: Identifiable {

}
