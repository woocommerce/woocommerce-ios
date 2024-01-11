import Foundation
import CoreData


extension BlazeTargetTopic {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BlazeTargetTopic> {
        return NSFetchRequest<BlazeTargetTopic>(entityName: "BlazeTargetTopic")
    }

    @NSManaged public var id: String
    @NSManaged public var name: String
    @NSManaged public var locale: String

}
