import Foundation
import CoreData


extension WooShippingCarrierPredefinedOptions {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<WooShippingCarrierPredefinedOptions> {
        return NSFetchRequest<WooShippingCarrierPredefinedOptions>(entityName: "WooShippingCarrierPredefinedOptions")
    }

    @NSManaged public var carrierID: String?
    @NSManaged public var packagesResponse: WooShippingPackagesResponse?
    @NSManaged public var predefinedOptions: NSOrderedSet?

}

// MARK: Generated accessors for predefinedOptions
extension WooShippingCarrierPredefinedOptions {

    @objc(insertObject:inPredefinedOptionsAtIndex:)
    @NSManaged public func insertIntoPredefinedOptions(_ value: WooShippingPredefinedOption, at idx: Int)

    @objc(removeObjectFromPredefinedOptionsAtIndex:)
    @NSManaged public func removeFromPredefinedOptions(at idx: Int)

    @objc(insertPredefinedOptions:atIndexes:)
    @NSManaged public func insertIntoPredefinedOptions(_ values: [WooShippingPredefinedOption], at indexes: NSIndexSet)

    @objc(removePredefinedOptionsAtIndexes:)
    @NSManaged public func removeFromPredefinedOptions(at indexes: NSIndexSet)

    @objc(replaceObjectInPredefinedOptionsAtIndex:withObject:)
    @NSManaged public func replacePredefinedOptions(at idx: Int, with value: WooShippingPredefinedOption)

    @objc(replacePredefinedOptionsAtIndexes:withPredefinedOptions:)
    @NSManaged public func replacePredefinedOptions(at indexes: NSIndexSet, with values: [WooShippingPredefinedOption])

    @objc(addPredefinedOptionsObject:)
    @NSManaged public func addToPredefinedOptions(_ value: WooShippingPredefinedOption)

    @objc(removePredefinedOptionsObject:)
    @NSManaged public func removeFromPredefinedOptions(_ value: WooShippingPredefinedOption)

    @objc(addPredefinedOptions:)
    @NSManaged public func addToPredefinedOptions(_ values: NSOrderedSet)

    @objc(removePredefinedOptions:)
    @NSManaged public func removeFromPredefinedOptions(_ values: NSOrderedSet)

}

extension WooShippingCarrierPredefinedOptions: Identifiable {

}
