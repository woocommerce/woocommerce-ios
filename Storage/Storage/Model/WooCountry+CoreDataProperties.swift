import Foundation
import CoreData


extension WooCountry {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<WooCountry> {
        return NSFetchRequest<WooCountry>(entityName: "WooCountry")
    }

    @NSManaged public var code: String
    @NSManaged public var name: String
    @NSManaged public var states: Set<StateOfAWooCountry>

}

// MARK: Generated accessors for states
extension WooCountry {

    @objc(addStatesObject:)
    @NSManaged public func addToStates(_ value: StateOfAWooCountry)

    @objc(removeStatesObject:)
    @NSManaged public func removeFromStates(_ value: StateOfAWooCountry)

    @objc(addStates:)
    @NSManaged public func addToStates(_ values: NSSet)

    @objc(removeStates:)
    @NSManaged public func removeFromStates(_ values: NSSet)

}
