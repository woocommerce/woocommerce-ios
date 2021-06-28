import Foundation
import CoreData


extension StateOfAWooCountry {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<StateOfAWooCountry> {
        return NSFetchRequest<StateOfAWooCountry>(entityName: "StateOfAWooCountry")
    }

    @NSManaged public var code: String
    @NSManaged public var name: String
    @NSManaged public var relationship: WooCountry

}
