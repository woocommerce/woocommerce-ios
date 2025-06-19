import Foundation
import CoreData


extension Account {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Account> {
        return NSFetchRequest<Account>(entityName: "Account")
    }

    @NSManaged public var displayName: String?
    @NSManaged public var email: String?
    @NSManaged public var gravatarUrl: String?
    @NSManaged public var userID: Int64
    @NSManaged public var username: String?

}
