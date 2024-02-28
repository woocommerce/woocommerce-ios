import Foundation
import CoreData


extension BlazeTargetLanguage {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BlazeTargetLanguage> {
        return NSFetchRequest<BlazeTargetLanguage>(entityName: "BlazeTargetLanguage")
    }

    @NSManaged public var id: String
    @NSManaged public var name: String
    @NSManaged public var locale: String

}
