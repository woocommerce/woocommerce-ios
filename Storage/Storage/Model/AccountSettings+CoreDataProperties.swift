import CoreData
import Foundation

extension AccountSettings {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<AccountSettings> {
        return NSFetchRequest<AccountSettings>(entityName: "AccountSettings")
    }

    @NSManaged public var tracksOptOut: Bool
    @NSManaged public var userID: Int64

}
