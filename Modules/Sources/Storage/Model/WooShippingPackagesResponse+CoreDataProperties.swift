import Foundation
import CoreData


extension WooShippingPackagesResponse {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<WooShippingPackagesResponse> {
        return NSFetchRequest<WooShippingPackagesResponse>(entityName: "WooShippingPackagesResponse")
    }

    @NSManaged public var siteID: Int64
    @NSManaged public var allPredefinedOptions: NSOrderedSet?
    @NSManaged public var customPackages: Set<WooShippingCustomPackage>?
    @NSManaged public var savedPredefinedPackages: Set<WooShippingSavedPredefinedPackage>?
}

// MARK: Generated accessors for allPredefinedOptions
extension WooShippingPackagesResponse {

    @objc(insertObject:inAllPredefinedOptionsAtIndex:)
    @NSManaged public func insertIntoAllPredefinedOptions(_ value: WooShippingCarrierPredefinedOptions, at idx: Int)

    @objc(removeObjectFromAllPredefinedOptionsAtIndex:)
    @NSManaged public func removeFromAllPredefinedOptions(at idx: Int)

    @objc(insertAllPredefinedOptions:atIndexes:)
    @NSManaged public func insertIntoAllPredefinedOptions(_ values: [WooShippingCarrierPredefinedOptions], at indexes: NSIndexSet)

    @objc(removeAllPredefinedOptionsAtIndexes:)
    @NSManaged public func removeFromAllPredefinedOptions(at indexes: NSIndexSet)

    @objc(replaceObjectInAllPredefinedOptionsAtIndex:withObject:)
    @NSManaged public func replaceAllPredefinedOptions(at idx: Int, with value: WooShippingCarrierPredefinedOptions)

    @objc(replaceAllPredefinedOptionsAtIndexes:withAllPredefinedOptions:)
    @NSManaged public func replaceAllPredefinedOptions(at indexes: NSIndexSet, with values: [WooShippingCarrierPredefinedOptions])

    @objc(addAllPredefinedOptionsObject:)
    @NSManaged public func addToAllPredefinedOptions(_ value: WooShippingCarrierPredefinedOptions)

    @objc(removeAllPredefinedOptionsObject:)
    @NSManaged public func removeFromAllPredefinedOptions(_ value: WooShippingCarrierPredefinedOptions)

    @objc(addAllPredefinedOptions:)
    @NSManaged public func addToAllPredefinedOptions(_ values: NSOrderedSet)

    @objc(removeAllPredefinedOptions:)
    @NSManaged public func removeFromAllPredefinedOptions(_ values: NSOrderedSet)
}

// MARK: Generated accessors for customPackages
extension WooShippingPackagesResponse {

    @objc(addCustomPackagesObject:)
    @NSManaged public func addToCustomPackages(_ value: WooShippingCustomPackage)

    @objc(removeCustomPackagesObject:)
    @NSManaged public func removeFromCustomPackages(_ value: WooShippingCustomPackage)

    @objc(addCustomPackages:)
    @NSManaged public func addToCustomPackages(_ values: NSSet)

    @objc(removeCustomPackages:)
    @NSManaged public func removeFromCustomPackages(_ values: NSSet)
}

// MARK: Generated accessors for savedPredefinedPackages
extension WooShippingPackagesResponse {

    @objc(addSavedPredefinedPackagesObject:)
    @NSManaged public func addToSavedPredefinedPackages(_ value: WooShippingSavedPredefinedPackage)

    @objc(removeSavedPredefinedPackagesObject:)
    @NSManaged public func removeFromSavedPredefinedPackages(_ value: WooShippingSavedPredefinedPackage)

    @objc(addSavedPredefinedPackages:)
    @NSManaged public func addToSavedPredefinedPackages(_ values: NSSet)

    @objc(removeSavedPredefinedPackages:)
    @NSManaged public func removeFromSavedPredefinedPackages(_ values: NSSet)
}

extension WooShippingPackagesResponse: Identifiable {
}
