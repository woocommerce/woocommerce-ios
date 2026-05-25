import Foundation
import CoreData


extension WooShippingPredefinedOption {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<WooShippingPredefinedOption> {
        return NSFetchRequest<WooShippingPredefinedOption>(entityName: "WooShippingPredefinedOption")
    }

    @NSManaged public var providerID: String?
    @NSManaged public var title: String?
    @NSManaged public var carrier: WooShippingCarrierPredefinedOptions?
    @NSManaged public var predefinedPackages: Set<WooShippingPredefinedPackage>?
}

// MARK: Generated accessors for predefinedPackages
extension WooShippingPredefinedOption {

    @objc(addPredefinedPackagesObject:)
    @NSManaged public func addToPredefinedPackages(_ value: WooShippingPredefinedPackage)

    @objc(removePredefinedPackagesObject:)
    @NSManaged public func removeFromPredefinedPackages(_ value: WooShippingPredefinedPackage)

    @objc(addPredefinedPackages:)
    @NSManaged public func addToPredefinedPackages(_ values: NSSet)

    @objc(removePredefinedPackages:)
    @NSManaged public func removeFromPredefinedPackages(_ values: NSSet)
}

extension WooShippingPredefinedOption: Identifiable {
}
