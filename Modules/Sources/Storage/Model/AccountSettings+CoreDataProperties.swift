import Foundation
import CoreData


extension AccountSettings {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<AccountSettings> {
        return NSFetchRequest<AccountSettings>(entityName: "AccountSettings")
    }

    @NSManaged public var tracksOptOut: Bool
    @NSManaged public var userID: Int64
    @NSManaged public var firstName: String?
    @NSManaged public var lastName: String?

}
