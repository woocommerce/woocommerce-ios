import Foundation
import CoreData


extension StateOfACountry {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<StateOfACountry> {
        return NSFetchRequest<StateOfACountry>(entityName: "StateOfACountry")
    }

    @NSManaged public var code: String
    @NSManaged public var name: String
    @NSManaged public var relationship: Country

}
