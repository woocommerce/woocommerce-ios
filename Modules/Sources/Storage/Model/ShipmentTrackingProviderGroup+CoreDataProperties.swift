import Foundation
import CoreData


extension ShipmentTrackingProviderGroup {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ShipmentTrackingProviderGroup> {
        return NSFetchRequest<ShipmentTrackingProviderGroup>(entityName: "ShipmentTrackingProviderGroup")
    }

    @NSManaged public var siteID: Int64
    @NSManaged public var name: String?
    @NSManaged public var providers: Set<ShipmentTrackingProvider>?

}

// MARK: Generated accessors for providers
extension ShipmentTrackingProviderGroup {

    @objc(addProvidersObject:)
    @NSManaged public func addToProviders(_ value: ShipmentTrackingProvider)

    @objc(removeProvidersObject:)
    @NSManaged public func removeFromProviders(_ value: ShipmentTrackingProvider)

    @objc(addProviders:)
    @NSManaged public func addToProviders(_ values: NSSet)

    @objc(removeProviders:)
    @NSManaged public func removeFromProviders(_ values: NSSet)

}
