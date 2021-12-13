import Foundation
import CoreData


extension Country {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Country> {
        return NSFetchRequest<Country>(entityName: "Country")
    }

    @NSManaged public var code: String
    @NSManaged public var name: String
    @NSManaged public var states: Set<StateOfACountry>

}

// MARK: Generated accessors for states
extension Country {

    @objc(addStatesObject:)
    @NSManaged public func addToStates(_ value: StateOfACountry)

    @objc(removeStatesObject:)
    @NSManaged public func removeFromStates(_ value: StateOfACountry)

    @objc(addStates:)
    @NSManaged public func addToStates(_ values: NSSet)

    @objc(removeStates:)
    @NSManaged public func removeFromStates(_ values: NSSet)

}
