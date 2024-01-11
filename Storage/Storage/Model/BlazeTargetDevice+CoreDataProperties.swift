import Foundation
import CoreData


extension BlazeTargetDevice {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BlazeTargetDevice> {
        return NSFetchRequest<BlazeTargetDevice>(entityName: "BlazeTargetDevice")
    }

    @NSManaged public var id: String
    @NSManaged public var name: String
    @NSManaged public var locale: String

}
